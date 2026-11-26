import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/attempt_review.dart';
import 'package:certifications/domain/services/attempt_review_api_service.dart';
import 'package:certifications/domain/models/public_quiz_statistics.dart';
import 'package:certifications/domain/services/public_quiz_statistics_api_service.dart';
import 'package:certifications/presentation/components/attachment/app_bar.dart';
import 'package:certifications/domain/services/certificate_verification_api_service.dart';
import 'package:certifications/presentation/components/certificates/certificate_issue_card.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:reports_view/reports_view.dart';

String _localizedDecimal(BuildContext context, num value) => NumberFormat(
  '0.0',
  Localizations.localeOf(context).languageCode,
).format(value);

String _localizedCount(BuildContext context, num value) =>
    NumberFormat.decimalPattern(
      Localizations.localeOf(context).languageCode,
    ).format(value);

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
                                  '${_localizedCount(context, page.offset + 1)}–${_localizedCount(context, page.offset + page.items.length)} / ${_localizedCount(context, page.total)}',
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
          : '${_localizedDecimal(context, item.scorePct!)}%',
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
                      : '${_localizedDecimal(context, result.scorePct!)}%',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  '${_localizedCount(context, result.scoreCorrect)} / ${_localizedCount(context, result.scoreTotal)}',
                ),
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

  static const _metricLabels = [
    ('focus_lost_count', 'certificateFocusLoss'),
    ('page_hidden_count', 'certificatePageHidden'),
    ('page_return_count', 'certificatePageReturns'),
    ('known_away_ms', 'certificateKnownAway'),
    ('reconnect_count', 'certificateReconnects'),
    ('refresh_count', 'certificateRefreshes'),
    ('unknown_gap_count', 'certificateUnknownGaps'),
  ];

  String _completenessLabel(BuildContext context) =>
      context.tr(switch (values['completeness']) {
        'complete_observed' => 'certificateCompletenessComplete',
        'partial_with_interruptions' => 'certificateCompletenessPartial',
        'no_events_recorded' => 'certificateCompletenessNoEvents',
        _ => 'certificateCompletenessUnknown',
      });

  String _metricValue(BuildContext context, String key) {
    final value = values[key];
    if (value is! num || !value.isFinite || value < 0 || value % 1 != 0) {
      return context.tr('unavailable');
    }
    if (key != 'known_away_ms') return _localizedCount(context, value);

    final seconds = value.toInt() ~/ 1000;
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainder = seconds % 60;
    if (hours > 0) {
      return context.trParams('generationDurationHours', {
        'hours': '$hours',
        'minutes': '$minutes',
        'seconds': '$remainder',
      });
    }
    if (minutes > 0) {
      return context.trParams('generationDurationMinutes', {
        'minutes': '$minutes',
        'seconds': '$remainder',
      });
    }
    return context.trParams('generationDurationSeconds', {
      'seconds': '$remainder',
    });
  }

  @override
  Widget build(BuildContext context) {
    final disclaimer = values['disclaimer'] ?? '';
    return ExpansionTile(
      title: Text(context.tr('attemptActivity')),
      subtitle: Text(
        '${context.tr('certificateCompleteness')}: '
        '${_completenessLabel(context)} · $disclaimer',
      ),
      children: [
        for (final (key, label) in _metricLabels)
          ListTile(
            title: Text(context.tr(label)),
            trailing: Text(_metricValue(context, key)),
          ),
      ],
    );
  }
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
              final correct = item['correct'];
              final denominator = (item['total'] as num?)?.toInt() ?? 0;
              return _Metric(
                label: context.tr(switch (group) {
                  'generated_with_cortex' => 'generatedQuestions',
                  'supplied_by_creator' => 'creatorQuestions',
                  _ => 'overallQuestions',
                }),
                value: denominator == 0 || pct == null
                    ? context.tr('noScoreSample')
                    : correct is! num
                    ? context.tr('unavailable')
                    : '${_localizedDecimal(context, pct as num)}% · ${_localizedCount(context, correct)} / ${_localizedCount(context, denominator)}',
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
                  value: _localizedCount(context, v.createdQuizCount),
                ),
                _Metric(
                  label: context.tr('completedAttempts'),
                  value: _localizedCount(context, v.completedAttemptCount),
                ),
                _Metric(
                  label: context.tr('distinctQuizzesAttempted'),
                  value: _localizedCount(context, v.distinctQuizzesAttempted),
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
                      : '${_localizedDecimal(context, v.averageCompletionTimeSeconds!)} s · n=${_localizedCount(context, v.completionTimeDenominator)}',
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
      : '${_localizedDecimal(context, value)}% · n=${_localizedCount(context, denominator)}';
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
      subtitle: Text(
        n == 0
            ? context.tr('emptyGroup')
            : '${_localizedCount(context, correct)} / ${_localizedCount(context, n)}',
      ),
      trailing: Text(
        n == 0 || pct == null
            ? context.tr('unavailable')
            : '${_localizedDecimal(context, pct as num)}%',
      ),
    );
  }
}

