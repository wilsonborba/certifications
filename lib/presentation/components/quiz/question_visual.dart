import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// Renders a question's optional visual (LaTeX), shared by every screen that
/// presents a question. Diagram logic has been completely removed to avoid complexity.
class QuestionVisual extends StatelessWidget {
  const QuestionVisual({super.key, required this.visual, this.diagramBytes});

  final Map<String, dynamic> visual;
  final Future<List<int>>? diagramBytes;

  @override
  Widget build(BuildContext context) {
    final kind = visual['kind'];
    if (kind == 'latex') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Semantics(
          label: visual['description'] as String?,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Math.tex(visual['source'] as String),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
