# certifications

Frontend Web Application for Asodya Certifications.

## Overview

`certifications` is a modern, responsive Flutter web application designed for comprehensive study management, AI-assisted exam preparation, quiz taking, interactive score analytics, and certification tracking.

## Key Features

- **Intuitive Study Hub**: Responsive landing page, interactive dashboard, and study progress tracking.
- **Quiz Wizard & Exam Runner**: Interactive question rendering, multiple-choice / scenario evaluations, and dynamic scoring reports.
- **Automatic Client Telemetry**: `ClientTelemetryService` capturing uncaught `FlutterError` and `PlatformDispatcher` exceptions with rate-throttled forwarding to the centralized telemetry gateway.
- **Clean Production Versioning**: Embedded deployment version and timestamp indicator adhering to Bangkok local time (`Asia/Bangkok`).
- **Monochrome & High-Contrast UX**: Premium, accessible UI design with full localization support.

## Architecture & Tech Stack

- **Framework**: Flutter 3.x (Web target with CanvasKit / HTML renderers)
- **State Management & Routing**: Provider / GoRouter
- **Hosting & CDN**: Cloudflare Pages (`certifications.asodya.com`)

## Getting Started

### Prerequisites

- Flutter SDK (stable channel)
- Chrome / Chromium for web testing

### Installation & Run

```bash
git clone git@github.com:wilsonborba/certifications.git
cd certifications

flutter pub get
flutter run -d chrome --web-port 8080
```

### Building for Production

```bash
flutter build web --release --no-tree-shake-icons
```

## Changelog & Releases

Changelogs are managed with [git-cliff](https://git-cliff.org).

```bash
git cliff -o CHANGELOG.md --tag <tag>
```

## License

Proprietary © Asodya. All rights reserved.
