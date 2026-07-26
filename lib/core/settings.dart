// ignore_for_file: non_constant_identifier_names

import 'package:accredit/domain/models/application_info.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:accredit/dal/local/local_source_adapter.dart';

class Settings {
  // accessible from outside

  late final String FERNET_KEY_SECRET;

  final bool developmentMode = false;

  // ASODYA URLS

  String get ASODYA_MAIN_DOMAIN => 'asodya.com';

  String get ASODYA_API_URL => developmentMode
      ? 'http://localhost:8000'
      : 'https://api.$ASODYA_MAIN_DOMAIN';

  // String get ASODYA_AUTH_URL => developmentMode ? 'http://localhost:7000' : 'https://auth.$ASODYA_MAIN_DOMAIN';

  String get ASODYA_AUTH_URL => 'https://auth.$ASODYA_MAIN_DOMAIN';

  String get ASODYA_AUTH_LOGIN_URL => '$ASODYA_AUTH_URL/log_in';
  String get ASODYA_AUTH_SIGNUP_URL => '$ASODYA_AUTH_URL/sign_up';

  final String imgsPath = "lib/presentation/assets/img/";

  final applicationInfo = ApplicationInfo(
    name: "Certifications",
    description:
        "Certifications is a secure and user-friendly platform for getting certifications.",
    logoImageUrl:
        "https://res.cloudinary.com/dhncdmb2t/image/upload/v1761907623/temp_logo_tw3grt.png",
    urlApp: "https://certifications.asodya.com",
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
