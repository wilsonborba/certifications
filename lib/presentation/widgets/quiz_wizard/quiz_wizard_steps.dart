import 'dart:convert';

import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/domain/models/quiz.dart';
import 'package:certifications/domain/models/quiz_wizard_data.dart';
import 'package:certifications/domain/models/study.dart';
import 'package:certifications/domain/services/study_api_service.dart';
import 'package:certifications/presentation/components/premium_hover_card.dart';
import 'package:certifications/presentation/components/quiz/granular_range_selector.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Extensions accepted by the Step 2 file picker.
const uploadAllowedExtensions = [
  'pdf',
  'docx',
  'xlsx',
  'csv',
  'txt',
  'md',
  'png',
  'jpg',
  'jpeg',
  'webp',
  'mp3',
  'wav',
  'm4a',
];

/// Step 1: name the study. Quick-preset cards (AWS/Python/ENEM/Law) were
/// removed after testing confirmed they were bad UX; free-text is now the
/// only input on this step.
class Step1ThemeView extends StatefulWidget {
  const Step1ThemeView({
    super.key,
    required this.wizardData,
    required this.isDesktop,
  });

  final QuizWizardData wizardData;
  final bool isDesktop;

  @override
  State<Step1ThemeView> createState() => _Step1ThemeViewState();
}

class _Step1ThemeViewState extends State<Step1ThemeView> {
  // Created once and reused for the field's whole lifetime. The previous
  // version built a brand new TextEditingController inline on every
  // keystroke (wizardData.setName notifies listeners, which rebuilds this
  // widget), leaking the old one every time (never disposed) and forcing a
  // manual cursor-position hack to paper over the cursor jumping back to
  // the end of the field after each character.
  late final _controller = TextEditingController(text: widget.wizardData.name);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('step1Title'),
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr('welcomeBody'),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        SizedBox(height: widget.isDesktop ? 28 : 20),
        TextField(
          controller: _controller,
          onChanged: widget.wizardData.setName,
          style: widget.isDesktop ? null : const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            labelText: context.tr('studyName'),
            hintText: context.tr('studyNameHint'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            prefixIcon: const Icon(Icons.edit),
            contentPadding: widget.isDesktop
                ? null
                : const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          ),
        ),
      ],
    );
  }
}

/// Step 2: attach the study material. Upload is the sole real source (no
/// backend support exists for "AI generates it for me" or "search the web"),
/// so this step is a single elevated, primary-feeling upload zone rather than
/// a choice between three options.
///
/// Split into two visual phases:
/// - Phase A (add files): an "Add files" button, a horizontally scrollable
///   strip of the files added so far, and a meter based on backend account
///   quota values. Missing quota data remains explicitly unavailable.
/// - Phase B (configure a file, optional): each file defaults to whole
///   document. Tapping a file's chip expands [GranularRangeSelector] for
///   just that file, accordion-style, collapsed by default.
class Step2SourceView extends StatefulWidget {
  const Step2SourceView({
    super.key,
    required this.wizardData,
    required this.isDesktop,
    required this.onPrepareSources,
    required this.studyApi,
  });

  final QuizWizardData wizardData;
  final bool isDesktop;
  final Future<String?> Function() onPrepareSources;
  final StudyApiService studyApi;

  @override
  State<Step2SourceView> createState() => _Step2SourceViewState();
}

