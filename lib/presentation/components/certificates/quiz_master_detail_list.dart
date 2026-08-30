import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/quiz.dart';
import 'package:certifications/presentation/components/premium_hover_card.dart';
import 'package:flutter/material.dart';

/// Bespoke, premium-styled master/detail list: a custom scrollable list of
/// [quizzes] (never a default ListTile/ListView-only look) where selecting
/// an item renders [detailBuilder]'s output for it in the same card, with no
/// navigation. Shared by the dashboard's per-certificate mini-list (#37) and
/// the Certificates tab's Public/Private sub-tabs (#39), per #37's own note
/// that this exact pattern was meant to be reused there.
class QuizMasterDetailList extends StatefulWidget {
  const QuizMasterDetailList({
    super.key,
    required this.quizzes,
    required this.detailBuilder,
    required this.emptyIcon,
    required this.emptyMessage,
    this.isDesktop = false,
    this.listExtent = 320,
  });

  final List<Quiz> quizzes;
  final Widget Function(BuildContext context, Quiz quiz) detailBuilder;
  final IconData emptyIcon;
  final String emptyMessage;
  final bool isDesktop;

  /// Height (mobile, stacked) or width (desktop, side-by-side) reserved for
  /// the list pane.
  final double listExtent;

  @override
  State<QuizMasterDetailList> createState() => _QuizMasterDetailListState();
}

class _QuizMasterDetailListState extends State<QuizMasterDetailList> {
  Quiz? _selected;

  @override
  void didUpdateWidget(covariant QuizMasterDetailList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_selected != null && !widget.quizzes.any((q) => q.id == _selected!.id)) {
      _selected = widget.quizzes.isEmpty ? null : widget.quizzes.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (widget.quizzes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(widget.emptyIcon, size: 48, color: scheme.onSurface.withValues(alpha: 0.35)),
            const SizedBox(height: 12),
            Text(
              widget.emptyMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    final selected = _selected ?? widget.quizzes.first;
    final list = SizedBox(
      height: widget.isDesktop ? null : widget.listExtent,
      child: ListView.separated(
        shrinkWrap: !widget.isDesktop ? false : true,
        physics: widget.isDesktop ? const NeverScrollableScrollPhysics() : null,
        itemCount: widget.quizzes.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final quiz = widget.quizzes[index];
          final isSelected = quiz.id == selected.id;
          return _QuizListRow(
            quiz: quiz,
            selected: isSelected,
            onTap: () => setState(() => _selected = quiz),
          );
        },
      ),
    );

    final detail = AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: KeyedSubtree(
        key: ValueKey(selected.id),
        child: widget.detailBuilder(context, selected),
      ),
    );

    if (widget.isDesktop) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: widget.listExtent, child: SingleChildScrollView(child: list)),
            const SizedBox(width: 20),
            Expanded(child: detail),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        list,
        const Divider(height: 28),
        detail,
      ],
    );
  }
}

class _QuizListRow extends StatelessWidget {
  const _QuizListRow({required this.quiz, required this.selected, required this.onTap});

  final Quiz quiz;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isPublic = quiz.visibility == QuizVisibility.public;

    return PremiumHoverCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: 16,
      selected: selected,
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            isPublic ? Icons.public : Icons.lock_outline,
            size: 18,
            color: selected ? scheme.primary : scheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              quiz.title.isEmpty ? quiz.id : quiz.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
          if (selected)
            Icon(Icons.chevron_right, size: 18, color: scheme.primary),
        ],
      ),
    );
  }
}

/// Default detail content: the honest, currently-available stats for a
/// quiz (no fabricated per-attempt score, since the app has no client-side
/// source of the current user's own score on a quiz yet).
Widget buildQuizStatDetail(BuildContext context, Quiz quiz) {
  final scheme = Theme.of(context).colorScheme;
  final isPublic = quiz.visibility == QuizVisibility.public;

  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          quiz.title.isEmpty ? quiz.id : quiz.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 20,
          runSpacing: 12,
          children: [
            _StatField(
              icon: Icons.event_outlined,
              label: context.tr('completedOnLabel'),
              value: quiz.createdAt.isEmpty ? '-' : quiz.createdAt.split('T').first,
            ),
            _StatField(
              icon: Icons.quiz_outlined,
              label: context.tr('question'),
              value: '${quiz.totalQuestions}',
            ),
            _StatField(
              icon: Icons.groups_outlined,
              label: context.tr('totalAttemptsLabel'),
              value: '${quiz.totalAttempts}',
            ),
            _StatField(
              icon: isPublic ? Icons.public : Icons.lock_outline,
              label: context.tr('visibilityLabel'),
              value: isPublic ? context.tr('visibilityPublic') : context.tr('visibilityPrivate'),
            ),
          ],
        ),
      ],
    ),
  );
}

class _StatField extends StatelessWidget {
  const _StatField({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
