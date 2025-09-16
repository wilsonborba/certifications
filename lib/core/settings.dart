// ignore_for_file: non_constant_identifier_names


import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:accredit/dal/local/local_source_adapter.dart';




class Settings {

  // accessible from outside


  
  late final String FERNET_KEY_SECRET;


  final bool developmentMode = true;

  final String imgsPath = "lib/presentation/assets/img/";







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