class _Step2SourceViewState extends State<Step2SourceView> {
  int? _expandedIndex;
  String? _studyId;
  List<ReportPickerItem> _reports = const [];
  List<ReportDatasetPickerItem> _reportDatasets = const [];
  String? _selectedReportKey;
  String? _selectedDatasetRef;
  String? _reportPickerError;
  bool _loadingReports = true;
  bool _loadingReportDatasets = false;
  bool _attachingReport = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        _studyId = await widget.onPrepareSources();
        if (!mounted) return;
        await _loadReports();
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.tr('errorGeneric'))));
      }
    });
  }

  Future<void> _loadReports() async {
    setState(() {
      _loadingReports = true;
      _reportPickerError = null;
      _reports = const [];
      _reportDatasets = const [];
      _selectedReportKey = null;
      _selectedDatasetRef = null;
    });
    try {
      final reports = await widget.studyApi.listReports();
      if (!mounted) return;
      setState(() => _reports = reports);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _reportPickerError = context.tr('reportPickerUnavailable'),
      );
    } finally {
      if (mounted) setState(() => _loadingReports = false);
    }
  }

  Future<void> _selectReport(String? key) async {
    setState(() {
      _selectedReportKey = key;
      _selectedDatasetRef = null;
      _reportDatasets = const [];
      _reportPickerError = null;
    });
    if (key == null) return;
    ReportPickerItem? report;
    for (final item in _reports) {
      if ('${item.project}/${item.report}' == key) {
        report = item;
        break;
      }
    }
    if (report == null) return;
    setState(() => _loadingReportDatasets = true);
    try {
      final datasets = await widget.studyApi.listReportDatasets(report);
      if (!mounted || _selectedReportKey != key) return;
      setState(() => _reportDatasets = datasets);
    } catch (_) {
      if (!mounted || _selectedReportKey != key) return;
      setState(
        () => _reportPickerError = context.tr('reportPickerUnavailable'),
      );
    } finally {
      if (mounted && _selectedReportKey == key) {
        setState(() => _loadingReportDatasets = false);
      }
    }
  }

  Future<void> _attachReportDataset() async {
    final studyId = _studyId;
    ReportDatasetPickerItem? selected;
    for (final item in _reportDatasets) {
      if (item.externalRef == _selectedDatasetRef && item.canView) {
        selected = item;
        break;
      }
    }
    if (studyId == null || selected == null || _attachingReport) return;
    final dataset = selected;
    setState(() => _attachingReport = true);
    try {
      final source = await widget.studyApi.attachReportDataset(
        studyId: studyId,
        dataset: dataset,
      );
      if (!mounted) return;
      widget.wizardData.addExistingSource(source);
      // Account usage/caps come from study detail. Reload after the attach so
      // the meter reflects the newly committed server-side dataset bytes.
      try {
        final study = await widget.studyApi.get(studyId);
        if (!mounted) return;
        widget.wizardData.setAccountQuota(
          usedBytes: study.accountUsedBytes,
          maxBytes: study.accountMaxBytes,
          fileLimitBytes: study.maxFileBytes,
          studyLimitBytes: study.maxStudyBytes,
        );
        widget.wizardData.setExistingSources(study.sources);
      } catch (_) {
        if (!mounted) return;
        widget.wizardData.setAccountQuota(
          usedBytes: null,
          maxBytes: null,
          fileLimitBytes: null,
          studyLimitBytes: null,
        );
      }
      setState(() {
        _selectedDatasetRef = null;
        _reportPickerError = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('reportSourceAttached'))),
      );
    } catch (_) {
      if (!mounted) return;
      // The POST has no duplicate suppression. Refresh the authoritative list
      // before showing a retry path; never repeat an ambiguous attach blindly.
      try {
        final study = await widget.studyApi.get(studyId);
        widget.wizardData.setExistingSources(study.sources);
        final exists = study.sources.any(
          (source) => source.externalRef == dataset.externalRef,
        );
        if (exists && mounted) {
          setState(() => _selectedDatasetRef = null);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('reportSourceAttached'))),
          );
        } else if (mounted) {
          setState(
            () => _reportPickerError = context.tr(
              'reportSourceAttachUnconfirmed',
            ),
          );
        }
      } catch (_) {
        if (mounted) {
          setState(
            () => _reportPickerError = context.tr(
              'reportSourceAttachUnconfirmed',
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _attachingReport = false);
    }
  }

  Widget _reportPickerCard(BuildContext context) {
    final reportKey = _selectedReportKey;
    final reportSelected =
        reportKey != null &&
        _reports.any((item) => '${item.project}/${item.report}' == reportKey);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('reportsSourceLabel'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              context.tr('reportsSourceHint'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (_loadingReports || _loadingReportDatasets)
              const LinearProgressIndicator(),
            if (_reportPickerError case final error?) ...[
              const SizedBox(height: 8),
              Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (!_loadingReports &&
                _reportPickerError == null &&
                _reports.isEmpty)
              Text(context.tr('noReadableReports')),
            if (_reports.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                initialValue: _selectedReportKey,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: context.tr('reportPickerLabel'),
                ),
                items: _reports
                    .map(
                      (item) => DropdownMenuItem(
                        value: '${item.project}/${item.report}',
                        child: Text(
                          '${item.title} · ${item.project}/${item.report}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _loadingReportDatasets ? null : _selectReport,
              ),
            ],
            if (reportSelected && !_loadingReportDatasets) ...[
              const SizedBox(height: 10),
              if (_reportDatasets.isEmpty && _reportPickerError == null)
                Text(context.tr('noReadableDatasets')),
              if (_reportDatasets.isNotEmpty)
                DropdownButtonFormField<String>(
                  initialValue: _selectedDatasetRef,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: context.tr('reportDatasetLabel'),
                  ),
                  items: _reportDatasets
                      .where((item) => item.canView)
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.externalRef,
                          child: Text(
                            '${item.title} · ${item.datasetId}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedDatasetRef = value),
                ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _loadingReports || _attachingReport
                      ? null
                      : _loadReports,
                  icon: const Icon(Icons.refresh),
                  label: Text(context.tr('refreshReports')),
                ),
                FilledButton.icon(
                  onPressed:
                      _selectedDatasetRef == null ||
                          _attachingReport ||
                          _studyId == null
                      ? null
                      : _attachReportDataset,
                  icon: const Icon(Icons.add),
                  label: Text(context.tr('addReportDataset')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFiles() async {
    final wizardData = widget.wizardData;
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: uploadAllowedExtensions,
      allowMultiple: true,
    );
    if (result == null) return;

    var blocked = false;
    var unsupported = false;
    for (final picked in result.files) {
      final bytes = picked.bytes;
      if (bytes == null) continue;
      final kind = picked.extension?.toLowerCase();
      if (kind == null || !uploadAllowedExtensions.contains(kind)) {
        unsupported = true;
        continue;
      }
      List<int> normalizedBytes;
      if (const {'txt', 'md', 'csv'}.contains(kind)) {
        try {
          normalizedBytes = _normalizeTextBytes(bytes);
        } on FormatException {
          unsupported = true;
          continue;
        }
      } else {
        normalizedBytes = bytes;
      }
      if (wizardData.wouldExceedAccountQuota(normalizedBytes.length) ||
          wizardData.wouldExceedStudyQuota(normalizedBytes.length) ||
          wizardData.wouldExceedFileLimit(normalizedBytes.length)) {
        blocked = true;
        continue;
      }
      final file = AttachedFile(
        bytes: normalizedBytes,
        name: picked.name,
        kind: kind,
        totalPages: kind == 'pdf' ? _countPdfPages(bytes) : null,
        totalLines: (kind == 'txt' || kind == 'md' || kind == 'csv')
            ? _countLines(normalizedBytes)
            : null,
      );
      // The default range (page/line 1-10) was picked blind; clamp it now
      // that the real length is known so a short document doesn't send a
      // selection the backend has to reject (#pdf pages, e.g.).
      if (file.totalPages != null && file.totalPages! < file.pageEnd) {
        file.pageEnd = file.totalPages!;
      }
      if (file.totalLines != null && file.totalLines! < file.lineEnd) {
        file.lineEnd = file.totalLines!;
      }
      wizardData.addFile(file);
    }

    if (blocked && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('accountQuotaExceededWarning'))),
      );
    }
    if (unsupported && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('binarySourceUnavailable'))),
      );
    }
  }

  List<int> _normalizeTextBytes(List<int> bytes) {
    final text = utf8
        .decode(bytes)
        .replaceFirst(RegExp(r'^\uFEFF'), '')
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');
    return utf8.encode(text);
  }

  /// Real page count so the range selector can show/enforce it instead of a
  /// blind 1-10 default. Returns null (shown as "unknown") rather than
  /// guessing when the PDF can't be parsed client-side.
  int? _countPdfPages(List<int> bytes) {
    try {
      final document = PdfDocument(inputBytes: bytes);
      final count = document.pages.count;
      document.dispose();
      return count;
    } catch (_) {
      return null;
    }
  }

  int? _countLines(List<int> bytes) {
    try {
      final text = utf8.decode(bytes);
      if (text.isEmpty) return 0;
      return '\n'.allMatches(text).length + 1;
    } catch (_) {
      return null;
    }
  }

  void _removeFile(int index) {
    widget.wizardData.removeFileAt(index);
    if (_expandedIndex == index) {
      setState(() => _expandedIndex = null);
    } else if (_expandedIndex != null && _expandedIndex! > index) {
      setState(() => _expandedIndex = _expandedIndex! - 1);
    }
  }

  void _toggleExpanded(int index) {
    setState(() => _expandedIndex = _expandedIndex == index ? null : index);
  }

  @override
  Widget build(BuildContext context) {
    final wizardData = widget.wizardData;
    final scheme = Theme.of(context).colorScheme;
    final usedBytes = wizardData.projectedAccountUsageBytes;
    final capBytes = wizardData.accountMaxBytes;
    final ratio = usedBytes != null && capBytes != null && capBytes > 0
        ? (usedBytes / capBytes).clamp(0.0, 1.0)
        : null;
    final over = usedBytes != null && capBytes != null && usedBytes > capBytes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('step2Title'),
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        // Primary Upload Box Card
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(widget.isDesktop ? 24 : 18),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.upload_file, color: scheme.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('sourceUpload'),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            context.tr('sourceUploadHint'),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    FilledButton.icon(
                      onPressed: _pickFiles,
                      icon: const Icon(Icons.add),
                      label: Text(context.tr('addFiles')),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.upload_file, color: scheme.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('sourceUpload'),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                context.tr('sourceUploadHint'),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: scheme.onSurface.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: _pickFiles,
                      icon: const Icon(Icons.add),
                      label: Text(context.tr('addFiles')),
                    ),
                  ],
                ),
              const SizedBox(height: 18),
              Text(
                context.tr('preparedNotesUnavailable'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr('sourceStorageNotice'),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 12),
              _CapUsageBar(
                usedBytes: usedBytes,
                capBytes: capBytes,
                pendingBytes: wizardData.totalAttachedBytes,
                ratio: ratio,
                over: over,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        _reportPickerCard(context),
        const SizedBox(height: 20),

        // Attached Files Section
        if (wizardData.existingSources.isNotEmpty) ...[
          Text(
            context.tr('preparedSourcesLabel'),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.65),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          for (final source in wizardData.existingSources)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.check_circle_outline),
              title: Text(
                source.filename,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${formatFileSize(source.sizeBytes)} · ${source.status} · '
                '${source.selectionKind == 'all' ? context.tr('wholeDocumentOnly') : '${source.selectionKind}: ${source.selectionSpec}'}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const SizedBox(height: 8),
        ],
        if (wizardData.attachedFiles.isEmpty &&
            wizardData.existingSources.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.35),
                style: BorderStyle.solid,
              ),
            ),
            child: Center(
              child: Text(
                context.tr('noFilesAddedYet'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          )
        else ...[
          Text(
            context.tr('tapFileToConfigureHint'),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.65),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 116,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: wizardData.attachedFiles.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) => _FileChip(
                file: wizardData.attachedFiles[index],
                expanded: _expandedIndex == index,
                onTap: () => _toggleExpanded(index),
                onRemove: () => _removeFile(index),
              ),
            ),
          ),
          if (_expandedIndex != null &&
              _expandedIndex! < wizardData.attachedFiles.length) ...[
            const SizedBox(height: 16),
            GranularRangeSelector(
              key: ValueKey('range_$_expandedIndex'),
              file: wizardData.attachedFiles[_expandedIndex!],
              isDesktop: widget.isDesktop,
            ),
          ],
        ],
      ],
    );
  }
}

