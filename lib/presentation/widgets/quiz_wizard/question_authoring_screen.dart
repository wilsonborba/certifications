import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/authoring.dart';
import 'package:certifications/domain/models/public_question_catalog.dart';
import 'package:certifications/domain/services/public_question_api_service.dart';
import 'package:certifications/domain/services/question_authoring_service.dart';
import 'package:flutter/material.dart';

class QuestionAuthoringScreen extends StatefulWidget {
  const QuestionAuthoringScreen({
    super.key,
    required this.studyId,
    required this.studyTitle,
    required this.onPublished,
    this.authoringService,
    this.publicQuestionService,
  });

  final String studyId;
  final String studyTitle;
  final VoidCallback onPublished;
  final QuestionAuthoringService? authoringService;
  final PublicQuestionApiService? publicQuestionService;

  @override
  State<QuestionAuthoringScreen> createState() =>
      _QuestionAuthoringScreenState();
}

class _QuestionAuthoringScreenState extends State<QuestionAuthoringScreen> {
  late final _authoring = widget.authoringService ?? QuestionAuthoringService();
  late final _publicQuestions =
      widget.publicQuestionService ?? PublicQuestionApiService();
  late Future<List<AuthoringQuestion>> _questions = _authoring.list(
    widget.studyId,
  );
  final _searchController = TextEditingController();
  PublicQuestionCatalogPage? _catalogPage;
  final Set<String> _selectedVersionIds = {};
  bool _loadingCatalog = false;
  bool _reusing = false;
  bool _publishing = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reloadQuestions() {
    setState(() {
      _questions = _authoring.list(widget.studyId);
    });
  }

  Future<void> _editQuestion([AuthoringQuestion? question]) async {
    final draft = await showDialog<_QuestionDraft>(
      context: context,
      builder: (_) => _QuestionEditorDialog(question: question),
    );
    if (draft == null || !mounted) return;
    try {
      if (question == null) {
        await _authoring.create(
          studyId: widget.studyId,
          language: draft.language,
          prompt: draft.prompt,
          alternatives: draft.alternatives,
          correctId: draft.correctId,
          explanation: draft.explanation,
          citationRef: draft.citationRef,
        );
      } else {
        await _authoring.update(
          studyId: widget.studyId,
          question: question,
          language: draft.language,
          prompt: draft.prompt,
          alternatives: draft.alternatives,
          correctId: draft.correctId,
          explanation: draft.explanation,
          citationRef: draft.citationRef,
        );
      }
      if (mounted) _reloadQuestions();
    } on QuestionAuthoringException catch (error) {
      if (mounted) {
        _showMessage(
          context.trParams('questionSaveError', {
            'status': '${error.statusCode}',
          }),
        );
      }
    } on FormatException {
      if (mounted) _showMessage(context.tr('questionResponseInvalid'));
    } catch (_) {
      if (mounted) _showMessage(context.tr('errorGeneric'));
    }
  }

  Future<void> _importCsv() async {
    final imported = await showDialog<bool>(
      context: context,
      builder: (_) =>
          _CsvImportDialog(studyId: widget.studyId, service: _authoring),
    );
    if (imported == true && mounted) _reloadQuestions();
  }

  Future<void> _searchCatalog({int offset = 0}) async {
    setState(() => _loadingCatalog = true);
    try {
      final page = await _publicQuestions.search(
        query: _searchController.text.trim().isEmpty
            ? null
            : _searchController.text.trim(),
        limit: 20,
        offset: offset,
      );
      if (mounted) setState(() => _catalogPage = page);
    } on FormatException {
      if (mounted) _showMessage(context.tr('questionResponseInvalid'));
    } catch (_) {
      if (mounted) _showMessage(context.tr('errorGeneric'));
    } finally {
      if (mounted) setState(() => _loadingCatalog = false);
    }
  }

