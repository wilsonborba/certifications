import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/quiz.dart';
import 'package:certifications/domain/services/quiz_api_service.dart';
import 'package:certifications/presentation/components/attachment/app_bar.dart';
import 'package:certifications/presentation/components/certificates/quiz_master_detail_list.dart';
import 'package:certifications/presentation/components/quiz/quiz_leaderboard_view.dart';
import 'package:certifications/presentation/components/quiz/quiz_share_modal.dart';
import 'package:certifications/presentation/components/search/live_search_field.dart';
import 'package:flutter/material.dart';

/// The Certificates tab, rebuilt on the real (backed by a live database)
/// completed-quizzes contract: no more direct deep link with a single id
/// and nothing to browse from, dead scaffolding, or unreachable screen.
///
/// Public/Private is an in-body sub-tab switcher (a TabBar in the body, not
/// another app bar item), each reusing the bespoke master/detail list built
/// for the dashboard (#37) so a certificate's detail (or, for Public, its
/// leaderboard) shows inline with no extra navigation.
class OnCertificatesScreen extends StatefulWidget {
  const OnCertificatesScreen({super.key});

  @override
  State<OnCertificatesScreen> createState() => _OnCertificatesScreenState();
}

class _OnCertificatesScreenState extends State<OnCertificatesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this);
  final _quizApi = QuizApiService();
  late final Future<List<Quiz>> _future = _quizApi.listCompleted();
  String _searchQuery = '';

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Quiz> _filter(List<Quiz> quizzes) {
    if (_searchQuery.isEmpty) return quizzes;
    final query = _searchQuery.toLowerCase();
    return quizzes.where((q) => q.title.toLowerCase().contains(query)).toList();
  }

  void _openShareModal(BuildContext context, Quiz quiz) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => QuizShareModal(
        quizId: quiz.id,
        quizTitle: quiz.title.isEmpty ? quiz.id : quiz.title,
      ),
    );
  }

  Widget _buildPrivateDetail(BuildContext context, Quiz quiz) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        buildQuizStatDetail(context, quiz),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _openShareModal(context, quiz),
          icon: const Icon(Icons.share_outlined, size: 18),
          label: Text(context.tr('shareAction')),
        ),
      ],
    );
  }

  Widget _buildPublicDetail(BuildContext context, Quiz quiz, bool isDesktop) {
    final scheme = Theme.of(context).colorScheme;
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
          Row(
            children: [
              Expanded(
                child: Text(
                  quiz.title.isEmpty ? quiz.id : quiz.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(Icons.emoji_events_outlined, color: scheme.primary, size: 20),
            ],
          ),
          const SizedBox(height: 14),
          QuizLeaderboardScreen(
            quizId: quiz.id,
            quizTitle: quiz.title,
            isDesktop: isDesktop,
            embedded: true,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 768;

    return Scaffold(
      appBar: AttachmentAppBar(
        title: context.tr('certificates'),
        currentTab: 'certificates',
      ),
      endDrawer: const AttachmentSideMenu(currentTab: 'certificates'),
      body: SafeArea(
        child: FutureBuilder<List<Quiz>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text(context.tr('errorGeneric')));
            }

            final all = snapshot.data ?? const [];
            final privateQuizzes = _filter(
              all.where((q) => q.visibility == QuizVisibility.private).toList(),
            );
            final publicQuizzes = _filter(
              all.where((q) => q.visibility == QuizVisibility.public).toList(),
            );

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: EdgeInsets.all(isDesktop ? 24 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        context.tr('certificates'),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr('certificatesSubtitle'),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.72),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          indicator: BoxDecoration(
                            color: scheme.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          labelColor: scheme.onPrimary,
                          unselectedLabelColor: scheme.onSurface.withValues(alpha: 0.7),
                          tabs: [
                            Tab(
                              icon: const Icon(Icons.lock_outline, size: 18),
                              text: context.tr('visibilityPrivate'),
                            ),
                            Tab(
                              icon: const Icon(Icons.public, size: 18),
                              text: context.tr('visibilityPublic'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      LiveSearchField(
                        hintText: context.tr('searchCertificatesHint'),
                        onChanged: (value) => setState(() => _searchQuery = value),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            SingleChildScrollView(
                              child: QuizMasterDetailList(
                                quizzes: privateQuizzes,
                                detailBuilder: _buildPrivateDetail,
                                emptyIcon: Icons.lock_outline,
                                emptyMessage: context.tr('noPrivateCertificatesYet'),
                                isDesktop: isDesktop,
                              ),
                            ),
                            SingleChildScrollView(
                              child: QuizMasterDetailList(
                                quizzes: publicQuizzes,
                                detailBuilder: (context, quiz) =>
                                    _buildPublicDetail(context, quiz, isDesktop),
                                emptyIcon: Icons.public_off_outlined,
                                emptyMessage: context.tr('noPublicCertificatesYet'),
                                isDesktop: isDesktop,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
