import 'dart:convert';

import 'package:accredit/core/utils/my_logs.dart';
import 'package:accredit/core/utils/my_nagivation.dart';
import 'package:accredit/domain/models/certification.dart';
import 'package:accredit/domain/services/api_certification_manager.dart';
import 'package:accredit/presentation/widgets/accredit/on_accredit.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class CertificationsView extends StatefulWidget {
  const CertificationsView({super.key, required this.isDesktop});

  final bool isDesktop;

  @override
  State<CertificationsView> createState() => _CertificationsViewState();
}

class _CertificationsViewState extends State<CertificationsView> {
  late Future<List<Certification>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadCertifications();
  }

  Future<List<Certification>> _loadCertifications() async {
    final manager = CertificationManager();
    final res = await manager.getUserCertifications();

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to load certifications: ${res.statusCode}');
    }

    final decoded = jsonDecode(utf8.decode(res.bodyBytes));

    final List<dynamic> rawList = _extractList(decoded);

    final certs = rawList
        .whereType<Map<String, dynamic>>()
        .map(Certification.fromJson)
        .toList();

    certs.sort((a, b) => b.issuedAt.compareTo(a.issuedAt));

    return certs;
  }

  List<dynamic> _extractList(dynamic payload) {
    if (payload is List) return payload;

    if (payload is Map<String, dynamic>) {
      final data = payload['data'];
      if (data is List) return data;
      if (data is Map<String, dynamic>) {
        final nested = data['certifications'];
        if (nested is List) return nested;
        if (nested is Map<String, dynamic>) return nested.values.toList();
      }

      final topCerts = payload['certifications'];
      if (topCerts is List) return topCerts;
      if (topCerts is Map<String, dynamic>) return topCerts.values.toList();
    }

    return const [];
  }

  void _refresh() {
    setState(() {
      _future = _loadCertifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final header = _CertificationsHeader(
      isDesktop: widget.isDesktop,
      onRefresh: _refresh,
    );

    final body = FutureBuilder<List<Certification>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          debug('Certifications load error: ${snapshot.error}');
          return _CertificationsError(
            message: 'We could not load your certifications right now.',
            onRetry: _refresh,
          );
        }

        final certs = snapshot.data ?? [];
        if (certs.isEmpty) {
          return _CertificationsEmpty(onRefresh: _refresh);
        }

        if (widget.isDesktop) {
          return ListView.separated(
            padding: const EdgeInsets.only(top: 12, bottom: 24),
            itemBuilder: (context, index) {
              final cert = certs[index];
              return CertificationCard(
                certification: cert,
                isDesktop: true,
                onShare: () => _shareCertification(cert),
                onView: () => _openCertification(cert.id),
              );
            },
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: certs.length,
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(top: 12, bottom: 24),
          itemBuilder: (context, index) {
            final cert = certs[index];
            return CertificationCard(
              certification: cert,
              isDesktop: false,
              onShare: () => _shareCertification(cert),
              onView: () => _openCertification(cert.id),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemCount: certs.length,
        );
      },
    );

    return Material(
      color: scheme.surface,
      child: SafeArea(
        child: widget.isDesktop
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    header,
                    const SizedBox(height: 18),
                    Expanded(child: body),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    header,
                    const SizedBox(height: 14),
                    Expanded(child: body),
                  ],
                ),
              ),
      ),
    );
  }

  Future<void> _shareCertification(Certification cert) async {
    if (cert.shareUrl.isEmpty) return;
    await Share.share(cert.shareUrl, subject: cert.title);
  }

  void _openCertification(String certificationId) {
    if (certificationId.isEmpty) return;
    NavigationService.push(
      OnAccreditScreen(certificationId: certificationId),
    );
  }
}

class _CertificationsHeader extends StatelessWidget {
  const _CertificationsHeader({required this.isDesktop, required this.onRefresh});

  final bool isDesktop;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Certifications',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Share your achievements or open the full certificate.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withOpacity(0.65),
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh),
          label: Text(isDesktop ? 'Refresh list' : 'Refresh'),
        ),
      ],
    );
  }
}

class _CertificationsEmpty extends StatelessWidget {
  const _CertificationsEmpty({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.7),
            blurRadius: 8,
            offset: const Offset(-1, -1),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No certifications yet.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Complete a quiz to earn your first certification and it will appear here.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withOpacity(0.65),
                ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Check again'),
          ),
        ],
      ),
    );
  }
}

class _CertificationsError extends StatelessWidget {
  const _CertificationsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.error.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: scheme.error,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class CertificationCard extends StatelessWidget {
  const CertificationCard({
    super.key,
    required this.certification,
    required this.onShare,
    required this.onView,
    required this.isDesktop,
  });

  final Certification certification;
  final VoidCallback onShare;
  final VoidCallback onView;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.primary.withOpacity(0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.7),
            blurRadius: 6,
            offset: const Offset(-1, -1),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      certification.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      certification.fullName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurface.withOpacity(0.7),
                          ),
                    ),
                    if (certification.certificationAs != null &&
                        certification.certificationAs!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        certification.certificationAs!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              _BadgePill(
                label: 'Issued ${certification.issuedAtLabel}',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.language,
                label: certification.language == null
                    ? 'Language: —'
                    : 'Language: ${certification.language}',
              ),
              if (certification.score != null)
                _InfoChip(
                  icon: Icons.score,
                  label: 'Score ${certification.score!.toStringAsFixed(1)}',
                ),
              if (certification.totalQuestions != null)
                _InfoChip(
                  icon: Icons.help_outline,
                  label: '${certification.totalQuestions} questions',
                ),
            ],
          ),
          const SizedBox(height: 16),
          isDesktop
              ? Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: onView,
                      icon: const Icon(Icons.remove_red_eye_outlined),
                      label: const Text('View certificate'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: onShare,
                      icon: const Icon(Icons.ios_share),
                      label: const Text('Share link'),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: onView,
                      icon: const Icon(Icons.remove_red_eye_outlined),
                      label: const Text('View certificate'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: onShare,
                      icon: const Icon(Icons.ios_share),
                      label: const Text('Share link'),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  const _BadgePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.surfaceVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.onSurface.withOpacity(0.7)),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.onSurface.withOpacity(0.8),
                ),
          ),
        ],
      ),
    );
  }
}