  Future<void> _reuseSelected() async {
    if (_selectedVersionIds.isEmpty || _selectedVersionIds.length > 50) return;
    setState(() => _reusing = true);
    try {
      final result = await _publicQuestions.reuseSelected(
        studyId: widget.studyId,
        questionVersionIds: _selectedVersionIds.toList(growable: false),
      );
      if (!mounted) return;
      _selectedVersionIds.clear();
      _showMessage(
        context.trParams('questionReuseResult', {
          'added': '${result.addedCount}',
          'present': '${result.alreadyPresentCount}',
        }),
      );
      _reloadQuestions();
    } on FormatException {
      if (mounted) _showMessage(context.tr('questionResponseInvalid'));
    } catch (_) {
      if (mounted) _showMessage(context.tr('errorGeneric'));
    } finally {
      if (mounted) setState(() => _reusing = false);
    }
  }

  Future<void> _publish() async {
    final draft = await showDialog<_PublishDraft>(
      context: context,
      builder: (_) => _PublishDialog(title: widget.studyTitle),
    );
    if (draft == null || !mounted) return;
    setState(() => _publishing = true);
    try {
      await _authoring.publish(
        studyId: widget.studyId,
        title: draft.title,
        tags: draft.tags,
      );
      if (!mounted) return;
      widget.onPublished();
      _showMessage(context.tr('questionPublished'));
      Navigator.of(context).pop();
    } on QuestionAuthoringException catch (error) {
      if (mounted) {
        _showMessage(
          context.trParams('questionPublishError', {
            'status': '${error.statusCode}',
          }),
        );
      }
    } on FormatException {
      if (mounted) _showMessage(context.tr('questionResponseInvalid'));
    } catch (_) {
      if (mounted) _showMessage(context.tr('errorGeneric'));
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('questionReviewTitle'))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: FutureBuilder<List<AuthoringQuestion>>(
            future: _questions,
            builder: (context, snapshot) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    widget.studyTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(context.tr('questionReviewBody')),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: () => _editQuestion(),
                        icon: const Icon(Icons.add),
                        label: Text(context.tr('addManualQuestion')),
                      ),
                      OutlinedButton.icon(
                        onPressed: _importCsv,
                        icon: const Icon(Icons.upload_file_outlined),
                        label: Text(context.tr('importCsv')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    context.tr('questionListTitle'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (snapshot.hasError)
                    _StatusCard(
                      message: context.tr('questionLoadError'),
                      action: TextButton(
                        onPressed: _reloadQuestions,
                        child: Text(context.tr('retry')),
                      ),
                    )
                  else if ((snapshot.data ?? const []).isEmpty)
                    _StatusCard(message: context.tr('questionListEmpty'))
                  else
                    ...snapshot.data!.map(
                      (question) => _QuestionCard(
                        question: question,
                        onEdit: () => _editQuestion(question),
                      ),
                    ),
                  const SizedBox(height: 24),
                  _buildPublicCatalog(colors),
                  const SizedBox(height: 24),
                  _buildVisualNotice(),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed:
                        _publishing ||
                            snapshot.connectionState ==
                                ConnectionState.waiting ||
                            (snapshot.data ?? const []).isEmpty
                        ? null
                        : _publish,
                    icon: _publishing
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.public),
                    label: Text(context.tr('publishQuestionSet')),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPublicCatalog(ColorScheme colors) {
    final page = _catalogPage;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('reusePublicQuestions'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(context.tr('reusePublicQuestionsBody')),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _searchCatalog(),
                    decoration: InputDecoration(
                      labelText: context.tr('searchPublicQuestions'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: context.tr('search'),
                  onPressed: _loadingCatalog ? null : () => _searchCatalog(),
                  icon: _loadingCatalog
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                ),
              ],
            ),
            if (page != null) ...[
              const SizedBox(height: 8),
              ...page.items.map(_buildCatalogItem),
              Row(
                children: [
                  TextButton(
                    onPressed: page.offset == 0 || _loadingCatalog
                        ? null
                        : () => _searchCatalog(
                            offset: (page.offset - page.limit).clamp(
                              0,
                              1 << 30,
                            ),
                          ),
                    child: Text(context.tr('previousPage')),
                  ),
                  if (page.items.isNotEmpty)
                    Text(
                      '${page.offset + 1}–${page.offset + page.items.length}',
                    ),
                  TextButton(
                    onPressed: !page.hasMore || _loadingCatalog
                        ? null
                        : () =>
                              _searchCatalog(offset: page.offset + page.limit),
                    child: Text(context.tr('nextPage')),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed:
                      _selectedVersionIds.isEmpty ||
                          _selectedVersionIds.length > 50 ||
                          _reusing
                      ? null
                      : _reuseSelected,
                  icon: _reusing
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.playlist_add),
                  label: Text(
                    context.trParams('reuseSelectedCount', {
                      'count': '${_selectedVersionIds.length}',
                    }),
                  ),
                ),
              ),
            ],
            if (page != null && page.items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(context.tr('publicQuestionNoResults')),
              ),
            if (page == null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(context.tr('publicQuestionPrivacyNotice')),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCatalogItem(PublicQuestionCatalogItem item) => CheckboxListTile(
    value: _selectedVersionIds.contains(item.questionVersionId),
    onChanged: (selected) => setState(() {
      if (selected == true && _selectedVersionIds.length < 50) {
        _selectedVersionIds.add(item.questionVersionId);
      } else {
        _selectedVersionIds.remove(item.questionVersionId);
      }
    }),
    controlAffinity: ListTileControlAffinity.leading,
    title: Text(item.prompt),
    subtitle: Text('${item.quizTitle} · ${item.language}'),
  );

  Widget _buildVisualNotice() => Card(
    child: ListTile(
      leading: const Icon(Icons.insert_chart_outlined),
      title: Text(context.tr('questionVisualTitle')),
      subtitle: Text(context.tr('questionVisualUnavailable')),
    ),
  );
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.question, required this.onEdit});

  final AuthoringQuestion question;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(top: 10),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  question.prompt,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: context.tr('editQuestion'),
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final option in question.alternatives)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Icon(
                    option.id == question.correctId
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 18,
                    color: option.id == question.correctId
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('${option.id.toUpperCase()}. ${option.text}'),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text(question.explanation),
          if (question.citationRef.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              context.trParams('questionCitationLabel', {
                'citation': question.citationRef,
              }),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            context.trParams('questionOriginLabel', {
              'origin': _originLabel(context, question.origin),
            }),
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    ),
  );
}

String _originLabel(BuildContext context, String origin) => switch (origin) {
  'generated_with_cortex' => context.tr('originAppGeneration'),
  'supplied_by_creator' => context.tr('originCreatorSupplied'),
  _ => context.tr('originUnknown'),
};

class _QuestionDraft {
  const _QuestionDraft({
    required this.language,
    required this.prompt,
    required this.alternatives,
    required this.correctId,
    required this.explanation,
    required this.citationRef,
  });

  final String language;
  final String prompt;
  final List<AuthoringAlternative> alternatives;
  final String correctId;
  final String explanation;
  final String citationRef;
}

class _QuestionEditorDialog extends StatefulWidget {
  const _QuestionEditorDialog({this.question});
  final AuthoringQuestion? question;

  @override
  State<_QuestionEditorDialog> createState() => _QuestionEditorDialogState();
}

class _QuestionEditorDialogState extends State<_QuestionEditorDialog> {
  late final _prompt = TextEditingController(text: widget.question?.prompt);
  late final _explanation = TextEditingController(
    text: widget.question?.explanation,
  );
  late final _citation = TextEditingController(
    text: widget.question?.citationRef,
  );
  late final List<String> _optionIds = widget.question == null
      ? List.generate(4, (index) => String.fromCharCode(97 + index))
      : widget.question!.alternatives.map((item) => item.id).toList();
  late final List<TextEditingController> _options = widget.question == null
      ? List.generate(_optionIds.length, (_) => TextEditingController())
      : widget.question!.alternatives
            .map((item) => TextEditingController(text: item.text))
            .toList();
  late String _language = widget.question?.language ?? 'en';
  late String _correctId = widget.question?.correctId ?? 'a';
  String? _validation;

  @override
  void dispose() {
    _prompt.dispose();
    _explanation.dispose();
    _citation.dispose();
    for (final option in _options) {
      option.dispose();
    }
    super.dispose();
  }

  void _save() {
    final alternatives = <AuthoringAlternative>[];
    for (var index = 0; index < _options.length; index++) {
      final text = _options[index].text.trim();
      if (text.isNotEmpty) {
        alternatives.add(
          AuthoringAlternative(id: _optionIds[index], text: text),
        );
      }
    }
    if (_prompt.text.trim().isEmpty || _explanation.text.trim().isEmpty) {
      setState(() => _validation = context.tr('questionRequiredFields'));
      return;
    }
    if (alternatives.length < 2 ||
        !alternatives.any((item) => item.id == _correctId)) {
      setState(() => _validation = context.tr('questionChoicesValidation'));
      return;
    }
    Navigator.of(context).pop(
      _QuestionDraft(
        language: _language,
        prompt: _prompt.text.trim(),
        alternatives: alternatives,
        correctId: _correctId,
        explanation: _explanation.text.trim(),
        citationRef: _citation.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeIds = _options
        .asMap()
        .entries
        .where((entry) => entry.value.text.trim().isNotEmpty)
        .map((entry) => _optionIds[entry.key])
        .toList();
    return AlertDialog(
      title: Text(
        context.tr(
          widget.question == null ? 'addManualQuestion' : 'editQuestion',
        ),
      ),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _language,
                decoration: InputDecoration(labelText: context.tr('language')),
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'pt-BR', child: Text('Português')),
                  DropdownMenuItem(value: 'th', child: Text('ไทย')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _language = value);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _prompt,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: context.tr('questionPrompt'),
                ),
              ),
              const SizedBox(height: 10),
              for (var index = 0; index < _options.length; index++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextField(
                    controller: _options[index],
                    decoration: InputDecoration(
                      labelText: context.trParams('optionNumber', {
                        'letter': String.fromCharCode(65 + index),
                      }),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              DropdownButtonFormField<String>(
                initialValue: activeIds.contains(_correctId)
                    ? _correctId
                    : activeIds.firstOrNull,
                decoration: InputDecoration(
                  labelText: context.tr('correctChoice'),
                ),
                items: [
                  for (final id in activeIds)
                    DropdownMenuItem(value: id, child: Text(id.toUpperCase())),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _correctId = value);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _explanation,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: context.tr('explanation'),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _citation,
                decoration: InputDecoration(
                  labelText: context.tr('supportingSource'),
                ),
              ),
              if (_validation != null) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _validation!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr('cancel')),
        ),
        FilledButton(onPressed: _save, child: Text(context.tr('saveQuestion'))),
      ],
    );
  }
}

class _CsvImportDialog extends StatefulWidget {
  const _CsvImportDialog({required this.studyId, required this.service});
  final String studyId;
  final QuestionAuthoringService service;

