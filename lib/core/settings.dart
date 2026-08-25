// ignore_for_file: non_constant_identifier_names

import 'package:certifications/domain/models/application_info.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:certifications/dal/local/local_source_adapter.dart';
import 'package:flutter/foundation.dart';

class Settings {
  // accessible from outside

  late final String FERNET_KEY_SECRET;

  /// Runtime environment is independent from Flutter's compilation mode.
  ///
  /// The local web runner uses a release build for a stable bootstrap, while
  /// still needing local API and authentication endpoints.
  final bool developmentMode = bool.fromEnvironment(
    'DEVELOPMENT_MODE',
    defaultValue: kDebugMode,
  );

  // ASODYA URLS

  String get ASODYA_MAIN_DOMAIN => 'asodya.com';

  String get ASODYA_API_URL => developmentMode
      ? 'http://192.168.1.103:8101'
      : 'https://api.$ASODYA_MAIN_DOMAIN:8101';

  String get ASODYA_AUTH_URL => developmentMode
      ? 'http://192.168.1.103:8100'
      : 'https://auth.$ASODYA_MAIN_DOMAIN:8100';

  String get ASODYA_AUTH_LOGIN_URL => '$ASODYA_AUTH_URL/log_in';
  String get ASODYA_AUTH_SIGNUP_URL => '$ASODYA_AUTH_URL/sign_up';

  final String imgsPath = "lib/presentation/assets/img/";

  Map<String, dynamic> get applicationInfo => ApplicationInfo(
    name: "Certifications",
    description:
        "Certifications is a secure and user-friendly platform for getting certifications.",
    logoImageUrl:
        "https://res.cloudinary.com/dhncdmb2t/image/upload/v1761907623/temp_logo_tw3grt.png",
    urlApp: developmentMode
        ? "http://192.168.1.103:8102"
        : "https://certifications.asodya.com",
    twoFaAuth: false,
    primaryColor: "#3498db",
    secondaryColor: "#2ecc71",
    tertiaryColor: "#e74c3c",
    quartaryColor: null,
    createdAt: DateTime.now().toIso8601String(),
  ).toJson();

  // not accessible from outside
  final LocalSourceAdapter _localSourceAdapter = LocalSourceAdapter(
    namespace: 'settings',
  );

  static final Settings _instance = Settings._internal();

  Settings._internal();

  factory Settings() {
    return _instance;
  }

  Future<void> init() async {
    FERNET_KEY_SECRET = 'mEt5jdm9aTbUYnjhQM_tY_CTQL-JvXe0u9VdKEM2KmY=';
  }
}

Settings get app_settings => Settings();
