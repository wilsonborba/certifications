import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/quiz.dart';
import 'package:certifications/domain/services/quiz_api_service.dart';
import 'package:certifications/presentation/components/certificates/quiz_master_detail_list.dart';
import 'package:certifications/presentation/components/premium_hover_card.dart';
import 'package:flutter/material.dart';

/// Dashboard card containing a small, scrollable master/detail list of the
/// user's completed quizzes/certificates: selecting one updates a detail
/// panel in the same card, no navigation. Part of the dashboard's expandable
/// section (see [CertificateMiniListCard]'s caller), so it only mounts (and
/// only then fetches data) once expanded.
class CertificateMiniListCard extends StatefulWidget {
  const CertificateMiniListCard({super.key, required this.isDesktop});

  final bool isDesktop;

  @override
  State<CertificateMiniListCard> createState() => _CertificateMiniListCardState();
}

class _CertificateMiniListCardState extends State<CertificateMiniListCard> {
  late final Future<List<Quiz>> _future = QuizApiService().listCompleted();

  @override
  Widget build(BuildContext context) {
    return PremiumHoverCard(
      child: FutureBuilder<List<Quiz>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final quizzes = snapshot.data ?? const [];
          return QuizMasterDetailList(
            quizzes: quizzes,
            detailBuilder: buildQuizStatDetail,
            emptyIcon: Icons.workspace_premium_outlined,
            emptyMessage: context.tr('noCompletedQuizzesYet'),
            isDesktop: widget.isDesktop,
            maxListHeight: widget.isDesktop ? 280 : 220,
          );
        },
      ),
    );
  }
}