  @override
  State<_CsvImportDialog> createState() => _CsvImportDialogState();
}

class _CsvImportDialogState extends State<_CsvImportDialog> {
  static const _sample =
      'language,prompt,option_a,option_b,option_c,option_d,correct_option,explanation,citation_ref\n'
      'en,Capital of France?,Paris,Lyon,Nice,Marseille,a,Paris is the capital,p.1';
  late final _csv = TextEditingController(text: _sample);
  CsvImportResult? _preview;
  String? _previewCsvText;
  bool _busy = false;
  bool _confirming = false;

  @override
  void dispose() {
    _csv.dispose();
    super.dispose();
  }

  Future<void> _previewCsv() async {
    final csvText = _csv.text;
    setState(() {
      _busy = true;
      _preview = null;
      _previewCsvText = null;
    });
    try {
      final result = await widget.service.previewCsv(
        studyId: widget.studyId,
        csvText: csvText,
      );
      if (mounted && _csv.text == csvText) {
        setState(() {
          _preview = result;
          _previewCsvText = csvText;
        });
      }
    } on QuestionAuthoringException catch (error) {
      if (mounted && _csv.text == csvText) {
        _message(
          context.trParams('csvRequestError', {
            'status': '${error.statusCode}',
          }),
        );
      }
    } catch (_) {
      if (mounted && _csv.text == csvText) {
        _message(context.tr('errorGeneric'));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmImport() async {
    final current = _preview;
    final csvText = _previewCsvText;
    if (current == null ||
        csvText == null ||
        csvText != _csv.text ||
        current.invalidRows.isNotEmpty) {
      return;
    }
    setState(() {
      _busy = true;
      _confirming = true;
    });
    try {
      final result = await widget.service.confirmCsv(
        studyId: widget.studyId,
        csvText: csvText,
      );
      if (!mounted) return;
      if (result.previewOnly || result.invalidRows.isNotEmpty) {
        _message(context.tr('csvConfirmRejected'));
        return;
      }
      Navigator.of(context).pop(true);
    } on QuestionAuthoringException catch (error) {
      if (mounted) {
        _message(
          context.trParams('csvRequestError', {
            'status': '${error.statusCode}',
          }),
        );
      }
    } catch (_) {
      if (mounted) _message(context.tr('errorGeneric'));
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _confirming = false;
        });
      }
    }
  }

