
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:accredit/core/utils/my_logs.dart';




class LocalSourceAdapter {




  // Example method to save data to local storage
  Future<void> saveData(String key, dynamic value) async {
    // Implement your local storage saving logic here
    // For example, using SharedPreferences or any other local storage solution
  }


  Future<String> getEnvData(String key) async {
    try {
      // Retrieve the value from the environment variables
      final value = dotenv.env[key.toUpperCase()];
      if (value == null) {
        throw Exception("Key [$key] not found in environment!");
      }
      return value;
    } catch (e) {
      // Handle any errors that occur during retrieval
      debug("Error retrieving environment variable: $e");
      rethrow;
    }
  }

}
