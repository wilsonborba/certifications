import 'dart:convert';

import 'package:certifications/core/settings.dart';
import 'package:certifications/dal/remote/api_adapter.dart';
import 'package:certifications/domain/models/support_ticket.dart';
import 'package:http_parser/http_parser.dart';

class SupportApiException implements Exception {
  const SupportApiException(this.statusCode);
  final int statusCode;
}

/// Client for api_for_apps's central cross-app support ticket system
/// (api_for_apps#17). Every call is scoped to this app: source_app is
/// always sent/filtered as 'certifications', matching how this screen only
/// ever shows and creates tickets for this app.
class SupportApiService {
  SupportApiService({ApiAdapter? adapter})
    : _adapter =
          adapter ??
          ApiAdapter(defaultHeaders: const {'Accept': 'application/json'});
  final ApiAdapter _adapter;

  static const _sourceApp = 'certifications';

  String get _base => '${app_settings.ASODYA_API_URL}/apps/support/v1';

  Future<List<SupportTicket>> listTickets() async {
    final response = await _adapter.get(
      Uri.parse('$_base/tickets'),
      queryParams: {'source_app': _sourceApp},
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SupportApiException(response.statusCode);
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return ((payload['data'] as List? ?? const [])
            .cast<Map<String, dynamic>>())
        .map(SupportTicket.fromJson)
        .toList();
  }

  Future<SupportTicketDetail> createTicket({
    String? subject,
    required String body,
    String? attachmentReference,
  }) async {
    final response = await _adapter.post(
      Uri.parse('$_base/tickets'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'source_app': _sourceApp,
        'subject': subject,
        'body': body,
        'attachment_reference': attachmentReference,
      }),
    );
    return SupportTicketDetail.fromJson(_data(response));
  }

  Future<SupportTicketDetail> getTicket(String ticketId) async =>
      SupportTicketDetail.fromJson(
        _data(await _adapter.get(Uri.parse('$_base/tickets/$ticketId'))),
      );

  Future<SupportMessage> postMessage(
    String ticketId, {
    required String body,
    String? attachmentReference,
  }) async {
    final response = await _adapter.post(
      Uri.parse('$_base/tickets/$ticketId/messages'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'body': body,
        'attachment_reference': attachmentReference,
      }),
    );
    return SupportMessage.fromJson(_data(response));
  }

  Future<void> markTicketRead(String ticketId) async {
    final response = await _adapter.patch(
      Uri.parse('$_base/tickets/$ticketId/read'),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SupportApiException(response.statusCode);
    }
  }

  /// Uploads an attachment to FSM via api_for_apps and returns the
  /// attachment_reference to pass into [createTicket] or [postMessage].
  Future<String> uploadAttachment({
    required String filename,
    required List<int> bytes,
    required String mimeType,
  }) async {
    final response = await _adapter.postMultipart(
      url: Uri.parse('$_base/attachments'),
      files: [
        MultipartFileData(
          field: 'file',
          bytes: bytes,
          filename: filename,
          contentType: MediaType.parse(mimeType),
        ),
      ],
    );
    final data = _data(response);
    return data['attachment_reference'] as String;
  }

  Map<String, dynamic> _data(dynamic response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SupportApiException(response.statusCode);
    }
    return (jsonDecode(response.body) as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
  }
}
