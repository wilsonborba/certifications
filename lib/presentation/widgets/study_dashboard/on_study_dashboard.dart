import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/study.dart';
import 'package:certifications/domain/services/study_api_service.dart';
import 'package:certifications/presentation/components/attachment/app_bar.dart';
import 'package:certifications/presentation/components/dashboard/completed_metrics_banner.dart';
import 'package:certifications/presentation/components/dashboard/standby_study_card.dart';
import 'package:certifications/presentation/widgets/study_workspace.dart';
import 'package:flutter/material.dart';

class OnStudyDashboardScreen extends StatefulWidget {
  const OnStudyDashboardScreen({super.key});

  @override
  State<OnStudyDashboardScreen> createState() => _OnStudyDashboardScreenState();
}

class _OnStudyDashboardScreenState extends State<OnStudyDashboardScreen> {
  final api = StudyApiService();
  late Future<List<Study>> future = api.list();

  void _reload() {
    setState(() {
      future = api.list();
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 768;

    return Scaffold(
      appBar: AttachmentAppBar(title: context.tr('yourStudies')),
      body: SafeArea(
        child: FutureBuilder<List<Study>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final studies = snapshot.data ?? [];
            final totalBytes = studies.fold<int>(0, (sum, s) => sum + s.activeSizeBytes);

            return SingleChildScrollView(
              padding: EdgeInsets.all(isDesktop ? 24 : 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CompletedMetricsBanner(
                        totalStudies: studies.length,
                        totalSizeBytes: totalBytes,
                        completedQuizzesCount: studies.where((s) => s.status == 'completed').length,
                        averageScorePercent: 85.0,
                        isDesktop: isDesktop,
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
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (studies.isEmpty)
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
                      else
                        Column(
                          children: studies.map((study) {
                            return StandbyStudyCard(
                              study: study,
                              isDesktop: isDesktop,
                              onDeleted: _reload,
                              onOpen: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => StudyWorkspace(study: study),
                                  ),
                                );
                                _reload();
                              },
                            );
                          }).toList(),
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