/// A running-total bar against the server-reported study/account cap, always
/// visible above the file strip so the user knows how much room is left.
class _CapUsageBar extends StatelessWidget {
  const _CapUsageBar({
    required this.usedBytes,
    required this.capBytes,
    required this.pendingBytes,
    required this.ratio,
    required this.over,
  });

  final int? usedBytes;
  final int? capBytes;
  final int pendingBytes;
  final double? ratio;
  final bool over;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final barColor = over ? scheme.error : scheme.primary;
    final locale = AppLocalizations.of(context).locale.toLanguageTag();
    String mib(int bytes) =>
        NumberFormat.decimalPattern(locale).format(bytes / (1024 * 1024));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                usedBytes != null && capBytes != null
                    ? context.trParams('accountQuotaUsageLabel', {
                        'used': mib(usedBytes!),
                        'cap': mib(capBytes!),
                        'pending': mib(pendingBytes),
                      })
                    : context.trParams('accountQuotaUnavailableLabel', {
                        'pending': mib(pendingBytes),
                      }),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (over) ...[
              const SizedBox(width: 6),
              Icon(Icons.warning_amber_rounded, size: 14, color: scheme.error),
            ],
          ],
        ),
        const SizedBox(height: 6),
        if (ratio != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: scheme.outlineVariant.withValues(alpha: 0.25),
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
      ],
    );
  }
}

