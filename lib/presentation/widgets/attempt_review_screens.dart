import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/attempt_review.dart';
import 'package:certifications/domain/services/attempt_review_api_service.dart';
import 'package:certifications/domain/models/public_quiz_statistics.dart';
import 'package:certifications/domain/services/public_quiz_statistics_api_service.dart';
import 'package:certifications/presentation/components/attachment/app_bar.dart';
import 'package:certifications/domain/services/certificate_verification_api_service.dart';
import 'package:certifications/presentation/components/certificates/certificate_issue_card.dart';
import 'package:flutter/material.dart';
import 'package:reports_view/reports_view.dart';

class AttemptHistoryScreen extends StatefulWidget {
  const AttemptHistoryScreen({this.api, super.key});
  final AttemptReviewApiService? api;
  @override
  State<AttemptHistoryScreen> createState() => _AttemptHistoryScreenState();
}

class _AttemptHistoryScreenState extends State<AttemptHistoryScreen> {
  late final _api = widget.api ?? AttemptReviewApiService();
  final _search = TextEditingController();
  final _quiz = TextEditingController();
  final _tag = TextEditingController();
  static const _pageSize = 20;
  int _offset = 0;
  DateTime? _startedFrom;
  DateTime? _startedTo;
  bool _invalidDateRange = false;
  late Future<AttemptHistoryPage> _future = _load();

  Future<AttemptHistoryPage> _load() => _api.listAttempts(
    AttemptHistoryQuery(
      q: _search.text.trim().isEmpty ? null : _search.text.trim(),
      quizId: _quiz.text.trim().isEmpty ? null : _quiz.text.trim(),
      tag: _tag.text.trim().isEmpty ? null : _tag.text.trim(),
      startedFrom: AttemptHistoryQuery.startOfLocalDateSeconds(_startedFrom),
      startedTo: AttemptHistoryQuery.endOfLocalDateSeconds(_startedTo),
      limit: _pageSize,
      offset: _offset,
    ),
  );

  void _apply() {
    if (_startedFrom != null &&
        _startedTo != null &&
        DateTime(
          _startedFrom!.year,
          _startedFrom!.month,
          _startedFrom!.day,
        ).isAfter(
          DateTime(_startedTo!.year, _startedTo!.month, _startedTo!.day),
        )) {
      setState(() => _invalidDateRange = true);
      return;
    }
    setState(() {
      _invalidDateRange = false;
      _offset = 0;
      _future = _load();
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final current = isStart ? _startedFrom : _startedTo;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _startedFrom = picked;
      } else {
        _startedTo = picked;
      }
      _invalidDateRange = false;
    });
  }

  void _move(int delta) => setState(() {
    _offset = (_offset + delta * _pageSize).clamp(0, 1 << 30);
    _future = _load();
  });

  @override
  void dispose() {
    _search.dispose();
    _quiz.dispose();
    _tag.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AttachmentAppBar(
      title: context.tr('attemptHistory'),
      currentTab: 'history',
    ),
    endDrawer: const AttachmentSideMenu(),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _search,
                        decoration: InputDecoration(
                          labelText: context.tr('searchHistory'),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: TextField(
                        controller: _quiz,
                        decoration: InputDecoration(
                          labelText: context.tr('quizIdFilter'),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 150,
                      child: TextField(
                        controller: _tag,
                        decoration: InputDecoration(
                          labelText: context.tr('tagFilter'),
                        ),
                      ),
                    ),
                    _HistoryDateFilter(
                      label: context.tr('historyFrom'),
                      value: _startedFrom,
                      onPick: () => _pickDate(isStart: true),
                      onClear: () => setState(() {
                        _startedFrom = null;
                        _invalidDateRange = false;
                      }),
                    ),
                    _HistoryDateFilter(
                      label: context.tr('historyThrough'),
                      value: _startedTo,
                      onPick: () => _pickDate(isStart: false),
                      onClear: () => setState(() {
                        _startedTo = null;
                        _invalidDateRange = false;
                      }),
                    ),
                    FilledButton(
                      onPressed: _apply,
                      child: Text(context.tr('applyFilters')),
                    ),
                  ],
                ),
                if (_invalidDateRange)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(context.tr('invalidDateRange')),
                    ),
                  ),
                const SizedBox(height: 16),
                Expanded(
                  child: FutureBuilder<AttemptHistoryPage>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(context.tr('errorGeneric')),
                              TextButton(
                                onPressed: () => setState(() {
                                  _future = _load();
                                }),
                                child: Text(context.tr('retry')),
                              ),
                            ],
                          ),
                        );
                      }
                      final page = snapshot.data!;
                      if (page.items.isEmpty) {
                        return Center(child: Text(context.tr('noAttempts')));
                      }
                      return Column(
                        children: [
                          Expanded(
                            child: ListView.separated(
                              itemCount: page.items.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) =>
                                  _HistoryRow(item: page.items[index]),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: _offset == 0
                                    ? null
                                    : () => _move(-1),
                                child: Text(context.tr('previousPage')),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  '${page.offset + 1}–${page.offset + page.items.length} / ${page.total}',
                                ),
                              ),
                              TextButton(
                                onPressed:
                                    page.offset + page.items.length >=
                                        page.total
                                    ? null
                                    : () => _move(1),
                                child: Text(context.tr('nextPage')),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _HistoryDateFilter extends StatelessWidget {
  const _HistoryDateFilter({
    required this.label,
    required this.value,
    required this.onPick,
    required this.onClear,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final dateLabel = value == null
        ? context.tr('chooseDate')
        : MaterialLocalizations.of(context).formatMediumDate(value!);
    return SizedBox(
      width: 220,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(dateLabel, overflow: TextOverflow.ellipsis),
              ),
            ),
            if (value != null)
              IconButton(
                tooltip: context.tr('clearDate'),
                onPressed: onClear,
                icon: const Icon(Icons.clear),
              ),
          ],
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.item});
  final AttemptHistoryItem item;
  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(item.quizTitle),
    subtitle: Text(
      '${DateTime.fromMillisecondsSinceEpoch(item.startedAt * 1000).toLocal()} · ${_localizedStatus(context, item.status)}',
    ),
    trailing: Text(
      item.scorePct == null
          ? context.tr('unavailable')
          : '${item.scorePct!.toStringAsFixed(1)}%',
    ),
    onTap: item.status == 'completed'
        ? () => Navigator.of(
            context,
          ).pushNamed('/v1/attempts/${Uri.encodeComponent(item.id)}/results')
        : null,
  );

  String _localizedStatus(BuildContext context, String status) =>
      switch (status) {
        'completed' => context.tr('attemptCompleted'),
        'in_progress' => context.tr('attemptInProgress'),
        _ => status,
      };
}

