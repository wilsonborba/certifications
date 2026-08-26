import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:certifications/domain/models/certification.dart';

class CertificateBody extends StatelessWidget {
  final Certification cert;
  final GlobalKey captureKey;
  final double maxWidth;
  final double verticalDensity;

  const CertificateBody({
    super.key,
    required this.cert,
    required this.captureKey,
    required this.maxWidth,
    required this.verticalDensity,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return RepaintBoundary(
      key: captureKey,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 28 * verticalDensity,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.surface,
                scheme.surfaceContainerHighest.withOpacity(0.9),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
            border: Border.all(color: scheme.outlineVariant, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /// HEADER — Title + icon
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_outlined, color: scheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    cert.title,
                    style: text.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 18 * verticalDensity),

              Text(
                'This acknowledges that',
                style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8 * verticalDensity),

              /// FULL NAME
              Text(
                cert.fullName,
                textAlign: TextAlign.center,
                style: text.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.05,
                ),
              ),

              /// Certification role / type
              if ((cert.certificationAs ?? '').isNotEmpty) ...[
                SizedBox(height: 14 * verticalDensity),
                Text(
                  'has successfully completed all the requirements to be recognized as a',
                  style: text.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 6 * verticalDensity),
                Text(
                  cert.certificationAs!,
                  style: text.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              SizedBox(height: 20 * verticalDensity),

              /// META INFO: Issued, series id, score, language…
              Wrap(
                spacing: 18,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _MetaChip(label: 'Issued', value: cert.issuedAtLabel),
                  if (cert.expiresAtLabel != null)
                    _MetaChip(label: 'Expires', value: cert.expiresAtLabel!),
                  _MetaChip(label: 'Series ID', value: cert.seriesId),
                  if (cert.language != null)
                    _MetaChip(label: 'Language', value: cert.language!),
                  if (cert.score != null)
                    _MetaChip(
                      label: 'Score',
                      value: '${cert.score!.toStringAsFixed(2)}%',
                    ),
                ],
              ),

              /// QUIZ STATS (optional)
              if (cert.totalQuestions != null) ...[
                SizedBox(height: 8 * verticalDensity),
                Wrap(
                  spacing: 18,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _MetaChip(
                      label: 'Total Q',
                      value: '${cert.totalQuestions ?? 0}',
                    ),
                    _MetaChip(
                      label: 'Correct',
                      value: '${cert.correctQuestions ?? 0}',
                    ),
                    _MetaChip(
                      label: 'Wrong',
                      value: '${cert.wrongQuestions ?? 0}',
                    ),
                  ],
                ),
              ],

              SizedBox(height: 24 * verticalDensity),

              /// Signature + Seal + QR code section
              LayoutBuilder(
                builder: (context, constraints) {
                  final isTight = constraints.maxWidth < 560;

                  return Wrap(
                    spacing: 28,
                    runSpacing: 24,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.center,
                    children: [
                      /// SIGNATURE
                      Column(
                        children: [
                          Image.asset(
                            'lib/presentation/assets/img/signature.png',
                            width: isTight ? 180 : 220,
                            fit: BoxFit.contain,
                          ),
                          SizedBox(
                            width: 240,
                            child: Divider(
                              color: scheme.outline,
                              thickness: 1.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            cert.issuerName ?? 'Certification Officer',
                            style: text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (cert.issuerTitle != null)
                            Text(
                              cert.issuerTitle!,
                              style: text.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),

                      /// SEAL
                      _Seal(scheme: scheme),

                      /// QR CODE
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: scheme.outlineVariant),
                            ),
                            child: QrImageView(
                              data: cert.shareUrl,
                              version: QrVersions.auto,
                              size: isTight ? 120 : 140,
                              gapless: true,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text('Verify / Share', style: text.bodySmall),
                        ],
                      ),
                    ],
                  );
                },
              ),

              SizedBox(height: 12),

              /// Share URL
              SelectableText(
                cert.shareUrl,
                textAlign: TextAlign.center,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final String value;

  const _MetaChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: TextStyle(color: scheme.onSurfaceVariant)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Seal extends StatelessWidget {
  final ColorScheme scheme;

  const _Seal({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [scheme.surfaceContainerHighest, scheme.surface],
        ),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withOpacity(0.1),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.workspace_premium_outlined,
          size: 40,
          color: scheme.primary,
        ),
      ),
    );
  }
}
