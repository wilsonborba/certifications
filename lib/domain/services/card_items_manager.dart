import 'package:accredit/dal/remote/api_adapter.dart';
import 'package:http/http.dart';

class CardItemsManager {

  // default headers request
  Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };



  Future<Response> getCards() {
    return ApiAdapter(defaultHeaders: defaultHeaders).get(
      Uri.parse('http://localhost:8001/all_items'),
    );
  }

  Future<Response> getTopicsFromCard(String itemName) {
    return ApiAdapter(defaultHeaders: defaultHeaders).get(
      Uri.parse('http://localhost:8001/topics/$itemName'),
    );
  }

  

}