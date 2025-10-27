import 'dart:convert';
import 'package:accredit/core/utils/my_logs.dart';
import 'package:accredit/core/utils/my_nagivation.dart';
import 'package:accredit/domain/models/topic_identifications.dart';
import 'package:accredit/presentation/screen_adjuster.dart';
import 'package:accredit/presentation/widgets/certifications_config/desktop_certifications_config.dart';
import 'package:accredit/presentation/widgets/certifications_config/mobile_certifications_config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:accredit/domain/services/pdf_frontend_prescan_manager.dart' as pre;

class OnCertificationConfigScreen extends StatefulWidget {
  final String? itemName;
  final String contextId;
  final bool isForPDF;

  const OnCertificationConfigScreen({
    super.key,
    required this.contextId,
    this.isForPDF = true,
    this.itemName,
  });

  Future<ContextInfo> _fetch(String ctxId) async {
    http.Response resp;
    if (isForPDF) {
      resp = await pre.getPdfContextFromApi(documentId: ctxId);
    } else {
      resp = await pre.getTopicContextFromApi(
        inputIdentification: ctxId,
        itemName: itemName!,
      );
    }
    return parseContextInfo(resp);
  }

  ContextInfo parseContextInfo(http.Response resp) {
    final jsonMap = json.decode(resp.body) as Map<String, dynamic>;
    final msg = (jsonMap['message'] ?? '') as String;
    List<dynamic> data;
    if (jsonMap["data"] is List<dynamic>) {
      data = jsonMap['data'] as List<dynamic>;
    } else {
      data = <dynamic>[];
      debug('Warning: "data" is not a List<dynamic>. It is ${jsonMap["data"].runtimeType}');
    }
    return ContextInfo(
      message: msg,
      data: data,
      statusCode: resp.statusCode,
    );
  }

  @override
  State<OnCertificationConfigScreen> createState() => _OnCertificationConfigScreenState();
}

class _OnCertificationConfigScreenState extends State<OnCertificationConfigScreen> {
  bool _loading = true;
  String? _error;
  String _loadingMessage = "Contacting server...";
  ContextInfo? _resp;

  @override
  void initState() {
    super.initState();
    // Don't await here; just start the async bootstrap.
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
        _loadingMessage = "Contacting server...";
      });
    }

    try {
      // Staged loading messages (optional eye-candy)
      await Future.delayed(const Duration(seconds: 5));
      if (!mounted) return;
      setState(() => _loadingMessage = "Loading...");

      await Future.delayed(const Duration(seconds: 10));
      if (!mounted) return;
      setState(() => _loadingMessage = "We're setting things up for you...");

      await Future.delayed(const Duration(seconds: 15));
      if (!mounted) return;
      setState(() => _loadingMessage = "Go take a coffee break ☕...");

      await Future.delayed(const Duration(seconds: 20));
      if (!mounted) return;
      setState(() => _loadingMessage = "It might take some time...");

      final got = await widget._fetch(widget.contextId);

      if (!mounted) return;

      if (got.statusCode != 200) {
        setState(() {
          _error = _mapStatusCodeToMessage(got.statusCode, got.message);
          _loading = false;
        });
        return;
      }

      // Success
      setState(() {
        _loadingMessage = "Almost done...";
        _resp = got;
        debug('Fetched ContextInfo: ${got.data}');
        _loading = false;
      });
    } catch (e) {
      debug('Error in OnCertificationConfigScreen: $e');
      if (!mounted) return;
      setState(() {
        _error = "Could not continue. Please contact support@asodya.com.";
        _loading = false;
      });
    }
  }

  String _mapStatusCodeToMessage(int code, String msg) {
    const supportEmail = "support@asodya.com";
    switch (code) {
      case 400:
        return "Bad request, please contact $supportEmail";
      case 404:
        return "Not found, please contact $supportEmail";
      case 409:
        return "Blocked, suspicious activity detected...";
      case 412:
        return "Minimal content context not met, please contact $supportEmail";
      case 415:
        return "Unsupported file, please contact $supportEmail";
      case 422:
        return "Invalid pages, please contact $supportEmail";
      case 503:
        return "Service unavailable, please contact $supportEmail";
      default:
        return "Please contact $supportEmail (code $code)";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(strokeWidth: 4),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                child: Text(
                  _loadingMessage,
                  key: ValueKey(_loadingMessage),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.shade100.withAlpha((0.4 * 255).toInt()),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.deepPurple),
                const SizedBox(height: 16),
                const Text(
                  "Oops! Something went wrong.",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, color: Colors.black87),
                  softWrap: true,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple.shade400,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  label: const Text("Go Back", style: TextStyle(color: Colors.white, fontSize: 18)),
                  onPressed: () async {
                      await defaultLogout();
                    },
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Success: show your main config UI with the fetched payload
    return ScreenAdjuster(
      mobileWidget: MobileCertificationConfig(
        documentId: widget.contextId,
        questionPayload: _resp,
      ),
      desktopWidget: DesktopCertificationConfig(
        documentId: widget.contextId,
        questionPayload: _resp,
      ),
    ).adjust(context);
  }
}