class AttemptResultsScreen extends StatefulWidget {
  const AttemptResultsScreen({
    required this.attemptId,
    this.api,
    this.certificateService,
    super.key,
  });
  final String attemptId;
  final AttemptReviewApiService? api;
  final CertificateVerificationApiService? certificateService;
  @override
  State<AttemptResultsScreen> createState() => _AttemptResultsScreenState();
}

class _AttemptResultsScreenState extends State<AttemptResultsScreen> {
  late Future<AttemptResults> _future = _load();

  Future<AttemptResults> _load() =>
      (widget.api ?? AttemptReviewApiService()).getResults(widget.attemptId);
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AttachmentAppBar(title: context.tr('resultsReview')),
    endDrawer: const AttachmentSideMenu(),
    body: FutureBuilder<AttemptResults>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.tr('errorGeneric')),
                TextButton(
                  onPressed: () => setState(() => _future = _load()),
                  child: Text(context.tr('retry')),
                ),
              ],
            ),
          );
        }
        final result = snapshot.data!;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  result.scorePct == null
                      ? context.tr('unavailable')
                      : '${result.scorePct!.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text('${result.scoreCorrect} / ${result.scoreTotal}'),
                if (result.status == 'completed') ...[
                  const SizedBox(height: 16),
                  CertificateIssueCard(
                    attemptId: widget.attemptId,
                    service: widget.certificateService,
                  ),
                ],
                _ResultStats(values: result.stats),
                const SizedBox(height: 20),
                for (var i = 0; i < result.questions.length; i++)
                  _ResultQuestion(index: i + 1, question: result.questions[i]),
                const SizedBox(height: 16),
                _ActivitySummary(values: result.activitySummary),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _ResultQuestion extends StatelessWidget {
  const _ResultQuestion({required this.index, required this.question});
  final int index;
  final AttemptResultQuestion question;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$index. ${question.prompt}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          for (final option in question.alternatives)
            _OptionLine(option: option, question: question),
          if (question.explanation?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(question.explanation!),
          ],
          if (question.citationRef?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            SelectableText(question.citationRef!),
          ],
        ],
      ),
    ),
  );
}

