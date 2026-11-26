import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/study_history.dart';
import 'package:certifications/domain/services/study_history_api_service.dart';
import 'package:certifications/presentation/components/attachment/app_bar.dart';
import 'package:flutter/material.dart';

class CreatedQuizHistoryScreen extends StatefulWidget {
  const CreatedQuizHistoryScreen({this.api, super.key});
  final StudyHistoryApiService? api;

  @override
  State<CreatedQuizHistoryScreen> createState() =>
      _CreatedQuizHistoryScreenState();
}

class _CreatedQuizHistoryScreenState extends State<CreatedQuizHistoryScreen> {
  static const _pageSize = 20;
  late final _api = widget.api ?? StudyHistoryApiService();
  final _search = TextEditingController();
  final _quizId = TextEditingController();
  DateTime? _createdFrom;
  DateTime? _createdTo;
  String? _status;
  String? _tag;
  int _offset = 0;
  bool _invalidDateRange = false;
  late Future<StudyHistoryPage> _future = _load();

  String? _optionalText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  StudyHistoryQuery _query() => StudyHistoryQuery(
    q: _optionalText(_search.text),
    quizId: _optionalText(_quizId.text),
    createdFrom: StudyHistoryQuery.startOfLocalDateSeconds(_createdFrom),
    createdTo: StudyHistoryQuery.endOfLocalDateSeconds(_createdTo),
    status: _status,
    tag: _tag,
    limit: _pageSize,
    offset: _offset,
  );

  Future<StudyHistoryPage> _load() => _api.list(_query());

