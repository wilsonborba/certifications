// ignore_for_file: non_constant_identifier_names


import 'package:accredit/domain/models/application_info.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:accredit/dal/local/local_source_adapter.dart';




class Settings {

  // accessible from outside


  
  late final String FERNET_KEY_SECRET;


  final bool developmentMode = true;

  final String imgsPath = "lib/presentation/assets/img/";

  final String applicationInfo = ApplicationInfo(
    name: "Accredit",
    description: "Accredit is a secure and user-friendly platform for getting certifications.",
    logoImageUrl: "https://example.com/logo.png",
    urlApp: "http://localhost:1165",
    twoFaAuth: false,
    primaryColor: "#3498db",
    secondaryColor: "#2ecc71",
    tertiaryColor: "#e74c3c",
    quartaryColor: null,
    createdAt: DateTime.now().toIso8601String(),
  ).toJson().toString();

  final String AUTH_PARAM_KEY_NAME = "tokenized";





  // not accessible from outside
  final LocalSourceAdapter _localSourceAdapter = LocalSourceAdapter(namespace: 'settings');

  static final Settings _instance = Settings._internal();

  Settings._internal();

  factory Settings() {
    return _instance;
  }

  static Future<void> loadEnv([String path = '.env']) async {
    await dotenv.load(fileName: path);
  }

  Future<void> init() async {


    FERNET_KEY_SECRET = 'FEfpKZshLL36rTMY3P_dv0ADiO8bqC8Jd1eE2lkyFZ0=';


  }

  Future<String> _getEnv(String key) async {
    try {
      final value = await _localSourceAdapter.getEnvData(key);
      return value;
    } catch (e) {
      throw Exception("Failed to load environment variable [$key]: $e");
    }
  }
}


Settings get app_settings => Settings();
