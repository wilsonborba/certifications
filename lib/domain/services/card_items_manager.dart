import 'package:accredit/core/settings.dart';
import 'package:accredit/core/utils/my_encryption.dart';
import 'package:accredit/core/utils/my_logs.dart';
import 'package:accredit/dal/local/local_source_adapter.dart';
import 'package:accredit/dal/remote/api_adapter.dart';

import 'package:http/http.dart';

class CardItemsManager {

  final String baseApi = app_settings.ASODYA_API_URL;

  final String apiEntity = '/apps';

  final String appName = '/certifications';

  final String appVersion = '/v1';

  late final String baseUrl;

  CardItemsManager() {
    baseUrl = "$baseApi$apiEntity$appName$appVersion";
  }

  // default headers request
  Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<String?> readNextAuthNounce() async {
    final LocalSourceAdapter localSourceAdapter = LocalSourceAdapter(namespace: 'ath');
    final encryptedNounce = await localSourceAdapter.read('n-a-n');
    // decrypt nounce here 
    final encryption = MyEncryption();
    return encryption.decryptPayload(encryptedNounce);
  }

  Future<Response> getCards() async {
    // update the headers with auth nounce

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

    debug('Fetching cards from $baseUrl/all_items with headers: $defaultHeaders');

      // continue with the request
      final response = await ApiAdapter(defaultHeaders: defaultHeaders).get(
        Uri.parse('$baseUrl/all_items'),
      );

      if (response.statusCode == 200) {
      final headers = response.headers;
      // get next auth nounce key = 'n-a-n'
      final nan = headers['n-a-n'];
      if (nan != null) {
        await saveNextAuthNounce(nan);
        debug('Next auth nounce updated: $nan from getCards response headers.');
      } else {
        warning('No next auth nounce found in response headers.');

      }
    }

    return response;

  }

  saveNextAuthNounce(String nan) async {
    final LocalSourceAdapter localSourceAdapter = LocalSourceAdapter(namespace: 'ath');
    await localSourceAdapter.upsert('n-a-n', nan);
    debug('next auth nounce saved: $nan');
  }


  Future<Response> getTopicsFromCard(String itemName, int page, int perPage) async {

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

    debug('Fetching cards from $baseUrl/topics/$itemName?page=$page&per_page=$perPage with headers: $defaultHeaders');

     // continue with the request

    final response = await ApiAdapter(defaultHeaders: defaultHeaders).get(
      Uri.parse('$baseUrl/topics/$itemName?page=$page&per_page=$perPage'),
    );

    if (response.statusCode == 200) {
      final headers = response.headers;
      // get next auth nounce key = 'n-a-n'
      final nan = headers['n-a-n'];
      if (nan != null) {
        await saveNextAuthNounce(nan);
        debug('Next auth nounce updated: $nan from getCards response headers.');
      } else {
        warning('No next auth nounce found in response headers.');

      }
    }

    return response;
  }

  // example 
  // curl -X 'GET' \
  // 'http://127.0.0.1:8001/search/wikipedia?q=santos&page=1&per_page=20&mode=fulltext&fill_page=true&max_extra_pages=2' \
  // -H 'accept: application/json'//

  Future<Response> searchTopics(String itemName, String query, int page, int perPage, String mode, bool fillPage, int maxExtraPages) async {

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

    debug('Fetching cards from $baseUrl/search/$itemName?q=$query&page=$page&per_page=$perPage&mode=$mode&fill_page=$fillPage&max_extra_pages=$maxExtraPages with headers: $defaultHeaders');

     // continue with the request


    final response = await ApiAdapter(defaultHeaders: defaultHeaders).get(
      Uri.parse('$baseUrl/search/$itemName?q=$query&page=$page&per_page=$perPage&mode=$mode&fill_page=$fillPage&max_extra_pages=$maxExtraPages'),
    );

    if (response.statusCode == 200) {
      final headers = response.headers;
      // get next auth nounce key = 'n-a-n'
      final nan = headers['n-a-n'];
      if (nan != null) {
        await saveNextAuthNounce(nan);
        debug('Next auth nounce updated: $nan from getCards response headers.');
      } else {
        warning('No next auth nounce found in response headers.');

      }
    }

    return response;
  }

  

}