  void _apply() {
    if (_createdFrom != null &&
        _createdTo != null &&
        DateTime(
          _createdFrom!.year,
          _createdFrom!.month,
          _createdFrom!.day,
        ).isAfter(
          DateTime(_createdTo!.year, _createdTo!.month, _createdTo!.day),
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

  Future<void> _pickDate({required bool start}) async {
    final current = start ? _createdFrom : _createdTo;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (start) {
        _createdFrom = picked;
      } else {
        _createdTo = picked;
      }
      _invalidDateRange = false;
    });
  }

  void _clear() {
    setState(() {
      _search.clear();
      _quizId.clear();
      _createdFrom = null;
      _createdTo = null;
      _status = null;
      _tag = null;
      _offset = 0;
      _invalidDateRange = false;
      _future = _load();
    });
  }

  void _move(int delta) {
    setState(() {
      _offset = (_offset + delta * _pageSize).clamp(0, 1 << 30);
      _future = _load();
    });
  }

  Widget _searchField(double width) => SizedBox(
    width: width,
    child: TextField(
      controller: _search,
      decoration: InputDecoration(
        labelText: context.tr('createdHistorySearch'),
        prefixIcon: const Icon(Icons.search),
      ),
      onSubmitted: (_) => _apply(),
    ),
  );

  List<Widget> _advancedFilterFields() => [
    SizedBox(
      width: 190,
      child: TextField(
        controller: _quizId,
        decoration: InputDecoration(labelText: context.tr('quizIdFilter')),
        onSubmitted: (_) => _apply(),
      ),
    ),
    SizedBox(
      width: 210,
      child: DropdownButtonFormField<String?>(
        key: ValueKey('study-history-status-$_status'),
        initialValue: _status,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: context.tr('createdHistoryStatus'),
        ),
        items: [
          DropdownMenuItem<String?>(
            value: null,
            child: Text(context.tr('allStatuses')),
          ),
          for (final status in ['draft', 'active', 'expired'])
            DropdownMenuItem<String?>(
              value: status,
              child: Text(context.tr('studyStatus_$status')),
            ),
        ],
        onChanged: (value) => setState(() => _status = value),
      ),
    ),
    SizedBox(
      width: 200,
      child: FutureBuilder<StudyHistoryPage>(
        future: _future,
        builder: (context, snapshot) {
          final tags = snapshot.data?.availableTags ?? const [];
          return DropdownButtonFormField<String?>(
            key: ValueKey('study-history-tag-$_tag'),
            initialValue: _tag,
            isExpanded: true,
            decoration: InputDecoration(labelText: context.tr('tagFilter')),
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(context.tr('allTags')),
              ),
              for (final tag in tags)
                DropdownMenuItem<String?>(
                  value: tag.slug,
                  child: Text(tag.label),
                ),
            ],
            onChanged: (value) => setState(() => _tag = value),
          );
        },
      ),
    ),
    OutlinedButton.icon(
      onPressed: () => _pickDate(start: true),
      icon: const Icon(Icons.calendar_today_outlined),
      label: Text(_dateLabel(_createdFrom, start: true)),
    ),
    OutlinedButton.icon(
      onPressed: () => _pickDate(start: false),
      icon: const Icon(Icons.event_outlined),
      label: Text(_dateLabel(_createdTo, start: false)),
    ),
    FilledButton(onPressed: _apply, child: Text(context.tr('applyFilters'))),
    TextButton(onPressed: _clear, child: Text(context.tr('clearFilters'))),
  ];

  Widget _advancedFilterWrap({bool includeSearch = false}) => Wrap(
    spacing: 10,
    runSpacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      if (includeSearch) _searchField(240),
      ..._advancedFilterFields(),
    ],
  );

  Widget _dateRangeError() => Align(
    alignment: Alignment.centerLeft,
    child: Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        context.tr('invalidDateRange'),
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    ),
  );

  Widget _historyResults() => FutureBuilder<StudyHistoryPage>(
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
      final hasFilters =
          _search.text.trim().isNotEmpty ||
          _quizId.text.trim().isNotEmpty ||
          _createdFrom != null ||
          _createdTo != null ||
          _status != null ||
          _tag != null;
      if (page.items.isEmpty) {
        return Center(
          child: Text(
            hasFilters
                ? context.tr('noCreatedHistoryMatches')
                : context.tr('noCreatedHistoryYet'),
          ),
        );
      }
      return Column(
        children: [
          Expanded(
            child: ListView.separated(
              itemCount: page.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final study = page.items[index];
                return Card(
                  child: ListTile(
                    title: Text(study.name.isEmpty ? study.id : study.name),
                    subtitle: Text(
                      '${context.tr('studyStatus_${study.status}')} · ${study.quizId.isEmpty ? context.tr('noQuizLinked') : study.quizId}',
                    ),
                    trailing: study.quizId.isEmpty
                        ? null
                        : IconButton(
                            tooltip: context.tr('privateStatsAction'),
                            icon: const Icon(Icons.bar_chart_outlined),
                            onPressed: () => Navigator.of(context).pushNamed(
                              '/v1/me/quizzes/${Uri.encodeComponent(study.quizId)}/statistics',
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: context.tr('previous'),
                onPressed: _offset == 0 ? null : () => _move(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                context.trParams('createdHistoryRange', {
                  'from': '${page.offset + 1}',
                  'to': '${page.offset + page.items.length}',
                  'total': '${page.total}',
                }),
              ),
              IconButton(
                tooltip: context.tr('next'),
                onPressed: page.offset + page.items.length >= page.total
                    ? null
                    : () => _move(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      );
    },
  );

  @override
  void dispose() {
    _search.dispose();
    _quizId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AttachmentAppBar(
      title: MediaQuery.sizeOf(context).width < 600
          ? ''
          : context.tr('createdQuizHistoryTitle'),
    ),
    endDrawer: const AttachmentSideMenu(currentTab: 'studies'),
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isPhone = MediaQuery.sizeOf(context).width < 600;
          final compactPhone = isPhone && constraints.maxHeight < 600;
          final header = <Widget>[
            if (isPhone) ...[
              Padding(
                padding: EdgeInsets.only(bottom: compactPhone ? 4 : 8),
                child: Text(
                  context.tr('createdQuizHistoryTitle'),
                  style: compactPhone
                      ? Theme.of(context).textTheme.titleMedium
                      : Theme.of(context).textTheme.titleLarge,
                ),
              ),
              _searchField(double.infinity),
              const SizedBox(height: 4),
              ExpansionTile(
                key: const ValueKey('created-history-advanced-filters'),
                tilePadding: EdgeInsets.zero,
                title: Text(context.tr('createdHistoryFilters')),
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: constraints.maxHeight * 0.4,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _advancedFilterWrap(),
                          if (_invalidDateRange) _dateRangeError(),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              _advancedFilterWrap(includeSearch: true),
              if (_invalidDateRange) _dateRangeError(),
            ],
          ];
          final results = _historyResults();
          final headerColumn = Column(
            crossAxisAlignment: isPhone
                ? CrossAxisAlignment.stretch
                : CrossAxisAlignment.center,
            children: header,
          );
          final headerArea = isPhone
              ? ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: constraints.maxHeight * 0.55,
                  ),
                  child: SingleChildScrollView(child: headerColumn),
                )
              : headerColumn;
          final bodyContent = Column(
            crossAxisAlignment: isPhone
                ? CrossAxisAlignment.stretch
                : CrossAxisAlignment.center,
            children: [
              headerArea,
              const SizedBox(height: 12),
              Expanded(child: results),
            ],
          );
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Padding(
                padding: EdgeInsets.all(compactPhone ? 8 : 16),
                child: bodyContent,
              ),
            ),
          );
        },
      ),
    ),
  );

  String _dateLabel(DateTime? date, {required bool start}) {
    final label = context.tr(start ? 'createdHistoryFrom' : 'createdHistoryTo');
    final value = date == null
        ? context.tr('chooseDate')
        : MaterialLocalizations.of(context).formatMediumDate(date);
    return '$label: $value';
  }
}
