import os
import sys
import json
import base64
import hashlib
import mimetypes
import urllib.request
import time
from pathlib import Path

# Load credentials
env_file = Path("/home/wilsonborba/.config/cloudflare/env")
with open(env_file) as f:
    for line in f:
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        k, v = line.split("=", 1)
        k = k.replace("export ", "").strip()
        v = v.strip().strip("'\"")
        os.environ[k] = v

ACCOUNT_ID = os.environ["CLOUDFLARE_ACCOUNT_ID"]
EMAIL = os.environ["CLOUDFLARE_EMAIL"]
API_KEY = os.environ["CLOUDFLARE_API_KEY"]
API_BASE = "https://api.cloudflare.com/client/v4"

headers_global = {
    "X-Auth-Email": EMAIL,
    "X-Auth-Key": API_KEY,
    "Content-Type": "application/json"
}

def cf_request(method, endpoint, data=None, headers=None):
    hdrs = headers or headers_global
    body = None
    if data is not None:
        if isinstance(data, (dict, list)):
            body = json.dumps(data).encode("utf-8")
        elif isinstance(data, bytes):
            body = data
        else:
            body = data.encode("utf-8")
    req = urllib.request.Request(f"{API_BASE}{endpoint}", data=body, headers=hdrs, method=method)
    try:
        with urllib.request.urlopen(req) as resp:
            res_bytes = resp.read()
            if not res_bytes:
                return {}
            return json.loads(res_bytes.decode("utf-8"))
    except urllib.error.HTTPError as e:
        err_content = e.read().decode("utf-8")
        print(f"HTTP Error {e.code} on {method} {endpoint}: {err_content}")
        raise

def deploy_pages_project(project_name, build_dir, custom_domain=None, branch="main", timestamp_str=None):
    build_path = Path(build_dir)
    if not build_path.exists():
        raise RuntimeError(f"Build dir not found: {build_dir}")

    # 1. Create or get project
    try:
        cf_request("GET", f"/accounts/{ACCOUNT_ID}/pages/projects/{project_name}")
        print(f"Project '{project_name}' exists.")
    except Exception:
        print(f"Creating project '{project_name}' (production branch: {branch})...")
        cf_request("POST", f"/accounts/{ACCOUNT_ID}/pages/projects", {
            "name": project_name,
            "production_branch": branch
        })
        print(f"Project '{project_name}' created.")

    # 2. Request Upload Token (JWT)
    tok_res = cf_request("GET", f"/accounts/{ACCOUNT_ID}/pages/projects/{project_name}/upload-token")
    jwt = tok_res["result"]["jwt"]
    jwt_headers = {
        "Authorization": f"Bearer {jwt}",
        "Content-Type": "application/json"
    }

    # 3. Hash all build files with leading slashes in manifest
    files = []
    manifest = {}
    for p in sorted(build_path.rglob("*")):
        if not p.is_file():
            continue
        rel = p.relative_to(build_path).as_posix()
        manifest_path = f"/{rel}" if not rel.startswith("/") else rel
        data = p.read_bytes()
        digest = hashlib.md5(data).hexdigest()
        mime, _ = mimetypes.guess_type(p.name)
        files.append({
            "path": manifest_path,
            "hash": digest,
            "content_type": mime or "application/octet-stream",
            "base64": base64.b64encode(data).decode("ascii"),
            "size": len(data)
        })
        manifest[manifest_path] = digest

    print(f"Total build files: {len(files)}")

    # 4. Check missing hashes
    hashes = list(set([f["hash"] for f in files]))
    missing_res = cf_request("POST", "/pages/assets/check-missing", {"hashes": hashes}, headers=jwt_headers)
    missing = set(missing_res.get("result", []))
    print(f"Missing hashes to upload: {len(missing)}")

    # 5. Upload missing files in batches
    if missing:
        batches = []
        cur_batch = []
        cur_bytes = 0
        max_bytes = 7000000
        max_files = 50

        for f in files:
            if f["hash"] not in missing:
                continue
            if cur_batch and (len(cur_batch) >= max_files or cur_bytes + f["size"] > max_bytes):
                batches.append(cur_batch)
                cur_batch = []
                cur_bytes = 0
            cur_batch.append({
                "base64": True,
                "key": f["hash"],
                "metadata": {"contentType": f["content_type"]},
                "value": f["base64"]
            })
            cur_bytes += f["size"]
        if cur_batch:
            batches.append(cur_batch)

        print(f"Uploading in {len(batches)} batches...")
        for i, b in enumerate(batches, 1):
            cf_request("POST", "/pages/assets/upload", b, headers=jwt_headers)
            print(f" - Uploaded batch {i}/{len(batches)}")

    # 6. Upsert hashes
    cf_request("POST", "/pages/assets/upsert-hashes", {"hashes": hashes}, headers=jwt_headers)

    # 7. Create production deployment using multipart/form-data
    boundary = "----CloudflarePagesDeploymentBoundary"
    form_data = bytearray()

    def add_field(name, value):
        form_data.extend(f"--{boundary}\r\nContent-Disposition: form-data; name=\"{name}\"\r\n\r\n{value}\r\n".encode())

    add_field("branch", branch)
    add_field("commit_dirty", "false")
    add_field("commit_hash", "production-build")
    add_field("commit_message", f"Deploy {project_name} - {timestamp_str or ''}")
    add_field("manifest", json.dumps(manifest, separators=(',', ':')))
    form_data.extend(f"--{boundary}--\r\n".encode())

    dep_headers = {
        "X-Auth-Email": EMAIL,
        "X-Auth-Key": API_KEY,
        "Content-Type": f"multipart/form-data; boundary={boundary}"
    }

    req = urllib.request.Request(
        f"{API_BASE}/accounts/{ACCOUNT_ID}/pages/projects/{project_name}/deployments",
        data=bytes(form_data),
        headers=dep_headers,
        method="POST"
    )
    with urllib.request.urlopen(req) as resp:
        dep = json.loads(resp.read().decode("utf-8"))
        dep_id = dep["result"]["id"]
        dep_url = dep["result"]["url"]
        print(f"Deployment created: {dep_id} -> {dep_url}")

    # 8. Poll until success
    for _ in range(30):
        s = cf_request("GET", f"/accounts/{ACCOUNT_ID}/pages/projects/{project_name}/deployments/{dep_id}")
        stage = s["result"]["latest_stage"]
        status = stage["status"]
        print(f"Deploy status: {stage['name']} -> {status}")
        if status == "success":
            break
        if status == "failure":
            raise RuntimeError(f"Deployment failed at stage {stage['name']}")
        time.sleep(2)

    # 9. Attach Custom Domain AFTER first deployment is live
    if custom_domain:
        try:
            domains = cf_request("GET", f"/accounts/{ACCOUNT_ID}/pages/projects/{project_name}/domains")
            existing_domains = [d.get("name") for d in domains.get("result", [])]
            if custom_domain not in existing_domains:
                print(f"Attaching custom domain '{custom_domain}' to {project_name}...")
                cf_request("POST", f"/accounts/{ACCOUNT_ID}/pages/projects/{project_name}/domains", {
                    "name": custom_domain
                })
                print(f"Attached custom domain '{custom_domain}'.")
            else:
                print(f"Custom domain '{custom_domain}' already attached.")
        except Exception as e:
            print(f"Custom domain attach note: {e}")

    print(f"✅ Successfully deployed {project_name} to {dep_url}")
    if custom_domain:
        print(f"   Live at: https://{custom_domain}")
