import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/study.dart';
import 'package:certifications/domain/services/draft_progress_store.dart';
import 'package:certifications/domain/services/study_api_service.dart';
import 'package:certifications/presentation/components/attachment/app_bar.dart';
import 'package:certifications/presentation/components/dashboard/completed_metrics_banner.dart';
import 'package:certifications/presentation/components/dashboard/draft_resume_hero_card.dart';
import 'package:certifications/presentation/components/dashboard/standby_study_card.dart';
import 'package:certifications/presentation/widgets/completed_quizzes/on_completed_quizzes.dart';
import 'package:certifications/presentation/widgets/quiz_wizard/on_quiz_wizard.dart';
import 'package:flutter/material.dart';

/// Studies list paired with the most recently touched draft (if any), used
/// to power the resume hero card without a second round trip.
class _DashboardData {
  _DashboardData(this.studies, this.mostRecentDraft);
  final List<Study> studies;
  final Study? mostRecentDraft;
}

class OnStudyDashboardScreen extends StatefulWidget {
  const OnStudyDashboardScreen({super.key});

  @override
  State<OnStudyDashboardScreen> createState() => _OnStudyDashboardScreenState();
}

class _OnStudyDashboardScreenState extends State<OnStudyDashboardScreen> {
  final api = StudyApiService();
  late Future<_DashboardData> future = _load();

  Future<_DashboardData> _load() async {
    final studies = await api.list();
    final standby = studies.where((s) => s.status != 'completed').toList();

    Study? mostRecent;
    DateTime? mostRecentAt;
    for (final study in standby) {
      final touchedAt = await DraftProgressStore.instance.getLastOpenedAt(study.id);
      if (touchedAt != null && (mostRecentAt == null || touchedAt.isAfter(mostRecentAt))) {
        mostRecent = study;
        mostRecentAt = touchedAt;
      }
    }
    // No locally recorded activity yet for any draft: fall back to the last
    // entry returned by the API as a reasonable "most recent" proxy.
    mostRecent ??= standby.isNotEmpty ? standby.last : null;

    return _DashboardData(studies, mostRecent);
  }

  void _reload() {
    setState(() {
      future = _load();
    });
  }

  Future<void> _resumeStudy(Study study) async {
    final savedStep = await DraftProgressStore.instance.getStep(study.id) ?? 0;
    await DraftProgressStore.instance.touch(study.id);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OnQuizWizardScreen(
          studyId: study.id,
          initialName: study.name,
          initialStep: savedStep,
          onGenerate: () {
            Navigator.pop(context);
            _reload();
          },
        ),
      ),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 768;

    return Scaffold(
      appBar: AttachmentAppBar(title: context.tr('myStudiesTitle')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OnQuizWizardScreen(
                onGenerate: () {
                  Navigator.pop(context);
                  _reload();
                },
              ),
            ),
          );
          _reload();
        },
        icon: const Icon(Icons.add),
        label: Text(context.tr('newStudy')),
      ),
      body: SafeArea(
        child: FutureBuilder<_DashboardData>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data;
            final studies = data?.studies ?? [];
            final standby = studies.where((s) => s.status != 'completed').toList();
            final totalBytes = studies.fold<int>(0, (sum, s) => sum + s.activeSizeBytes);

            return SingleChildScrollView(
              padding: EdgeInsets.all(isDesktop ? 24 : 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        context.tr('myStudiesTitle'),
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr('myStudiesSubtitle'),
                        style: Theme.of(context).textTheme.bodyLarge
                            ?.copyWith(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: .72),
                            ),
                      ),
                      const SizedBox(height: 24),
                      CompletedMetricsBanner(
                        totalStudies: studies.length,
                        totalSizeBytes: totalBytes,
                        completedQuizzesCount: studies.where((s) => s.status == 'completed').length,
                        // No client-side source of the user's own quiz scores
                        // exists yet (QuizResult is transient, never persisted
                        // or fetched back, and the completed-quiz contract
                        // carries no per-user score field), so this is a
                        // real 0.0 rather than a placeholder constant.
                        averageScorePercent: 0.0,
                        isDesktop: isDesktop,
                        onTapCompletedQuizzes: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OnCompletedQuizzesScreen(),
                          ),
                        ),
                      ),
                      if (data?.mostRecentDraft != null) ...[
                        const SizedBox(height: 20),
                        DraftResumeHeroCard(
                          study: data!.mostRecentDraft!,
                          isDesktop: isDesktop,
                          onResume: () => _resumeStudy(data.mostRecentDraft!),
                        ),
                      ],
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          Icon(Icons.hourglass_top, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            context.tr('standbyStudies'),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (standby.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                const Icon(Icons.auto_stories, size: 48, color: Colors.grey),
                                const SizedBox(height: 12),
                                Text(context.tr('noStudies')),
                              ],
                            ),
                          ),
                        )
                      else if (isDesktop)
                        _StandbyGrid(
                          studies: standby,
                          onReload: _reload,
                          onResume: _resumeStudy,
                        )
                      else
                        Column(
                          children: standby
                              .map(
                                (study) => StandbyStudyCard(
                                  study: study,
                                  isDesktop: false,
                                  onDeleted: _reload,
                                  onUpdated: _reload,
                                  onOpen: () => _resumeStudy(study),
                                ),
                              )
                              .toList(),
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

/// Multi-column responsive layout for the standby cards on wide screens;
/// narrow screens keep the plain single-column [Column] above.
class _StandbyGrid extends StatelessWidget {
  const _StandbyGrid({
    required this.studies,
    required this.onReload,
    required this.onResume,
  });

  final List<Study> studies;
  final VoidCallback onReload;
  final ValueChanged<Study> onResume;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1400 ? 3 : 2;
        const spacing = 16.0;
        final cardWidth = (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: studies
              .map(
                (study) => SizedBox(
                  width: cardWidth,
                  child: StandbyStudyCard(
                    study: study,
                    isDesktop: true,
                    onDeleted: onReload,
                    onUpdated: onReload,
                    onOpen: () => onResume(study),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}
