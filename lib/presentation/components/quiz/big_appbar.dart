// widgets/quiz/quiz_app_bar.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class QuizAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final ValueListenable<int> remainingSecondsListenable;
  final String? subtitle; // e.g., "Quiz about Matrix"
  final double height;
  final Color background;
  final Color accent;

  const QuizAppBar({
    super.key,
    required this.title,
    required this.remainingSecondsListenable,
    this.subtitle,
    this.height = 96,
    this.background = const Color(0xFF222222),
    this.accent = const Color(0xFF7C4DFF),
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false, // no back arrow
      toolbarHeight: height,
      backgroundColor: background,
      elevation: 0,
      titleSpacing: 24,
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ValueListenableBuilder<int>(
            valueListenable: remainingSecondsListenable,
            builder: (_, secs, __) {
              final m = secs ~/ 60;
              final s = secs % 60;
              final mmss = '${m.toString()}:${s.toString().padLeft(2, '0')}';
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    mmss,
                    style: TextStyle(
                      color: accent,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
