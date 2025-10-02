import 'package:accredit/dal/remote/api_adapter.dart';
import 'package:http/http.dart';

class CardItemsManager {

  String baseUrl = 'http://127.0.0.1:8001';

  // default headers request
  Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };



  Future<Response> getCards() {
    return ApiAdapter(defaultHeaders: defaultHeaders).get(
      Uri.parse('$baseUrl/all_items'),
    );
  }

  Future<Response> getTopicsFromCard(String itemName, int page, int perPage) {
    return ApiAdapter(defaultHeaders: defaultHeaders).get(
      Uri.parse('$baseUrl/topics/$itemName?page=$page&per_page=$perPage'),
    );
  }

  // example 
  // curl -X 'GET' \
  // 'http://127.0.0.1:8001/search/wikipedia?q=santos&page=1&per_page=20&mode=fulltext&fill_page=true&max_extra_pages=2' \
  // -H 'accept: application/json'//

  Future<Response> searchTopics(String itemName, String query, int page, int perPage, String mode, bool fillPage, int maxExtraPages) {
    return ApiAdapter(defaultHeaders: defaultHeaders).get(
      Uri.parse('$baseUrl/search/$itemName?q=$query&page=$page&per_page=$perPage&mode=$mode&fill_page=$fillPage&max_extra_pages=$maxExtraPages'),
    );
  }

  

}