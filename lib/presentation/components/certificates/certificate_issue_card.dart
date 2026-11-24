import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/certificate_verification.dart';
import 'package:certifications/domain/services/certificate_verification_api_service.dart';
import 'package:certifications/presentation/components/premium_hover_card.dart';
import 'package:certifications/presentation/widgets/certificates/certificate_verification_screen.dart';
import 'package:flutter/material.dart';

/// Owner-only issue action for a completed attempt. Eligibility and every
/// stored certificate field remain server-authoritative.
class CertificateIssueCard extends StatefulWidget {
  const CertificateIssueCard({
    super.key,
    required this.attemptId,
    this.service,
  });

  final String attemptId;
  final CertificateVerificationApiService? service;

  @override
  State<CertificateIssueCard> createState() => _CertificateIssueCardState();
}

class _CertificateIssueCardState extends State<CertificateIssueCard> {
  late final CertificateVerificationApiService _service =
      widget.service ?? CertificateVerificationApiService();
  late Future<CertificateHolderIdentity> _identity = _service.getMyIdentity();
  final _nameController = TextEditingController();
  IssuedCertificate? _certificate;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String get _previewName => _nameController.text
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .join(' ');

  Future<void> _confirmNameAndIssue() async {
    final name = _previewName;
    if (name.isEmpty || name.runes.length > 120) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('certificateConfirmName')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('certificateNamePreview')),
            const SizedBox(height: 12),
            Text(name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(context.tr('certificateNameImmutable')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('close')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('certificateConfirmName')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final identity = await _service.confirmMyIdentity(name);
      if (!identity.confirmed || identity.displayName != name) {
        throw const FormatException(
          'The server did not confirm the displayed name',
        );
      }
      await _issue();
    } catch (_) {
      if (mounted) setState(() => _error = context.tr('errorGeneric'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _issue() async {
    final certificate = await _service.issueForAttempt(widget.attemptId);
    if (mounted) setState(() => _certificate = certificate);
  }

  Future<void> _issueExistingName() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _issue();
    } catch (_) {
      if (mounted) setState(() => _error = context.tr('errorGeneric'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => FutureBuilder<CertificateHolderIdentity>(
    future: _identity,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError || snapshot.data == null) {
        return OutlinedButton.icon(
          onPressed: () => setState(() => _identity = _service.getMyIdentity()),
          icon: const Icon(Icons.refresh),
          label: Text(context.tr('certificateIdentityUnavailable')),
        );
      }
      final identity = snapshot.data!;
      final confirmedName = identity.confirmed ? identity.displayName : null;
      return PremiumHoverCard(
        accentColor: Theme.of(context).colorScheme.primary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _certificate == null
                  ? context.tr('certificateIssueTitle')
                  : context.tr('certificateIssuedTitle'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (_certificate == null && confirmedName == null) ...[
              Text(context.tr('certificateNameExplanation')),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                maxLength: 120,
                decoration: InputDecoration(
                  labelText: context.tr('certificateHolderName'),
                ),
                onChanged: (_) => setState(() {}),
              ),
              if (_previewName.isNotEmpty) ...[
                Text(context.tr('certificateNamePreview')),
                const SizedBox(height: 4),
                Text(
                  _previewName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed:
                    !_busy &&
                        _previewName.isNotEmpty &&
                        _previewName.runes.length <= 120
                    ? _confirmNameAndIssue
                    : null,
                icon: const Icon(Icons.verified_outlined),
                label: Text(context.tr('certificateConfirmName')),
              ),
            ] else if (_certificate == null) ...[
              Text(context.tr('certificateConfirmedName')),
              const SizedBox(height: 4),
              Text(
                confirmedName!,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _busy ? null : _issueExistingName,
                icon: const Icon(Icons.workspace_premium_outlined),
                label: Text(context.tr('certificateIssueTitle')),
              ),
            ] else ...[
              Text(
                _certificate!.holderName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${context.tr('certificateCode')}: ${_certificate!.verificationCode}',
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CertificateVerificationScreen(
                      code: _certificate!.verificationCode,
                      service: _service,
                    ),
                  ),
                ),
                icon: const Icon(Icons.open_in_new),
                label: Text(context.tr('certificateOpenVerification')),
              ),
            ],
            if (_busy) const LinearProgressIndicator(),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      );
    },
  );
}