class _OptionLine extends StatelessWidget {
  const _OptionLine({required this.option, required this.question});
  final dynamic option;
  final AttemptResultQuestion question;
  @override
  Widget build(BuildContext context) {
    final map = option is Map<String, dynamic>
        ? option as Map<String, dynamic>
        : const <String, dynamic>{};
    final id = (map['id'] ?? map['option_id'])?.toString();
    final label = (map['text'] ?? map['label'] ?? map['content'] ?? '')
        .toString();
    final selected = id != null && id == question.selectedOptionId;
    final correct = id != null && id == question.correctId;
    final tags = [
      if (selected) context.tr('yourAnswer'),
      if (correct) context.tr('answerKey'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text('$label${tags.isEmpty ? '' : ' · ${tags.join(' · ')}'}'),
    );
  }
}

class _ActivitySummary extends StatelessWidget {
  const _ActivitySummary({required this.values});
  final Map<String, dynamic> values;
  @override
  Widget build(BuildContext context) => ExpansionTile(
    title: Text(context.tr('attemptActivity')),
    subtitle: Text(
      '${values['completeness'] ?? context.tr('unavailable')} · ${values['disclaimer'] ?? ''}',
    ),
    children: [
      for (final key in [
        'focus_lost_count',
        'page_hidden_count',
        'page_return_count',
        'known_away_ms',
        'reconnect_count',
        'refresh_count',
        'unknown_gap_count',
      ])
        ListTile(
          title: Text(key.replaceAll('_', ' ')),
          trailing: Text('${values[key] ?? context.tr('unavailable')}'),
        ),
    ],
  );
}

class _ResultStats extends StatelessWidget {
  const _ResultStats({required this.values});
  final Map<String, dynamic> values;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final group in [
        'generated_with_cortex',
        'supplied_by_creator',
        'overall',
      ])
        if (values[group] is Map<String, dynamic>)
          Builder(
            builder: (context) {
              final item = values[group] as Map<String, dynamic>;
              final pct = item['percentage'];
              final denominator = (item['total'] as num?)?.toInt() ?? 0;
              return _Metric(
                label: context.tr(switch (group) {
                  'generated_with_cortex' => 'generatedQuestions',
                  'supplied_by_creator' => 'creatorQuestions',
                  _ => 'overallQuestions',
                }),
                value: denominator == 0 || pct == null
                    ? context.tr('noScoreSample')
                    : '${(pct as num).toStringAsFixed(1)}% · ${item['correct']} / $denominator',
              );
            },
          ),
    ],
  );
}

class AttemptDashboardScreen extends StatefulWidget {
  const AttemptDashboardScreen({super.key});
  @override
  State<AttemptDashboardScreen> createState() => _AttemptDashboardScreenState();
}

class _AttemptDashboardScreenState extends State<AttemptDashboardScreen> {
  late final Future<AttemptOverview> _future = AttemptReviewApiService()
      .getOverview();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AttachmentAppBar(
      title: context.tr('reviewDashboard'),
      currentTab: 'dashboard',
    ),
    endDrawer: const AttachmentSideMenu(),
    body: FutureBuilder<AttemptOverview>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(context.tr('errorGeneric')));
        }
        final v = snapshot.data!;
        final provenance = v.questionProvenance;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _Metric(
                  label: context.tr('createdQuizzes'),
                  value: '${v.createdQuizCount}',
                ),
                _Metric(
                  label: context.tr('completedAttempts'),
                  value: '${v.completedAttemptCount}',
                ),
                _Metric(
                  label: context.tr('distinctQuizzesAttempted'),
                  value: '${v.distinctQuizzesAttempted}',
                ),
                _Metric(
                  label: context.tr('averageScore'),
                  value: _mean(
                    v.allAttemptMeanScorePct,
                    v.allAttemptScoreDenominator,
                    context,
                  ),
                ),
                _Metric(
                  label: context.tr('latestQuizAverage'),
                  value: _mean(
                    v.latestAttemptPerQuizMeanScorePct,
                    v.latestAttemptPerQuizScoreDenominator,
                    context,
                  ),
                ),
                _Metric(
                  label: context.tr('averageCompletionTime'),
                  value:
                      v.completionTimeDenominator == 0 ||
                          v.averageCompletionTimeSeconds == null
                      ? context.tr('unavailable')
                      : '${v.averageCompletionTimeSeconds!.toStringAsFixed(1)} s · n=${v.completionTimeDenominator}',
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr('questionProvenance'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                for (final key in [
                  'generated_from_current_selected_sources',
                  'reused_public_question_version',
                  'unclassified',
                  'combined',
                ])
                  _ProvenanceRow(
                    name: key,
                    values:
                        provenance[key] as Map<String, dynamic>? ?? const {},
                  ),
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/v1/history'),
                  child: Text(context.tr('attemptHistory')),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );

  String _mean(double? value, int denominator, BuildContext context) =>
      denominator == 0 || value == null
      ? context.tr('noScoreSample')
      : '${(value as num).toStringAsFixed(1)}% · n=$denominator';
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      title: Text(label),
      trailing: Text(value, textAlign: TextAlign.end),
    ),
  );
}

