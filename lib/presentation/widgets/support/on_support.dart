import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/support_ticket.dart';
import 'package:certifications/domain/services/support_api_service.dart';
import 'package:certifications/presentation/components/attachment/app_bar.dart';
import 'package:certifications/presentation/components/premium_hover_card.dart';
import 'package:certifications/presentation/widgets/support/on_support_ticket.dart';
import 'package:flutter/material.dart';

/// Support tab (#35): a normal per-user ticket screen, CRUD against
/// api_for_apps's central support system (api_for_apps#17). The cross-app
/// admin panel is explicitly out of scope here, tracked separately.
class OnSupportScreen extends StatefulWidget {
  const OnSupportScreen({super.key});

  @override
  State<OnSupportScreen> createState() => _OnSupportScreenState();
}

class _OnSupportScreenState extends State<OnSupportScreen> {
  final _api = SupportApiService();
  late Future<List<SupportTicket>> _future = _api.listTickets();

  void _reload() => setState(() => _future = _api.listTickets());

  Future<void> _openNewTicket() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _NewTicketDialog(api: _api),
    );
    if (created == true) _reload();
  }

  Future<void> _openTicket(SupportTicket ticket) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SupportTicketScreen(ticketId: ticket.id)),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AttachmentAppBar(title: context.tr('support'), currentTab: 'support'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewTicket,
        icon: const Icon(Icons.add_comment_outlined),
        label: Text(context.tr('newTicket')),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: RefreshIndicator(
              onRefresh: () async => _reload(),
              child: FutureBuilder<List<SupportTicket>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Text(context.tr('errorGeneric')),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: _reload,
                                child: Text(context.tr('retry')),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                  final tickets = snapshot.data ?? const [];
                  if (tickets.isEmpty) {
                    return ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 80),
                          child: Column(
                            children: [
                              Icon(
                                Icons.support_agent_outlined,
                                size: 56,
                                color: scheme.onSurface.withValues(alpha: 0.35),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                context.tr('noSupportTicketsYet'),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: tickets.length,
                    itemBuilder: (context, index) {
                      final ticket = tickets[index];
                      final statusColor = _statusColor(ticket.status);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: PremiumHoverCard(
                          onTap: () => _openTicket(ticket),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(Icons.confirmation_number_outlined, color: statusColor),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ticket.id.substring(0, 8),
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _statusLabel(context, ticket.status),
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: statusColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, color: scheme.onSurface.withValues(alpha: 0.4)),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'resolved':
      case 'closed':
        return Colors.green;
      case 'pending':
        return Colors.amber;
      default:
        return Colors.blueAccent;
    }
  }

  String _statusLabel(BuildContext context, String status) {
    switch (status) {
      case 'resolved':
        return context.tr('ticketStatusResolved');
      case 'closed':
        return context.tr('ticketStatusClosed');
      case 'pending':
        return context.tr('ticketStatusPending');
      default:
        return context.tr('ticketStatusOpen');
    }
  }
}

class _NewTicketDialog extends StatefulWidget {
  const _NewTicketDialog({required this.api});
  final SupportApiService api;

  @override
  State<_NewTicketDialog> createState() => _NewTicketDialogState();
}

class _NewTicketDialogState extends State<_NewTicketDialog> {
  final _subjectController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final body = _bodyController.text.trim();
    if (body.isEmpty) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.api.createTicket(
        subject: _subjectController.text.trim().isEmpty
            ? null
            : _subjectController.text.trim(),
        body: body,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _error = context.tr('errorGeneric');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.tr('newTicket')),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(
                labelText: context.tr('ticketSubjectLabel'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyController,
              minLines: 3,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: context.tr('ticketBodyLabel'),
                border: const OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context, false),
          child: Text(context.tr('cancel')),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.tr('submit')),
        ),
      ],
    );
  }
}
