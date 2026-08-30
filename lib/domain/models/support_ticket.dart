/// One message in a support ticket's thread, matching api_for_apps's
/// SupportMessageModel (id, sender, body, attachment_reference, timestamp,
/// read).
class SupportMessage {
  SupportMessage.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String? ?? '',
      sender = json['sender'] as String? ?? 'user',
      body = json['body'] as String? ?? '',
      attachmentReference = json['attachment_reference'] as String?,
      timestamp = json['timestamp'] as String? ?? '',
      read = json['read'] as bool? ?? false;

  final String id;
  final String sender;
  final String body;
  final String? attachmentReference;
  final String timestamp;
  final bool read;

  bool get isFromAdmin => sender == 'admin';
}

/// One row from GET /apps/support/v1/tickets: the Postgres index only,
/// no message thread (see [SupportTicketDetail] for that).
class SupportTicket {
  SupportTicket.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String? ?? '',
      sourceApp = json['source_app'] as String? ?? '',
      status = json['status'] as String? ?? 'open',
      createdAt = json['created_at'] as String?,
      updatedAt = json['updated_at'] as String?;

  final String id;
  final String sourceApp;
  final String status;
  final String? createdAt;
  final String? updatedAt;
}

/// GET /apps/support/v1/tickets/{id} and the response of creating a ticket:
/// the index fields plus the full message thread.
class SupportTicketDetail {
  SupportTicketDetail.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String? ?? '',
      sourceApp = json['source_app'] as String? ?? '',
      status = json['status'] as String? ?? 'open',
      subject = json['subject'] as String?,
      createdAt = json['created_at'] as String?,
      updatedAt = json['updated_at'] as String?,
      messagesAvailable = json['messages_available'] as bool? ?? true,
      messages = ((json['messages'] as List? ?? const [])
              .cast<Map<String, dynamic>>())
          .map(SupportMessage.fromJson)
          .toList();

  final String id;
  final String sourceApp;
  final String status;
  final String? subject;
  final String? createdAt;
  final String? updatedAt;

  /// False when the CouchDB thread store is temporarily unreachable: the
  /// ticket itself still exists (Postgres is authoritative), only its
  /// message content could not be loaded right now.
  final bool messagesAvailable;
  final List<SupportMessage> messages;
}
