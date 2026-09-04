import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/quiz.dart';
import 'package:certifications/domain/models/study.dart';
import 'package:certifications/domain/services/draft_progress_store.dart';
import 'package:certifications/domain/services/quiz_api_service.dart';
import 'package:certifications/domain/services/study_api_service.dart';
import 'package:certifications/presentation/components/attachment/app_bar.dart';
import 'package:certifications/presentation/components/dashboard/certificate_mini_list_card.dart';
import 'package:certifications/presentation/components/dashboard/completed_metrics_banner.dart';
import 'package:certifications/presentation/components/dashboard/draft_resume_hero_card.dart';
import 'package:certifications/presentation/components/dashboard/standby_study_card.dart';
import 'package:certifications/presentation/components/search/live_search_field.dart';
import 'package:certifications/presentation/widgets/completed_quizzes/on_completed_quizzes.dart';
import 'package:certifications/presentation/widgets/quiz_wizard/on_quiz_wizard.dart';
import 'package:flutter/material.dart';

/// Studies list paired with completed quizzes and the most recently touched draft (if any),
/// used to power the resume hero card and metrics accurately.
class _DashboardData {
  _DashboardData(this.studies, this.completedQuizzes, this.mostRecentDraft);
  final List<Study> studies;
  final List<Quiz> completedQuizzes;
  final Study? mostRecentDraft;
}

class OnStudyDashboardScreen extends StatefulWidget {
  const OnStudyDashboardScreen({super.key});

  @override
  State<OnStudyDashboardScreen> createState() => _OnStudyDashboardScreenState();
}

class _OnStudyDashboardScreenState extends State<OnStudyDashboardScreen> {
  final api = StudyApiService();
  final quizApi = QuizApiService();
  late Future<_DashboardData> future = _load();

  String _searchQuery = '';
  bool _selectionMode = false;
  final Set<String> _selectedIds = {};
  bool _bulkDeleting = false;
  bool _dashboardExpanded = true;

