// ignore_for_file: non_constant_identifier_names

import 'package:certifications/domain/models/application_info.dart';

class Settings {
  // accessible from outside

  late final String FERNET_KEY_SECRET;

  /// Non-secret frontend behavior belongs in settings, not in an environment
  /// file or compiler flag. Switch this only when preparing a production build.
  final bool developmentMode = true;

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
