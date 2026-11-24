import 'dart:js_interop';
import 'dart:typed_data';

import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/certificate_verification.dart';
import 'package:certifications/domain/services/certificate_verification_api_service.dart';
import 'package:certifications/presentation/components/attachment/app_bar.dart';
import 'package:certifications/presentation/components/premium_hover_card.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// Public, factual certificate lookup. Activity details are shown online only;
/// downloads are server-rendered artifacts without the activity projection.
class CertificateVerificationScreen extends StatefulWidget {
  const CertificateVerificationScreen({
    super.key,
    required this.code,
    this.service,
  });

  final String code;
  final CertificateVerificationApiService? service;

  @override
  State<CertificateVerificationScreen> createState() =>
      _CertificateVerificationScreenState();
}

class _CertificateVerificationScreenState
    extends State<CertificateVerificationScreen> {
  late final CertificateVerificationApiService _service =
      widget.service ?? CertificateVerificationApiService();
  late Future<CertificateVerification> _verification = _service.verify(
    widget.code,
  );
  bool _downloading = false;
  String? _downloadError;

  Future<void> _download(String format) async {
    setState(() {
      _downloading = true;
      _downloadError = null;
    });
    try {
      final file = format == 'pdf'
          ? await _service.downloadPdf(widget.code)
          : await _service.downloadImage(widget.code);
      final blob = web.Blob(
        [Uint8List.fromList(file.bytes).toJS].toJS,
        web.BlobPropertyBag(type: file.contentType),
      );
      final url = web.URL.createObjectURL(blob);
      final extension = format == 'image' ? 'svg' : format;
      final anchor = web.HTMLAnchorElement()
        ..href = url
        ..download =
            'certificate-${Uri.encodeComponent(widget.code)}.$extension';
      web.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      web.URL.revokeObjectURL(url);
    } catch (_) {
      if (mounted) setState(() => _downloadError = context.tr('errorGeneric'));
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AttachmentAppBar(title: context.tr('certificateVerification')),
    body: FutureBuilder<CertificateVerification>(
      future: _verification,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final value = snapshot.data;
        if (snapshot.hasError || value == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.tr('certificateUnavailable')),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => setState(
                    () => _verification = _service.verify(widget.code),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: Text(context.tr('retry')),
                ),
              ],
            ),
          );
        }
        final scheme = Theme.of(context).colorScheme;
        final activity = value.activitySummary;
        final issued = DateTime.fromMillisecondsSinceEpoch(
          value.issuedAt * 1000,
        ).toLocal();
        final status = switch (value.status) {
          'active' => context.tr('certificateActive'),
          'revoked' => context.tr('certificateRevoked'),
          _ => value.status,
        };
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PremiumHoverCard(
                      accentColor: scheme.primary,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.verified_outlined,
                                color: scheme.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  context.tr('certificateVerification'),
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              Chip(label: Text(status)),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _Fact(
                            label: context.tr('certificateHolder'),
                            value: value.holderName,
                          ),
                          _Fact(
                            label: context.tr('certificateQuiz'),
                            value: value.quizTitle,
                          ),
                          _Fact(
                            label: context.tr('certificateScore'),
                            value:
                                '${value.scoreCorrect} / ${value.scoreTotal}',
                          ),
                          _Fact(
                            label: context.tr('certificateIssued'),
                            value: MaterialLocalizations.of(
                              context,
                            ).formatMediumDate(issued),
                          ),
                          _Fact(
                            label: context.tr('certificateCode'),
                            value: value.verificationCode,
                          ),
                          if (value.status == 'revoked' &&
                              value.revocationReason.isNotEmpty)
                            _Fact(
                              label: context.tr('certificateRevocationReason'),
                              value: value.revocationReason,
                            ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _downloading
                                    ? null
                                    : () => _download('pdf'),
                                icon: const Icon(Icons.picture_as_pdf_outlined),
                                label: Text(context.tr('downloadPdf')),
                              ),
                              OutlinedButton.icon(
                                onPressed: _downloading
                                    ? null
                                    : () => _download('image'),
                                icon: const Icon(Icons.image_outlined),
                                label: Text(context.tr('downloadImage')),
                              ),
                            ],
                          ),
                          if (_downloading) const LinearProgressIndicator(),
                          if (_downloadError != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _downloadError!,
                                style: TextStyle(color: scheme.error),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ExpansionTile(
                      key: const PageStorageKey('certificate-activity'),
                      title: Text(context.tr('certificateActivity')),
                      subtitle: Text(
                        '${context.tr('certificateCompleteness')}: ${activity.completeness}',
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(activity.disclaimer),
                        ),
                        const SizedBox(height: 10),
                        _Fact(
                          label: context.tr('certificateFocusLoss'),
                          value: '${activity.focusLostCount}',
                        ),
                        _Fact(
                          label: context.tr('certificatePageHidden'),
                          value: '${activity.pageHiddenCount}',
                        ),
                        _Fact(
                          label: context.tr('certificatePageReturns'),
                          value: '${activity.pageReturnCount}',
                        ),
                        _Fact(
                          label: context.tr('certificateKnownAway'),
                          value: _duration(activity.knownAwayMs),
                        ),
                        _Fact(
                          label: context.tr('certificateReconnects'),
                          value: '${activity.reconnectCount}',
                        ),
                        _Fact(
                          label: context.tr('certificateRefreshes'),
                          value: '${activity.refreshCount}',
                        ),
                        _Fact(
                          label: context.tr('certificateUnknownGaps'),
                          value: '${activity.unknownGapCount}',
                        ),
                        if (activity.events.isNotEmpty) ...[
                          const Divider(),
                          for (final event in activity.events)
                            ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(event.eventKind),
                              subtitle: Text(
                                MaterialLocalizations.of(
                                  context,
                                ).formatMediumDate(
                                  DateTime.fromMillisecondsSinceEpoch(
                                    event.occurredAt * 1000,
                                  ).toLocal(),
                                ),
                              ),
                              trailing: event.durationMs > 0
                                  ? Text(_duration(event.durationMs))
                                  : null,
                            ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );

  String _duration(int milliseconds) {
    final seconds = milliseconds ~/ 1000;
    return '${seconds ~/ 60}m ${seconds % 60}s';
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth < 430
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 2),
                Text(value),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 180,
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                Expanded(child: Text(value)),
              ],
            ),
    ),
  );
}
