import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/study.dart';
import 'package:certifications/domain/services/study_api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:certifications/presentation/widgets/question_session.dart';
import 'package:certifications/presentation/components/attachment/app_bar.dart';
import 'package:flutter/material.dart';

class StudyWorkspace extends StatefulWidget {
  const StudyWorkspace({super.key, required this.study});
  final Study study;
  @override
  State<StudyWorkspace> createState() => _StudyWorkspaceState();
}

class _StudyWorkspaceState extends State<StudyWorkspace> {
  final api = StudyApiService();
  late Study study = widget.study;
  bool busy = false;
  bool useWeb = false;
  String difficulty = 'easy';
  String? error;
  Future<void> _refresh() async {
    setState(() => busy = true);
    try {
      study = await api.get(study.id);
    } catch (_) {
      error = context.tr('errorGeneric');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _add() async {
    final kind = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['pdf', 'audio', 'text']
              .map(
                (item) => ListTile(
                  title: Text(context.tr(item)),
                  onTap: () => Navigator.pop(context, item),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (kind == null) return;
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.any,
    );
    final file = result?.files.single;
    if (file?.bytes == null || file == null) return;
    if (file.bytes!.length > 100 * 1024 * 1024) {
      setState(() => error = context.tr('errorGeneric'));
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await api.upload(
        studyId: study.id,
        kind: kind,
        filename: file.name,
        bytes: file.bytes!,
        mimeType: file.extension == 'pdf'
            ? 'application/pdf'
            : kind == 'audio'
            ? 'audio/mpeg'
            : 'text/plain',
      );
      await _refresh();
    } catch (_) {
      if (mounted) setState(() => error = context.tr('errorGeneric'));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _selectAndProcess(StudySource source) async {
    final first = TextEditingController();
    final last = TextEditingController();
    final selected = await showDialog<Map<String, int>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('selectRange')),
        content: Row(
          children: [
            Expanded(
              child: TextField(
                controller: first,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Start'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: last,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'End'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('delete')),
          ),
          ElevatedButton(
            onPressed: () {
              final a = int.tryParse(first.text);
              final b = int.tryParse(last.text);
              if (a != null && b != null)
                Navigator.pop(
                  context,
                  source.kind == 'pdf'
                      ? {'page_start': a, 'page_end': b}
                      : source.kind == 'audio'
                      ? {'audio_start_ms': a, 'audio_end_ms': b}
                      : {'line_start': a, 'line_end': b},
                );
            },
            child: Text(context.tr('process')),
          ),
        ],
      ),
    );
    if (selected == null) return;
    setState(() => busy = true);
    try {
      await api.select(
        studyId: study.id,
        sourceId: source.id,
        selection: selected,
      );
      await api.ingest(study.id, source.id);
      await _refresh();
    } catch (_) {
      if (mounted) setState(() => error = context.tr('errorGeneric'));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final max = 150 * 1024 * 1024;
    return Scaffold(
      appBar: AttachmentAppBar(title: study.name),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: busy ? null : _add,
        icon: const Icon(Icons.add),
        label: Text(context.tr('addSource')),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              '${context.tr('remaining')}: ${((max - study.activeSizeBytes) / 1024 / 1024).clamp(0, 150).toStringAsFixed(1)} MB',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 16),
            if (error != null) _Error(message: error!),
            if (study.sources.isNotEmpty &&
                study.sources.every((source) => source.status == 'ready'))
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                          value: 'easy',
                          label: Text(context.tr('easy')),
                        ),
                        ButtonSegment(
                          value: 'medium',
                          label: Text(context.tr('medium')),
                        ),
                        ButtonSegment(
                          value: 'hard',
                          label: Text(context.tr('hard')),
                        ),
                      ],
                      selected: {difficulty},
                      onSelectionChanged: (value) =>
                          setState(() => difficulty = value.first),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(context.tr('useWeb')),
                      subtitle: Text(context.tr('useWebDescription')),
                      value: useWeb,
                      onChanged: busy
                          ? null
                          : (value) => setState(() => useWeb = value),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: busy
                          ? null
                          : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => QuestionSession(
                                  studyId: study.id,
                                  difficulty: difficulty,
                                  useWeb: useWeb,
                                ),
                              ),
                            ),
                      child: Text(context.tr('generate')),
                    ),
                  ],
                ),
              ),
            if (busy)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
            ...study.sources.map(
              (source) => Card(
                child: ListTile(
                  title: Text(source.filename),
                  subtitle: Text(
                    '${source.kind.toUpperCase()} · ${source.status}',
                  ),
                  trailing: source.status == 'ready'
                      ? const Icon(Icons.check_circle_outline)
                      : OutlinedButton(
                          onPressed: busy
                              ? null
                              : () => _selectAndProcess(source),
                          child: Text(context.tr('process')),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: Text(message)),
  );
}
