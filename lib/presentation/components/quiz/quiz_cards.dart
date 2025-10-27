// widgets/quiz/question_card.dart
import 'package:accredit/core/utils/my_logs.dart';
import 'package:accredit/domain/models/quiz.dart';
import 'package:flutter/material.dart';

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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: difficultyColor.withAlpha((.12 * 255).toInt()),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: difficultyColor.withAlpha((.5 * 255).toInt())),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6),
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



Future<void> showComplaintDialog(
  BuildContext context, {
  required int questionIndex,
  int maxChars = 600,
}) async {
  final ctrl = TextEditingController();
  int remaining = maxChars;

  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (_) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          final canSend = ctrl.text.trim().isNotEmpty;
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Report question',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close),
                        )
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Explain the issue with Question $questionIndex:',
                      style: const TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: ctrl,
                      maxLines: 8,
                      minLines: 6,
                      maxLength: maxChars,
                      onChanged: (v) =>
                          setState(() => remaining = maxChars - v.characters.length),
                      decoration: InputDecoration(
                        hintText: 'Type your report here…',
                        filled: true,
                        fillColor: const Color(0xFFF3F3F3),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF7C4DFF), // your purple when clicked
                            width: 2,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '$remaining left',
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C4DFF),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: canSend
                              ? () {
                                  debug('Complaint for Q$questionIndex: ${ctrl.text}');
                                  Navigator.pop(ctx);
                                }
                              : null,
                          child: const Text('Send'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