class _ProvenanceRow extends StatelessWidget {
  const _ProvenanceRow({required this.name, required this.values});
  final String name;
  final Map<String, dynamic> values;
  @override
  Widget build(BuildContext context) {
    final labelKey = switch (name) {
      'generated_from_current_selected_sources' => 'provenanceGenerated',
      'reused_public_question_version' => 'provenanceReused',
      'unclassified' => 'provenanceUnclassified',
      'combined' => 'provenanceCombined',
      _ => name,
    };
    final n = (values['question_count'] as num?)?.toInt() ?? 0;
    final correct = (values['correct_question_count'] as num?)?.toInt() ?? 0;
    final pct = values['correct_percentage'];
    return ListTile(
      title: Text(context.tr(labelKey)),
      subtitle: Text(n == 0 ? context.tr('emptyGroup') : '$correct / $n'),
      trailing: Text(
        n == 0 || pct == null
            ? context.tr('unavailable')
            : '${(pct as num).toStringAsFixed(1)}%',
      ),
    );
  }
}

class PublicQuizStatisticsScreen extends StatefulWidget {
  const PublicQuizStatisticsScreen({required this.quizId, this.api, super.key});
  final String quizId;
  final PublicQuizStatisticsApiService? api;
  @override
  State<PublicQuizStatisticsScreen> createState() =>
      _PublicQuizStatisticsScreenState();
}

class _PublicQuizStatisticsScreenState
    extends State<PublicQuizStatisticsScreen> {
  late final PublicQuizStatisticsApiService _api =
      widget.api ?? PublicQuizStatisticsApiService();
  String? _loadedLanguage;
  Future<PublicQuizStatistics>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = Localizations.localeOf(context).languageCode;
    if (_loadedLanguage != language) {
      _loadedLanguage = language;
      _future = _api.getForQuiz(widget.quizId, language: language);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AttachmentAppBar(title: context.tr('scoreDistribution')),
    body: FutureBuilder<PublicQuizStatistics>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(context.tr('errorGeneric')));
        }
        final data = snapshot.data!;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _Metric(
                  label: context.tr('completedAttempts'),
                  value: '${data.completedAttemptCount}',
                ),
                _Metric(
                  label: context.tr('distinctParticipants'),
                  value: '${data.distinctParticipants}',
                ),
                _Metric(
                  label: context.tr('averageScore'),
                  value:
                      data.averageScoreDenominator == 0 ||
                          data.averageScorePct == null
                      ? context.tr('noScoreSample')
                      : '${data.averageScorePct!.toStringAsFixed(1)}% · n=${data.averageScoreDenominator}',
                ),
                _Metric(
                  label: context.tr('averageDuration'),
                  value:
                      data.durationDenominator == 0 ||
                          data.typicalDurationSec == null
                      ? context.tr('unavailable')
                      : '${data.typicalDurationSec} s · n=${data.durationDenominator}',
                ),
                Text(
                  context.tr('scoreDistribution'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (data.scoreDistributionDenominator == 0)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(context.tr('noScoreSample')),
                  )
                else ...[
                  if (data.scoreDistributionView case final reportView?)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: VisualChooser.buildTemplate(
                        page: reportView.page,
                        template: reportView.template,
                        binding: reportView.binding,
                        title: reportView.template.title,
                        mode: ChartFrameMode.embed,
                        height: 320,
                        showAxisTitles: true,
                      ),
                    ),
                  _ScoreDistributionTable(bands: data.scoreDistribution),
                  Text('n=${data.scoreDistributionDenominator}'),
                ],
                const SizedBox(height: 16),
                Text(
                  context.tr('questionProvenance'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                for (final key in [
                  'generated_from_current_selected_sources',
                  'reused_public_question_version',
                  'unclassified',
                  'combined',
                ])
                  _ProvenanceRow(
                    name: key,
                    values:
                        data.questionProvenance[key] as Map<String, dynamic>? ??
                        const {},
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _ScoreDistributionTable extends StatelessWidget {
  const _ScoreDistributionTable({required this.bands});

  final List<ScoreDistributionBand> bands;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            DataColumn(label: Text(context.tr('scoreBand'))),
            DataColumn(label: Text(context.tr('attemptCount')), numeric: true),
          ],
          rows: [
            for (final band in bands)
              DataRow(
                cells: [
                  DataCell(Text(band.label)),
                  DataCell(Text('${band.count}')),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
