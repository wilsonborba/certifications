// widgets/quiz/question_card.dart
import 'dart:ui';

import 'package:certifications/domain/models/quiz.dart';
import 'package:certifications/domain/services/api_certification_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Kebab extends StatelessWidget {
  final VoidCallback onComplain;
  const Kebab({super.key, required this.onComplain});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (v) {
        if (v == 'complain') onComplain();
      },
      // small nudge so the menu drops just below the button (tweak if desired)
      offset: const Offset(0, 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 6,
      color: Colors.white,
      itemBuilder: (ctx) => const [
        PopupMenuItem<String>(
          value: 'complain',
          child: Row(
            children: [
              Icon(Icons.report_problem_outlined, size: 20),
              SizedBox(width: 10),
              Text('Report this question…'),
            ],
          ),
        ),
      ],

      // Keep your circular “...” visual as the trigger
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black87, width: 2),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(Icons.more_horiz, size: 20, color: Colors.black87),
        ),
      ),
    );
  }
}

class QuestionCard extends StatelessWidget {
  final int index; // 1-based for display
  final QuestionItem item;
  final int? selectedIndex; // which option is selected
  final ValueChanged<int?> onChanged; // emits option index
  final VoidCallback onComplain;

  const QuestionCard({
    super.key,
    required this.index,
    required this.item,
    required this.selectedIndex,
    required this.onChanged,
    required this.onComplain,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final difficultyText = _difficultyLabel(item.difficulty);
    final difficultyColor = _difficultyColor(item.difficulty);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: title + menu
          Row(
            children: [
              Expanded(
                child: Text(
                  'Question $index',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (difficultyText != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: difficultyColor.withAlpha((.12 * 255).toInt()),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: difficultyColor.withAlpha((.5 * 255).toInt()),
                    ),
                  ),
                  child: Text(
                    difficultyText,
                    style: TextStyle(
                      color: difficultyColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              Kebab(onComplain: onComplain),
            ],
          ),
          const SizedBox(height: 14),
          // Question text
          Text(
            item.question,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          // Options
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // inside your QuestionCard build:
              RadioGroup<int>(
                groupValue: selectedIndex,
                onChanged: onChanged,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < item.options.length; i++)
                      RadioListTile<int>.adaptive(
                        value: i,
                        title: Text(
                          '${String.fromCharCode(65 + i)}) ${item.options[i]}',
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 6,
                        ),
                        dense: true,
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? _difficultyLabel(int? d) {
    //  integer (1 to 6, based on Bloom’s Taxonomy levels)
    switch (d) {
      case 1:
        return 'Remembering';
      case 2:
        return 'Understanding';
      case 3:
        return 'Applying';
      case 4:
        return 'Analyzing';
      case 5:
        return 'Evaluating';
      case 6:
        return 'Creating';
    }
    return null;
  }

  Color _difficultyColor(int? d) {
    //  integer (1 to 6, based on Bloom’s Taxonomy levels)
    switch (d) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.amber;
      case 5:
        return Colors.redAccent;
      case 6:
        return Colors.purple;
    }
    return Colors.grey;
  }
}

class SafeSpacer extends StatelessWidget {
  const SafeSpacer({
    super.key,
    this.flex = 1,
    this.fallback = const SizedBox.shrink(),
  });
  final int flex;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    // Walk up the tree to find a Row/Column (Flex)
    final isInsideFlex = context.findAncestorWidgetOfExactType<Flex>() != null;
    if (isInsideFlex)
      return Expanded(flex: flex, child: const SizedBox.shrink());
    return fallback; // Not in Flex → return a harmless placeholder (or a SizedBox(width: 8))
  }
}

Future<void> showComplaintDialog(
  BuildContext context, {
  required int questionIndex,
  required dynamic questionId,
  required bool isForPDF,
  required dynamic pdfQuestionId,
  required String contextId,
  int maxChars = 600,
  void Function(String text)? onSubmit,
}) async {
  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.black.withAlpha((0.2 * 255).toInt()),
    transitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, __, ___) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 18 * anim.value,
          sigmaY: 18 * anim.value,
        ),
        child: Opacity(
          opacity: anim.value,
          child: Center(
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.98, end: 1.0).animate(curved),
              child: _ComplaintGlassDialog(
                questionIndex: questionIndex,
                maxChars: maxChars,
                onCancel: () {
                  HapticFeedback.selectionClick();
                  Navigator.of(ctx).pop();
                },
                onSend: (text) async {
                  HapticFeedback.lightImpact();
                  if (onSubmit != null) onSubmit(text);
                  Navigator.of(ctx).pop();
                  final manager = CertificationManager();
                  final _ = await manager.applyComplain(
                    text,
                    isForPDF,
                    contextId,
                    pdfQuestionId,
                  );
                },
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _ComplaintGlassDialog extends StatefulWidget {
  const _ComplaintGlassDialog({
    required this.questionIndex,
    required this.maxChars,
    required this.onCancel,
    required this.onSend,
  });

  final int questionIndex;
  final int maxChars;
  final VoidCallback onCancel;
  final void Function(String text) onSend;

  @override
  State<_ComplaintGlassDialog> createState() => _ComplaintGlassDialogState();
}

class _ComplaintGlassDialogState extends State<_ComplaintGlassDialog> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;
  late int _remaining;

  bool get _canSend => _ctrl.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
    _focus = FocusNode();
    _remaining = widget.maxChars;
    _ctrl.addListener(_onChanged);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onChanged);
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged() {
    setState(() {
      _remaining = widget.maxChars - _ctrl.text.characters.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final radius = 20.0;
    const purple = Color(0xFF7C4DFF);
    final insets = MediaQuery.of(context).viewInsets;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        bottom: insets.bottom + 16,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            color: Colors.white.withAlpha((0.65 * 255).toInt()),
            border: Border.all(
              color: Colors.white.withAlpha((0.7 * 255).toInt()),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.08 * 255).toInt()),
                blurRadius: 28,
                spreadRadius: 2,
                offset: const Offset(0, 14),
              ),
            ],
            gradient: LinearGradient(
              colors: [
                Colors.white.withAlpha((0.72 * 255).toInt()),
                Colors.white.withAlpha((0.55 * 255).toInt()),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                height: 36,
                                width: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      purple.withAlpha((0.18 * 255).toInt()),
                                      purple.withAlpha((0.38 * 255).toInt()),
                                    ],
                                  ),
                                ),
                                child: const Icon(
                                  Icons.flag_outlined,
                                  size: 20,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Report question',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: widget.onCancel,
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Explain the issue with Question ${widget.questionIndex}:',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _ctrl,
                        focusNode: _focus,
                        maxLines: 8,
                        minLines: 6,
                        maxLength: widget.maxChars,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: 'Type your report here…',
                          filled: true,
                          fillColor: Colors.white.withAlpha(
                            (0.7 * 255).toInt(),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: Colors.black12.withAlpha(
                                (0.08 * 255).toInt(),
                              ),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: purple,
                              width: 2,
                            ),
                          ),
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(
                                (0.06 * 255).toInt(),
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$_remaining left',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                minHeight: 6,
                                value:
                                    (widget.maxChars - _remaining) /
                                    widget.maxChars,
                                backgroundColor: Colors.black.withAlpha(
                                  (0.05 * 255).toInt(),
                                ),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  purple,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: widget.onCancel,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.black87,
                            ),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: _canSend
                                ? () => widget.onSend(_ctrl.text.trim())
                                : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: purple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Send',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