  Future<_DashboardData> _load() async {
    final results = await Future.wait([
      api.list(),
      quizApi.listCompleted().catchError((_) => <Quiz>[]),
    ]);
    final studies = results[0] as List<Study>;
    final completedQuizzes = results[1] as List<Quiz>;
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

    return _DashboardData(studies, completedQuizzes, mostRecent);
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
          onGenerate: _reload,
        ),
      ),
    );
    _reload();
  }

  void _enterSelectionMode(String initialId) {
    setState(() {
      _selectionMode = true;
      _selectedIds
        ..clear()
        ..add(initialId);
    });
  }

  void _toggleSelected(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
      if (_selectedIds.isEmpty) _selectionMode = false;
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _deleteSelected() async {
    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('delete')),
        content: Text(context.trParams('deleteSelectedConfirm', {'count': '$count'})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('close')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _bulkDeleting = true);
    final ids = _selectedIds.toList();
    for (final id in ids) {
      try {
        await api.delete(id);
      } catch (_) {
        // Best-effort: keep deleting the rest even if one fails.
      }
    }
    if (!mounted) return;
    setState(() {
      _bulkDeleting = false;
      _selectionMode = false;
      _selectedIds.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('studyDeletedSuccess'))),
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 768;

    return Scaffold(
      appBar: AttachmentAppBar(title: context.tr('myStudiesTitle'), currentTab: 'studies'),
      endDrawer: const AttachmentSideMenu(currentTab: 'studies'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OnQuizWizardScreen(
                onGenerate: _reload,
              ),
            ),
          );
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
            final allStandby = studies.where((s) => s.status != 'completed').toList();
            final standby = _searchQuery.isEmpty
                ? allStandby
                : allStandby
                      .where((s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                      .toList();
            final totalBytes = studies.fold<int>(0, (sum, s) => sum + s.activeSizeBytes);
            final completedCount = data?.completedQuizzes.length ??
                studies.where((s) => s.status == 'completed').length;

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
                        standbyCount: allStandby.length,
                        totalSizeBytes: totalBytes,
                        completedQuizzesCount: completedCount,
                        activityDates: [
                          ...studies
                              .map((study) => study.createdAt == null
                                  ? null
                                  : DateTime.tryParse(study.createdAt!))
                              .whereType<DateTime>(),
                          ...(data?.completedQuizzes ?? [])
                              .map((quiz) => quiz.createdAt.isEmpty
                                  ? null
                                  : DateTime.tryParse(quiz.createdAt))
                              .whereType<DateTime>(),
                        ],
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
                          Icon(Icons.workspace_premium_outlined, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            context.tr('yourCertificatesLabel'),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => setState(() => _dashboardExpanded = !_dashboardExpanded),
                            icon: Icon(_dashboardExpanded ? Icons.expand_less : Icons.expand_more),
                            label: Text(
                              _dashboardExpanded
                                  ? context.tr('collapseDashboard')
                                  : context.tr('expandDashboard'),
                            ),
                          ),
                        ],
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.topCenter,
                        child: _dashboardExpanded
                            ? Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: CertificateMiniListCard(isDesktop: isDesktop),
                              )
                            : const SizedBox(width: double.infinity),
                      ),
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
                          const Spacer(),
                          if (allStandby.isNotEmpty)
                            TextButton.icon(
                              onPressed: _selectionMode
                                  ? _exitSelectionMode
                                  : () => setState(() => _selectionMode = true),
                              icon: Icon(_selectionMode ? Icons.close : Icons.checklist),
                              label: Text(
                                _selectionMode
                                    ? context.tr('cancel')
                                    : context.tr('selectStudiesAction'),
                              ),
                            ),
                        ],
                      ),
                      if (allStandby.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        LiveSearchField(
                          hintText: context.tr('searchStudiesHint'),
                          onChanged: (value) => setState(() => _searchQuery = value),
                        ),
                      ],
                      if (_selectionMode) ...[
                        const SizedBox(height: 12),
                        _SelectionActionBar(
                          count: _selectedIds.length,
                          busy: _bulkDeleting,
                          onDeleteAll: _selectedIds.isEmpty ? null : _deleteSelected,
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (allStandby.isEmpty)
                        _StandbyEmptyState(isDesktop: isDesktop)
                      else if (standby.isEmpty)
                        _NoSearchResultsState(query: _searchQuery)
                      else if (isDesktop)
                        _StandbyGrid(
                          studies: standby,
                          onReload: _reload,
                          onResume: _resumeStudy,
                          selectionMode: _selectionMode,
                          selectedIds: _selectedIds,
                          onToggleSelected: _toggleSelected,
                          onEnterSelectionMode: _enterSelectionMode,
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
                                  selectionMode: _selectionMode,
                                  selected: _selectedIds.contains(study.id),
                                  onToggleSelected: () => _toggleSelected(study.id),
                                  onEnterSelectionMode: () => _enterSelectionMode(study.id),
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

/// Bar shown while bulk-selecting standby studies: how many are selected,
/// plus the delete-all action.
class _SelectionActionBar extends StatelessWidget {
  const _SelectionActionBar({
    required this.count,
    required this.busy,
    required this.onDeleteAll,
  });

  final int count;
  final bool busy;
  final VoidCallback? onDeleteAll;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Text(
            context.trParams('selectedCountLabel', {'count': '$count'}),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: busy ? null : onDeleteAll,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            icon: busy
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.delete_outline, size: 18),
            label: Text(context.tr('deleteSelectedAction')),
          ),
        ],
      ),
    );
  }
}

/// Real empty state (icon + message) for the standby list, shown instead of
/// a blank area when the user has no draft studies at all.
class _StandbyEmptyState extends StatelessWidget {
  const _StandbyEmptyState({required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: isDesktop ? 48 : 32, horizontal: 24),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.auto_stories_outlined, size: 48, color: scheme.onSurface.withValues(alpha: 0.35)),
          const SizedBox(height: 14),
          Text(
            context.tr('noStudies'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            context.tr('noStudiesSubtitle'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown when a search query matches none of the standby studies.
class _NoSearchResultsState extends StatelessWidget {
  const _NoSearchResultsState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 40, color: scheme.onSurface.withValues(alpha: 0.35)),
          const SizedBox(height: 10),
          Text(
            context.trParams('noSearchResultsLabel', {'query': query}),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
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
    required this.selectionMode,
    required this.selectedIds,
    required this.onToggleSelected,
    required this.onEnterSelectionMode,
  });

  final List<Study> studies;
  final VoidCallback onReload;
  final ValueChanged<Study> onResume;
  final bool selectionMode;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggleSelected;
  final ValueChanged<String> onEnterSelectionMode;

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
                    selectionMode: selectionMode,
                    selected: selectedIds.contains(study.id),
                    onToggleSelected: () => onToggleSelected(study.id),
                    onEnterSelectionMode: () => onEnterSelectionMode(study.id),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}
