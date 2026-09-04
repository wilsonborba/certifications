import 'dart:typed_data';

import 'package:certifications/core/utils/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Renders a question's optional visual (LaTeX or a server-rendered D2
/// diagram), shared by every screen that presents a question: the study
/// wizard's [QuestionSession] and the shared-link answering flow.
///
/// Fetching (and caching across question navigation) is the caller's job:
/// pass the same [Future] back for a question the user has already viewed
/// instead of building a new one, so going back to a previous question
/// doesn't re-download its diagram.
class QuestionVisual extends StatelessWidget {
  const QuestionVisual({super.key, required this.visual, this.diagramBytes});

  final Map<String, dynamic> visual;

  /// Resolves to the rendered D2 SVG's raw bytes, when `visual['kind'] ==
  /// 'd2'`. Fetched through the same session-cookie-authenticated client the
  /// rest of the app uses - `SvgPicture.network` issues a plain,
  /// uncredentialed request that always 401s against this API.
  final Future<List<int>>? diagramBytes;

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
      final bytesFuture = diagramBytes;
      if (bytesFuture == null)
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Center(child: Text(context.tr('diagramUnavailable'))),
        );
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: SizedBox(
          height: 260,
          child: FutureBuilder<List<int>>(
            future: bytesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || snapshot.data == null) {
                return Center(child: Text(context.tr('diagramUnavailable')));
              }
              return SvgPicture.memory(
                Uint8List.fromList(snapshot.data!),
                errorBuilder: (_, __, ___) =>
                    Center(child: Text(context.tr('diagramUnavailable'))),
              );
            },
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
