import 'package:certifications/core/utils/app_localizations.dart';
import 'package:flutter/material.dart';

class BoardingMarketing extends StatelessWidget {
  const BoardingMarketing({super.key, required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Certifications',
          subtitle:
              'Turn what you learn into quizzes and shareable certifications.',
          titleSize: isDesktop ? 34 : 24,
          subtitleSize: isDesktop ? 18 : 14,
        ),
        const SizedBox(height: 24),
        _HeroCard(isDesktop: isDesktop),
        const SizedBox(height: 32),
        _SectionTitle(title: 'How it works', titleSize: isDesktop ? 26 : 20),
        const SizedBox(height: 12),
        _StepsRow(isDesktop: isDesktop),
        const SizedBox(height: 32),
        _SectionTitle(
          title: 'What you can create',
          titleSize: isDesktop ? 26 : 20,
        ),
        const SizedBox(height: 12),
        _ExamplesWrap(isDesktop: isDesktop),
        const SizedBox(height: 32),
        _SectionTitle(
          title: 'Why it’s different',
          titleSize: isDesktop ? 26 : 20,
        ),
        const SizedBox(height: 12),
        _BulletsList(isDesktop: isDesktop),
        const SizedBox(height: 32),
        _SectionTitle(
          title: context.tr('trustTransparency'),
          titleSize: isDesktop ? 26 : 20,
        ),
        const SizedBox(height: 12),
        _TrustPanel(isDesktop: isDesktop),
        const SizedBox(height: 32),
        _SectionTitle(
          title: 'MVP today, more tomorrow',
          titleSize: isDesktop ? 26 : 20,
        ),
        const SizedBox(height: 12),
        _MvpPanel(isDesktop: isDesktop),
        const SizedBox(height: 28),
        Divider(color: scheme.outlineVariant.withOpacity(0.5)),
        const SizedBox(height: 12),
        Text(
          'Share your certifications anywhere.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: scheme.onSurface.withOpacity(0.75),
            fontSize: isDesktop ? 16 : 13,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Quizzes are AI-generated; verify results before you publish.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: scheme.onSurface.withOpacity(0.6),
            fontSize: isDesktop ? 14 : 12,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.titleSize,
    required this.subtitleSize,
  });

  final String title;
  final String subtitle;
  final double titleSize;
  final double subtitleSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: titleSize,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: scheme.onSurface.withOpacity(0.7),
            fontSize: subtitleSize,
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary.withOpacity(0.16), scheme.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Learn. Quiz. Get certified.',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: isDesktop ? 28 : 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Attach a PDF. We create a quiz. Finish it and share a certification with your score.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withOpacity(0.7),
              fontSize: isDesktop ? 16 : 13,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _CtaChip(label: 'Start a certification', filled: true),
              _CtaChip(label: 'See how it works', filled: false),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.titleSize});

  final String title;
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: titleSize,
      ),
    );
  }
}

class _StepsRow extends StatelessWidget {
  const _StepsRow({required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final items = const [
      _StepContent(
        title: 'Attach your PDF',
        body: 'Upload a PDF to create your quiz.',
      ),
      _StepContent(
        title: 'Take the quiz',
        body: 'We generate questions from your content.',
      ),
      _StepContent(
        title: 'Share your certification',
        body: 'Get a clean certificate with your topic and score.',
      ),
    ];

    if (isDesktop) {
      return Row(
        children:
            items
                .map((item) => Expanded(child: _StepCard(content: item)))
                .expand((widget) => [widget, const SizedBox(width: 16)])
                .toList()
              ..removeLast(),
      );
    }

    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _StepCard(content: item),
            ),
          )
          .toList(),
    );
  }
}

class _StepContent {
  const _StepContent({required this.title, required this.body});

  final String title;
  final String body;
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.content});

  final _StepContent content;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            content.title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            content.body,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExamplesWrap extends StatelessWidget {
  const _ExamplesWrap({required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final examples = const [
      'Cloud Security Fundamentals',
      'AI Basics for Product Teams',
      'Jazz History Essentials',
      'Film Directors: A Quiz',
      'Space Exploration 101',
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: examples
          .map((item) => _TagChip(label: item, fontSize: isDesktop ? 14 : 12))
          .toList(),
    );
  }
}

class _BulletsList extends StatelessWidget {
  const _BulletsList({required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bullets = const [
      'Built from your own material.',
      'Shareable, score-based certifications.',
      'Multiple certifications per user.',
      'Start free with your own API key.',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: bullets
          .map(
            (bullet) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: isDesktop ? 18 : 16,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      bullet,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: isDesktop ? 15 : 13,
                        color: scheme.onSurface.withOpacity(0.85),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _TrustPanel extends StatelessWidget {
  const _TrustPanel({required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('trustTitle'),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            context.tr('trustBody'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withOpacity(0.7),
              fontSize: isDesktop ? 14 : 12,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.tr('privacyTitle'),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            context.tr('privacyBody'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withOpacity(0.7),
              fontSize: isDesktop ? 14 : 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MvpPanel extends StatelessWidget {
  const _MvpPanel({required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available now',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'PDF documents.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withOpacity(0.7),
              fontSize: isDesktop ? 14 : 12,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Coming next (if users want it)',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'YouTube quiz generation.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withOpacity(0.7),
              fontSize: isDesktop ? 14 : 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _CtaChip extends StatelessWidget {
  const _CtaChip({required this.label, required this.filled});

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: filled ? scheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.primary.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: filled ? scheme.onPrimary : scheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.fontSize});

  final String label;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(0.25),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.surfaceVariant),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: scheme.onSurface.withOpacity(0.85),
          fontSize: fontSize,
        ),
      ),
    );
  }
}