  void _message(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.tr('importCsv')),
    content: SizedBox(
      width: 640,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('csvColumnContract')),
            const SizedBox(height: 10),
            TextField(
              controller: _csv,
              enabled: !_confirming,
              minLines: 7,
              maxLines: 12,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              decoration: const InputDecoration(border: OutlineInputBorder()),
              onChanged: (_) => setState(() {
                _preview = null;
                _previewCsvText = null;
              }),
            ),
            if (_preview != null) ...[
              const SizedBox(height: 16),
              Text(
                context.trParams('csvValidRows', {
                  'count': '${_preview!.validRows.length}',
                }),
              ),
              for (final row in _preview!.validRows)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.check_circle_outline),
                  title: Text('${row.rowNumber}. ${row.prompt}'),
                  subtitle: Text(
                    '${row.language} · ${row.correctId.toUpperCase()}',
                  ),
                ),
              Text(
                context.trParams('csvInvalidRows', {
                  'count': '${_preview!.invalidRows.length}',
                }),
              ),
              for (final row in _preview!.invalidRows)
                ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    context.trParams('csvRowError', {
                      'row': '${row.rowNumber}',
                    }),
                  ),
                  subtitle: Text(row.error),
                ),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _busy ? null : () => Navigator.of(context).pop(false),
        child: Text(context.tr('cancel')),
      ),
      OutlinedButton(
        onPressed: _busy ? null : _previewCsv,
        child: Text(context.tr('previewCsv')),
      ),
      FilledButton(
        onPressed:
            _busy ||
                _preview == null ||
                _previewCsvText != _csv.text ||
                _preview!.validRows.isEmpty ||
                _preview!.invalidRows.isNotEmpty
            ? null
            : _confirmImport,
        child: Text(context.tr('confirmImport')),
      ),
    ],
  );
}

class _PublishDraft {
  const _PublishDraft({required this.title, required this.tags});
  final String title;
  final List<String> tags;
}

class _PublishDialog extends StatefulWidget {
  const _PublishDialog({required this.title});
  final String title;

  @override
  State<_PublishDialog> createState() => _PublishDialogState();
}

class _PublishDialogState extends State<_PublishDialog> {
  late final _title = TextEditingController(text: widget.title);
  final _tags = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _tags.dispose();
    super.dispose();
  }

  void _confirm() {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    final tags = _tags.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    Navigator.of(context).pop(_PublishDraft(title: title, tags: tags));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.tr('publishQuestionSet')),
    content: SizedBox(
      width: 480,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('publishFinalWarning')),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            decoration: InputDecoration(labelText: context.tr('quizTitle')),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _tags,
            decoration: InputDecoration(
              labelText: context.tr('quizTags'),
              helperText: context.tr('quizTagsLimit'),
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(context.tr('cancel')),
      ),
      FilledButton(
        onPressed: _title.text.trim().isEmpty ? null : _confirm,
        child: Text(context.tr('publishFinal')),
      ),
    ],
  );
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.message, this.action});
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(child: Text(message)),
          if (action != null) action!,
        ],
      ),
    ),
  );
}
