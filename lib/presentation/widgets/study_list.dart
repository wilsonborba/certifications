import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/study.dart';
import 'package:certifications/domain/services/study_api_service.dart';
import 'package:certifications/presentation/widgets/study_workspace.dart';
import 'package:certifications/presentation/components/attachment/app_bar.dart';
import 'package:flutter/material.dart';

class StudyList extends StatefulWidget {
  const StudyList({super.key});
  @override
  State<StudyList> createState() => _StudyListState();
}

class _StudyListState extends State<StudyList> {
  final api = StudyApiService();
  late Future<List<Study>> future = api.list();
  void reload() => setState(() => future = api.list());
  Future<void> create() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('newStudy')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: context.tr('studyName')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(context.tr('createStudy')),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    try {
      final study = await api.create(name);
      if (mounted)
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StudyWorkspace(study: study)),
        );
      reload();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.tr('errorGeneric'))));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AttachmentAppBar(title: context.tr('yourStudies')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: create,
      icon: const Icon(Icons.add),
      label: Text(context.tr('newStudy')),
    ),
    body: FutureBuilder<List<Study>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return Center(child: Text(context.tr('errorGeneric')));
        final studies = snapshot.data ?? [];
        if (studies.isEmpty)
          return Center(child: Text(context.tr('noStudies')));
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: studies.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final study = studies[index];
            return Card(
              child: ListTile(
                title: Text(study.name),
                subtitle: Text(study.status),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudyWorkspace(study: study),
                    ),
                  );
                  reload();
                },
              ),
            );
          },
        );
      },
    ),
  );
}