class PublicQuizStatisticsScreen extends StatelessWidget {
  const PublicQuizStatisticsScreen({required this.quizId, this.api, super.key});
  final String quizId;
  final PublicQuizStatisticsApiService? api;

  @override
  Widget build(BuildContext context) =>
      _QuizStatisticsScreen(quizId: quizId, api: api, ownerOnly: false);
}

class OwnedQuizStatisticsScreen extends StatelessWidget {
  const OwnedQuizStatisticsScreen({required this.quizId, this.api, super.key});
  final String quizId;
  final PublicQuizStatisticsApiService? api;

  @override
  Widget build(BuildContext context) =>
      _QuizStatisticsScreen(quizId: quizId, api: api, ownerOnly: true);
}

class _QuizStatisticsScreen extends StatefulWidget {
  const _QuizStatisticsScreen({
    required this.quizId,
    required this.ownerOnly,
    this.api,
  });
  final String quizId;
  final bool ownerOnly;
  final PublicQuizStatisticsApiService? api;

  @override
  State<_QuizStatisticsScreen> createState() => _QuizStatisticsScreenState();
}

class _QuizStatisticsScreenState extends State<_QuizStatisticsScreen> {
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
      _load(language);
    }
  }

  void _load(String language) {
    _future = widget.ownerOnly
        ? _api.getForOwnedQuiz(widget.quizId, language: language)
        : _api.getForQuiz(widget.quizId, language: language);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AttachmentAppBar(
      currentTab: 'statistics',
      title: context.tr(
        widget.ownerOnly ? 'ownedQuizStatisticsTitle' : 'scoreDistribution',
      ),
    ),
    endDrawer: const AttachmentSideMenu(currentTab: 'statistics'),
    body: FutureBuilder<PublicQuizStatistics>(
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
                  onPressed: () =>
                      setState(() => _load(_loadedLanguage ?? 'en')),
                  child: Text(context.tr('retry')),
                ),
              ],
            ),
          );
        }
        final data = snapshot.data!;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _Metric(
                  label: context.tr('completedAttempts'),
                  value: _localizedCount(context, data.completedAttemptCount),
                ),
                const SizedBox(height: 8),
                _Metric(
                  label: context.tr('distinctParticipants'),
                  value: _localizedCount(context, data.distinctParticipants),
                ),
                const SizedBox(height: 8),
                _Metric(
                  label: context.tr('averageScore'),
                  value:
                      data.averageScoreDenominator == 0 ||
                          data.averageScorePct == null
                      ? context.tr('noScoreSample')
                      : '${_localizedDecimal(context, data.averageScorePct!)}% · n=${_localizedCount(context, data.averageScoreDenominator)}',
                ),
                const SizedBox(height: 8),
                _Metric(
                  label: context.tr('averageDuration'),
                  value:
                      data.durationDenominator == 0 ||
                          data.typicalDurationSec == null
                      ? context.tr('unavailable')
                      : '${_localizedCount(context, data.typicalDurationSec!)} s · n=${_localizedCount(context, data.durationDenominator)}',
                ),
                Text(
                  context.tr(
                    widget.ownerOnly
                        ? 'ownedQuizStatisticsTitle'
                        : 'scoreDistribution',
                  ),
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
                        height: 380,
                        showAxisTitles: true,
                      ),
                    )
                  else
                    _ScoreDistributionTable(bands: data.scoreDistribution),
                  Text(
                    'n=${_localizedCount(context, data.scoreDistributionDenominator)}',
                  ),
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
                  DataCell(Text(_localizedCount(context, band.count))),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
