


import 'dart:convert';

import 'package:accredit/core/settings.dart';
import 'package:accredit/core/utils/my_logs.dart';
import 'package:accredit/dal/local/local_source_adapter.dart';

import 'package:accredit/dal/remote/api_adapter.dart';

import 'package:accredit/presentation/components/auth/verify_session.dart';
import 'package:http/http.dart';




class ApiAsodyaManager {

  String baseUrl = app_settings.ASODYA_API_URL;
  // default headers request
  Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };


  Future<Response> exchange(String token) async {
    final response = await  ApiAdapter(defaultHeaders: defaultHeaders).post(
      Uri.parse('$baseUrl/apps/api/v1/exchange'),
      body: jsonEncode({'token': token}),
    );


    if (response.statusCode == 200) {
      final headers = response.headers;
      // get next auth nounce key = 'n-a-n'
      final nan = headers['n-a-n'];
      if (nan != null) {
        await saveNextAuthNounce(nan);
        debug('Next auth nounce updated: $nan from exchange response headers.');
      } else {
        warning('No next auth nounce found in response headers.');
      }
    }

    return response;

  }

  

   Future<Response> updateUserInfo(String fullName, String? phoneE164) async {

    try {
      debug('Reading next auth nounce from local storage...');
      final nounce = await readNextAuthNounce();
      final hintCookies = readCookie('hint');      

      if (nounce != null) {
        defaultHeaders['T-A-N'] = nounce;
        
      }

      if (hintCookies != null) {
        defaultHeaders['A-A-N'] = hintCookies;
      }

    } catch (e) {
      debug('Error reading next auth nounce: $e');
    }


    // split the full name into first and last name
    // if there is no space, use the full name as first name and empty last name
    final nameParts = fullName.split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : '';
    final lastName = nameParts.length > 1 ? nameParts.last : '';

    // create the request body
    final body = {
      'first_name': firstName,
      'last_name': lastName,  
      'phone_number': phoneE164,
    };
   
   final jsonBody = jsonEncode(body);



      // continue with the request
      final response = await ApiAdapter(defaultHeaders: defaultHeaders).patch(
        Uri.parse('$baseUrl/user/info/v1'),
        body: jsonBody,
      );

      if (response.statusCode == 200) {
      final headers = response.headers;
      // get next auth nounce key = 'n-a-n'
      final nan = headers['n-a-n'];

      if (nan != null) {
        await saveNextAuthNounce(nan);
        debug('Next auth nounce updated: $nan from updateUserInfo response headers.');
        debug('New nan is: $nan');
      } else {
        warning('No next auth nounce found in response headers.');

      }
    }

    return response;


}
}