/// A single attached file, shown as a compact chip/card in the Phase A strip.
/// Tapping it toggles the Phase B range accordion for just that file; the
/// remove icon detaches it entirely.
class _FileChip extends StatelessWidget {
  const _FileChip({
    required this.file,
    required this.expanded,
    required this.onTap,
    required this.onRemove,
  });

  final AttachedFile file;
  final bool expanded;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final visual = fileKindVisual(file.kind.toLowerCase());

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 150,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: expanded
                ? scheme.primary
                : scheme.outlineVariant.withValues(alpha: 0.4),
            width: expanded ? 1.6 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: visual.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(visual.icon, size: 11, color: visual.color),
                      const SizedBox(width: 3),
                      Text(
                        file.kind.toUpperCase(),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: visual.color,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: onRemove,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      Icons.close,
                      size: 15,
                      color: scheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              file.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    formatFileSize(file.sizeBytes),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ),
                Icon(
                  file.isWholeDocument ? Icons.select_all : Icons.tune,
                  size: 13,
                  color: expanded
                      ? scheme.primary
                      : scheme.onSurface.withValues(alpha: 0.4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Step 3: difficulty and question count.
class Step3FormatView extends StatelessWidget {
  const Step3FormatView({
    super.key,
    required this.wizardData,
    required this.isDesktop,
  });

  final QuizWizardData wizardData;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final localeLanguage = Localizations.localeOf(context).languageCode;
    final selectedLanguage =
        wizardData.generationLanguage ??
        switch (localeLanguage) {
          'pt' => 'pt-BR',
          'th' => 'th',
          _ => 'en',
        };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('step3Title'),
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        Text(
          context.tr('difficultyLabel'),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        _maybeFullWidth(
          SegmentedButton<DifficultyLevel>(
            segments: [
              ButtonSegment(
                value: DifficultyLevel.easy,
                label: Text(context.tr('easy')),
                icon: const Icon(Icons.sentiment_satisfied),
              ),
            ],
            selected: {DifficultyLevel.easy},
            onSelectionChanged: (_) =>
                wizardData.setDifficulty(DifficultyLevel.easy),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          context.tr('generationLanguage'),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        _maybeFullWidth(
          DropdownButtonFormField<String>(
            initialValue: selectedLanguage,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: context.tr('generationLanguage'),
            ),
            items: [
              DropdownMenuItem(
                value: 'en',
                child: Text(context.tr('languageEnglish')),
              ),
              DropdownMenuItem(
                value: 'pt-BR',
                child: Text(context.tr('languagePortuguese')),
              ),
              DropdownMenuItem(
                value: 'th',
                child: Text(context.tr('languageThai')),
              ),
            ],
            onChanged: (language) {
              if (language != null) {
                wizardData.setGenerationLanguage(language);
              }
            },
          ),
        ),
        const SizedBox(height: 28),
        Text(
          '${context.tr('questionCount')}: ${_questionCountLabel(context)}',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        _maybeFullWidth(
          Semantics(
            label: context.tr('questionCount'),
            value: '${wizardData.questionCount}',
            child: Slider(
              value: wizardData.questionCount.toDouble(),
              min: 1,
              max: 20,
              divisions: 19,
              label: '${wizardData.questionCount}',
              onChanged: (count) => wizardData.setQuestionCount(count.round()),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          context.tr('generationWebResearchUnavailable'),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _questionCountLabel(BuildContext context) =>
      '${wizardData.questionCount}';

  Widget _maybeFullWidth(Widget child) =>
      isDesktop ? child : SizedBox(width: double.infinity, child: child);
}

/// Step 4: an Apple-premium receipt card reviewing every choice made so far,
/// plus the public/private visibility choice (with a warning when public)
/// right before the final generate action.
class Step4ReviewView extends StatelessWidget {
  const Step4ReviewView({
    super.key,
    required this.wizardData,
    required this.onGenerate,
    required this.onInspectSources,
    required this.isInspectingSources,
    this.inspectionStatus,
    this.uploadProgress,
    this.generateError,
  });

  final QuizWizardData wizardData;
  final VoidCallback onGenerate;
  final VoidCallback onInspectSources;
  final bool isInspectingSources;
  final String? inspectionStatus;
  final double? uploadProgress;

  /// When non-null, displayed as an inline error above the generate button so
  /// the user knows the previous attempt failed without leaving Step 4.
  final String? generateError;

  String _difficultyLabel(BuildContext context) {
    switch (wizardData.difficulty) {
      case DifficultyLevel.easy:
        return context.tr('easy');
      case DifficultyLevel.medium:
        return context.tr('medium');
      case DifficultyLevel.hard:
        return context.tr('hard');
    }
  }

  String _questionCountLine(BuildContext context) =>
      '${wizardData.questionCount} ${context.tr('questionsSuffixLabel')}';

  String _generationLanguageLabel(BuildContext context) {
    final language =
        wizardData.generationLanguage ??
        switch (Localizations.localeOf(context).languageCode) {
          'pt' => 'pt-BR',
          'th' => 'th',
          _ => 'en',
        };
    return context.tr(switch (language) {
      'pt-BR' => 'languagePortuguese',
      'th' => 'languageThai',
      _ => 'languageEnglish',
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isPublic = wizardData.visibility == QuizVisibility.public;
    final fileNames = [
      ...wizardData.existingSources.map((source) => source.filename),
      ...wizardData.attachedFiles.map((file) => file.name),
    ];
    final filesValue = fileNames.isEmpty
        ? context.tr('noFilesAddedYet')
        : context.trParams('reviewFilesCountLabel', {
            'count': '${fileNames.length}',
            'names': fileNames.join(', '),
          });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('step4Title'),
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        PremiumHoverCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReceiptRow(
                label: context.tr('reviewThemeLabel'),
                value: wizardData.name,
              ),
              Divider(
                height: 32,
                color: scheme.outlineVariant.withValues(alpha: 0.3),
              ),
              _ReceiptRow(
                label: context.tr('reviewSourceLabel'),
                value: filesValue,
              ),
              Divider(
                height: 32,
                color: scheme.outlineVariant.withValues(alpha: 0.3),
              ),
              _ReceiptRow(
                label: context.tr('reviewLevelLabel'),
                value:
                    '${_difficultyLabel(context)} • ${_questionCountLine(context)}',
              ),
              Divider(
                height: 32,
                color: scheme.outlineVariant.withValues(alpha: 0.3),
              ),
              _ReceiptRow(
                label: context.tr('generationLanguage'),
                value: _generationLanguageLabel(context),
              ),
              Divider(
                height: 32,
                color: scheme.outlineVariant.withValues(alpha: 0.3),
              ),
              Text(
                context.tr('reviewVisibilityLabel'),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 10),
              SegmentedButton<QuizVisibility>(
                expandedInsets: EdgeInsets.zero,
                segments: [
                  ButtonSegment(
                    value: QuizVisibility.private,
                    label: Text(context.tr('visibilityPrivate')),
                    icon: const Icon(Icons.lock_outline),
                  ),
                  ButtonSegment(
                    value: QuizVisibility.public,
                    label: Text(context.tr('visibilityPublic')),
                    icon: const Icon(Icons.public),
                  ),
                ],
                selected: {wizardData.visibility},
                onSelectionChanged: (set) =>
                    wizardData.setVisibility(set.first),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: !isPublic
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.amber.shade800,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  context.tr('visibilityPublicWarning'),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        OutlinedButton.icon(
          onPressed: isInspectingSources ? null : onInspectSources,
          icon: isInspectingSources
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.fact_check_outlined),
          label: Text(context.tr('inspectSources')),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr('sourceInspectionDescription'),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: scheme.onSurface.withValues(alpha: 0.68),
          ),
        ),
        if (uploadProgress != null) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(value: uploadProgress),
        ],
        if (inspectionStatus != null) ...[
          const SizedBox(height: 8),
          Text(inspectionStatus!, style: Theme.of(context).textTheme.bodySmall),
        ],
        const SizedBox(height: 16),
        if (generateError != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.redAccent.withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.redAccent,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    generateError!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          ),
        ],
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: wizardData.isStep4Valid && !isInspectingSources
                ? onGenerate
                : null,
            icon: const Icon(Icons.auto_awesome),
            label: Text(
              context.tr('generateQuizNow'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}

/// One label/value line of the Step 4 receipt card.
class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
