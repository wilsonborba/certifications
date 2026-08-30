import 'package:certifications/core/utils/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Renders a question's optional visual (LaTeX or a server-rendered D2
/// diagram), shared by every screen that presents a question: the study
/// wizard's [QuestionSession] and the shared-link answering flow.
class QuestionVisual extends StatelessWidget {
  const QuestionVisual({super.key, required this.visual, this.diagramUrl});

  final Map<String, dynamic> visual;

  /// URL to fetch the rendered D2 SVG from, when `visual['kind'] == 'd2'`.
  final String? diagramUrl;

  @override
  Widget build(BuildContext context) {
    final kind = visual['kind'];
    if (kind == 'latex')
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
    if (kind == 'd2') {
      final url = diagramUrl;
      if (url == null)
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Center(child: Text(context.tr('diagramUnavailable'))),
        );
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: SizedBox(
          height: 260,
          child: SvgPicture.network(
            url,
            placeholderBuilder: (_) =>
                const Center(child: CircularProgressIndicator()),
            errorBuilder: (_, __, ___) =>
                Center(child: Text(context.tr('diagramUnavailable'))),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
