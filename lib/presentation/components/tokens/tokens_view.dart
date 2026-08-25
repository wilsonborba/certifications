import 'dart:convert';
import 'dart:math' as math;
import 'package:accredit/core/utils/my_logs.dart';
import 'package:accredit/core/utils/my_nagivation.dart';
import 'package:accredit/domain/services/api_certification_manager.dart';
import 'package:accredit/presentation/components/tokens/glowing_button.dart';
import 'package:accredit/presentation/widgets/attachment/on_attachment.dart';
import 'package:flutter/material.dart';

/// Represents a provider option (Grok/Gemini/OpenAI etc.)
enum TokenProvider {
  //openai('ChatGPT / OpenAI'),
  gemini('Google Gemini'),
  groq('Groq (groq.com)');

  const TokenProvider(this.label);
  final String label;

  get labelSnakeCase => label == 'Google Gemini'
      ? 'gemini'
      : label == 'Groq (groq.com)'
      ? 'groq'
      : 'unknown';
}

/// UI model for a stored token.
/// NOTE: keyPreview is safe-to-display text (masked/partial).
class TokenEntry {
  TokenEntry({
    required this.id,
    required this.provider,
    required this.name,
    required this.keyPreview,
    required this.createdAt,
    this.isDefault = false,
  });

  final int id;
  final TokenProvider provider;
  final String name;
  final String keyPreview;
  final DateTime createdAt;
  bool isDefault;
}

/// Usage model (per provider or per token).
class UsageSnapshot {
  UsageSnapshot({
    this.totalRequests,
    this.totalTokens,
    this.costUsd,
    this.periodLabel = 'Last 30 days',
    this.series = const [],
    this.loaded = false,
  });

  final int? totalRequests;
  final int? totalTokens;
  final double? costUsd;
  final String periodLabel;

  /// (x,y) points for chart. If empty => placeholder.
  final List<Offset> series;

  final bool loaded;
}

class UsageEntry {
  UsageEntry({
    required this.providerModelDescription,
    required this.totalTokens,
    required this.createdAt,
    required this.latencyMs,
    required this.statusCode,
    required this.isForPdf,
    required this.attempts,
  });

  final String providerModelDescription;
  final int totalTokens;
  final DateTime createdAt;
  final int latencyMs;
  final int statusCode;
  final bool isForPdf;
  final int attempts;

  factory UsageEntry.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = json['created_at']?.toString();
    final createdAt = createdAtRaw == null
        ? DateTime.now()
        : DateTime.tryParse(createdAtRaw) ?? DateTime.now();

    return UsageEntry(
      providerModelDescription:
          (json['provider_model_description'] ?? 'Unknown').toString(),
      totalTokens: (json['total_tokens'] as num?)?.toInt() ?? 0,
      createdAt: createdAt,
      latencyMs: (json['latency_ms'] as num?)?.toInt() ?? 0,
      statusCode: (json['status_code'] as num?)?.toInt() ?? 0,
      isForPdf: json['is_for_pdf'] == true || json['is_for_pdf'] == 't',
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
    );
  }
}

class UsageDashboardData {
  UsageDashboardData({required this.entries, required this.periodLabel});

  final List<UsageEntry> entries;
  final String periodLabel;

  int get totalRequests => entries.length;
  int get totalTokens =>
      entries.fold<int>(0, (sum, entry) => sum + entry.totalTokens);
  double get avgLatencyMs => entries.isEmpty
      ? 0
      : entries.fold(0, (sum, entry) => sum + entry.latencyMs) / entries.length;
  double get avgAttempts => entries.isEmpty
      ? 0
      : entries.fold(0, (sum, entry) => sum + entry.attempts) / entries.length;
  int get pdfRequests =>
      entries.where((entry) => entry.isForPdf).toList().length;
  int get nonPdfRequests =>
      entries.where((entry) => !entry.isForPdf).toList().length;

  Map<int, int> get statusCounts {
    final counts = <int, int>{};
    for (final entry in entries) {
      counts.update(entry.statusCode, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts;
  }
}

/// Main Token screen state holder.
/// In production, you can replace this with your state management of choice.
class TokensController extends ChangeNotifier {
  TokensController() {
    // Demo data (safe placeholders). Replace with backend load.
    tokens = [];

    selectedTokenId = null;
  }

  Future<void> loadTokensFromBackend() async {
    final res = await certificationManager.getAllUserTokens();

    if (res.statusCode < 200 || res.statusCode >= 300) {
      // Optional: handle error UI/state
      debug('getAllUserTokens failed: ${res.statusCode} ${res.body}');
      return;
    }

    final decoded = jsonDecode(res.body);

    // Accept either:
    // 1) a List directly
    // 2) { "data": [ ... ] }
    final List<dynamic> list = decoded is List
        ? decoded
        : (decoded is Map<String, dynamic> && decoded['data'] is List
              ? decoded['data'] as List
              : const []);

    final loaded = list
        .whereType<Map<String, dynamic>>()
        .map(_tokenEntryFromJson)
        .toList();

    tokens = loaded;

    // Keep selection valid
    if (tokens.isEmpty) {
      selectedTokenId = null;
    } else {
      final stillExists =
          selectedTokenId != null && tokens.any((t) => t.id == selectedTokenId);

      // Prefer backend default token if present
      final defaultToken = tokens.where((t) => t.isDefault).toList();
      final defaultId = defaultToken.isNotEmpty ? defaultToken.first.id : null;

      selectedTokenId = stillExists
          ? selectedTokenId
          : (defaultId ?? tokens.first.id);
    }

    notifyListeners();
  }

  TokenEntry _tokenEntryFromJson(Map<String, dynamic> j) {
    // Adjust keys to match your backend response.
    final id = (j['id'] as num).toInt();

    final providerRaw = (j['provider'] ?? j['provider_name'] ?? '').toString();
    final provider = _parseProvider(providerRaw);

    final name = (j['token_name'] ?? j['name'] ?? provider.label).toString();

    // Prefer masked preview from backend. If backend returns only full key, mask it client-side.
    final keyPreview =
        (j['key_preview'] ?? j['masked'] ?? j['token_preview'])?.toString() ??
        '••••••••';

    final createdAtStr = (j['created_at'] ?? j['createdAt'])?.toString();
    final createdAt = createdAtStr == null
        ? DateTime.now()
        : DateTime.tryParse(createdAtStr) ?? DateTime.now();

    final isDefault = (j['is_default'] ?? j['isDefault']) == true;

    return TokenEntry(
      id: id,
      provider: provider,
      name: name,
      keyPreview: keyPreview,
      createdAt: createdAt,
      isDefault: isDefault,
    );
  }

  TokenProvider _parseProvider(String raw) {
    final s = raw.toLowerCase().trim();

    // Map backend strings to your enum
    if (s.contains('gemini') || s.contains('google'))
      return TokenProvider.gemini;
    if (s.contains('groq') || s.contains('grok')) return TokenProvider.groq;

    // fallback
    return TokenProvider.gemini;
  }

  late List<TokenEntry> tokens;
  int? selectedTokenId;

  CertificationManager certificationManager = CertificationManager();

  UsageSnapshot usage = UsageSnapshot(loaded: false, series: const []);
  List<UsageEntry> usageEntries = [];
  String? selectedUsageModel;
  DateTimeRange? selectedUsageRange;

  TokenEntry? get selectedToken {
    final id = selectedTokenId;
    if (id == null) return null;

    for (final t in tokens) {
      if (t.id == id) return t;
    }
    return null;
  }

  List<String> get availableUsageModels {
    final models = usageEntries
        .map((entry) => entry.providerModelDescription)
        .toSet()
        .toList();
    models.sort();
    return models;
  }

  void setUsageModel(String? model) {
    selectedUsageModel = model == 'All models' ? null : model;
    notifyListeners();
  }

  void setUsageRange(DateTimeRange? range) {
    selectedUsageRange = range;
    notifyListeners();
  }

  void selectToken(int id) {
    selectedTokenId = id;
    notifyListeners();
  }

  /// Stub: call backend to set default token, then update local state.
  Future<void> setDefaultById(int id) async {
    final token = tokens.where((t) => t.id == id).toList();
    if (token.isEmpty) return;

    final tokenName = token.first.name;

    final res = await certificationManager.setDefaultUserToken(tokenName);

    // Your API returns 202 on success
    if (res.statusCode != 202) {
      debug('setDefaultUserToken failed: ${res.statusCode} ${res.body}');
      return;
    }

    // Update local state
    for (final t in tokens) {
      t.isDefault = (t.id == id);
    }

    notifyListeners();
  }

  /// Stub: call backend to delete token.
  Future<void> deleteToken(String name) async {
    final res = await certificationManager.deleteUserToken(name);

    // If backend failed, do not mutate UI state (optional but recommended)
    if (res.statusCode < 200 || res.statusCode >= 300) {
      debug('deleteToken failed: ${res.statusCode} ${res.body}');
      return;
    }

    // Capture whether we are deleting the selected token
    final selected = selectedToken;

    // Remove all tokens with that name (name may not be unique; this matches your current design)
    tokens.removeWhere((t) => t.name == name);

    // If the selected token was deleted, select a new one safely
    final selectedWasDeleted = selected != null && selected.name == name;

    if (tokens.isEmpty) {
      selectedTokenId = null;
    } else if (selectedWasDeleted) {
      // Prefer default token, otherwise first token
      final defaultToken = tokens.where((t) => t.isDefault).toList();
      selectedTokenId = defaultToken.isNotEmpty
          ? defaultToken.first.id
          : tokens.first.id;
    } else {
      // Ensure current selectedTokenId still exists (defensive)
      final stillExists =
          selectedTokenId != null && tokens.any((t) => t.id == selectedTokenId);
      if (!stillExists) {
        selectedTokenId = tokens.first.id;
      }
    }

    notifyListeners();
  }

  /// Stub: call backend to create token.
  /// For security: you typically show full key ONCE in a modal,
  /// then store only masked preview and never show full key again.
  Future<void> createToken({
    required TokenProvider provider,
    required String name,
    required String apiKey,
    required bool isDefault,
  }) async {
    final response = await certificationManager.createUserToken(
      provider.labelSnakeCase,
      name,
      apiKey,
      isDefault,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      // Optional: show error snackbar
      return;
    }

    final resolvedName = name.trim().isEmpty ? provider.label : name.trim();

    final preview = _maskKey(apiKey);

    final existingIndex = tokens.indexWhere((t) => t.name == resolvedName);

    if (existingIndex != -1) {
      // 🔁 UPDATE EXISTING TOKEN (no duplication)
      final existing = tokens[existingIndex];

      tokens[existingIndex] = TokenEntry(
        id: existing.id, // keep backend ID
        provider: provider,
        name: resolvedName,
        keyPreview: preview,
        createdAt: existing.createdAt, // or DateTime.now() if you prefer
        isDefault: isDefault,
      );

      selectedTokenId = existing.id;
    } else {
      // ➕ CREATE NEW TOKEN (only when it truly does not exist)
      final newId = (tokens.isEmpty
          ? 100
          : tokens.map((e) => e.id).reduce(math.max) + 1);

      final entry = TokenEntry(
        id: newId,
        provider: provider,
        name: resolvedName,
        keyPreview: preview,
        createdAt: DateTime.now(),
        isDefault: isDefault,
      );

      tokens.insert(0, entry);
      selectedTokenId = entry.id;
    }

    // Enforce single default locally
    if (isDefault) {
      for (final t in tokens) {
        t.isDefault = (t.id == selectedTokenId);
      }
    }

    notifyListeners();
  }

  /// Stub: refresh usage dashboard from backend.
  Future<void> refreshUsage() async {
    final res = await certificationManager.getUserUsage(
      providerModelDescription: selectedUsageModel,
      startDate: selectedUsageRange?.start,
      endDate: selectedUsageRange?.end,
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      debug('getUserUsage failed: ${res.statusCode} ${res.body}');
      usage = UsageSnapshot(loaded: false, series: const []);
      notifyListeners();
      return;
    }

    final decoded = jsonDecode(utf8.decode(res.bodyBytes));
    final List<dynamic> list = decoded is List
        ? decoded
        : (decoded is Map<String, dynamic> && decoded['data'] is List
              ? decoded['data'] as List
              : const []);

    usageEntries = list
        .whereType<Map<String, dynamic>>()
        .map(UsageEntry.fromJson)
        .toList();

    usageEntries.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    usage = UsageSnapshot(
      loaded: true,
      periodLabel: _periodLabel(selectedUsageRange),
      totalRequests: usageEntries.length,
      totalTokens: usageEntries.fold<int>(
        0,
        (sum, entry) => sum + entry.totalTokens,
      ),
      series: _buildTokensSeries(usageEntries),
    );

    notifyListeners();
  }

  String _periodLabel(DateTimeRange? range) {
    if (range == null) return 'All time';
    final start = range.start;
    final end = range.end;
    return '${start.month}/${start.day}/${start.year} → ${end.month}/${end.day}/${end.year}';
  }

  List<Offset> _buildTokensSeries(List<UsageEntry> entries) {
    if (entries.isEmpty) return const [];
    final grouped = <DateTime, int>{};
    for (final entry in entries) {
      final key = DateTime(
        entry.createdAt.year,
        entry.createdAt.month,
        entry.createdAt.day,
      );
      grouped.update(
        key,
        (value) => value + entry.totalTokens,
        ifAbsent: () => entry.totalTokens,
      );
    }
    final days = grouped.keys.toList()..sort();
    return List.generate(days.length, (index) {
      final value = grouped[days[index]] ?? 0;
      return Offset(index.toDouble(), value.toDouble());
    });
  }

  List<Offset> buildLatencySeries(List<UsageEntry> entries) {
    if (entries.isEmpty) return const [];
    final grouped = <DateTime, List<int>>{};
    for (final entry in entries) {
      final key = DateTime(
        entry.createdAt.year,
        entry.createdAt.month,
        entry.createdAt.day,
      );
      grouped.putIfAbsent(key, () => []).add(entry.latencyMs);
    }
    final days = grouped.keys.toList()..sort();
    return List.generate(days.length, (index) {
      final values = grouped[days[index]] ?? const [];
      final avg = values.isEmpty
          ? 0
          : values.reduce((a, b) => a + b) / values.length;
      return Offset(index.toDouble(), avg.toDouble());
    });
  }

  static String _maskKey(String key) {
    final trimmed = key.trim();
    if (trimmed.length <= 8) return '••••••••';
    final tail = trimmed.substring(trimmed.length - 3);
    final head = trimmed.substring(0, math.min(3, trimmed.length));
    return '$head-•••••••••••••••••••$tail';
  }
}

/// Pure UI constants to keep the “Apple-like” feel.
class TokensUI {
  static const double radius = 18;
  static const double innerRadius = 14;

  static BoxDecoration cardDecoration(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: cs.onSurface.withOpacity(0.06)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static BoxDecoration subtlePanelDecoration(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return BoxDecoration(
      color: Colors.white.withOpacity(0.9),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: cs.onSurface.withOpacity(0.06)),
    );
  }
}

/// A single page widget that can be arranged in Desktop or Mobile layouts.
class TokensView extends StatefulWidget {
  const TokensView({super.key, required this.isDesktop});

  final bool isDesktop;

  @override
  State<TokensView> createState() => _TokensViewState();
}

class _TokensViewState extends State<TokensView> {
  late final TokensController controller;
  bool isDefault = false;

  @override
  void initState() {
    super.initState();
    controller = TokensController();
    controller.loadTokensFromBackend();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final header = _HeaderBar(
              isDesktop: widget.isDesktop,
              onCreate: () => _showCreateTokenDialog(context, controller),
              onRefreshUsage: () => controller.refreshUsage(),
              usagePeriodLabel: controller.usage.periodLabel,
            );

            final left = _TokensListPanel(controller: controller);
            final right = _UsageDashboardPanel(controller: controller);

            if (widget.isDesktop) {
              return Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    header,
                    const SizedBox(height: 18),
                    Expanded(
                      child: Row(
                        children: [
                          SizedBox(width: 460, child: left),
                          const SizedBox(width: 18),
                          Expanded(child: right),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                header,
                const SizedBox(height: 14),
                left,
                const SizedBox(height: 14),
                right,
                const SizedBox(height: 18),
                Text(
                  'Tip: For security, keys should be shown once at creation and then stored masked.',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.55),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

Future<void> _showCreateTokenDialog(
  BuildContext context,
  TokensController controller,
) async {
  final nameCtrl = TextEditingController();
  final keyCtrl = TextEditingController();
  TokenProvider selected = TokenProvider.gemini;

  bool isDefaultLocal = false;

  final cs = Theme.of(context).colorScheme;

  await showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setLocalState) {
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TokensUI.radius),
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              padding: const EdgeInsets.all(18),
              decoration: TokensUI.subtlePanelDecoration(context),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _DialogTitle(
                    title: 'Add API Key',
                    subtitle:
                        'Save a provider key to use for requests. The full key should be visible only once.',
                  ),
                  const SizedBox(height: 14),

                  DropdownButtonFormField<TokenProvider>(
                    value: selected,
                    items: TokenProvider.values.map((p) {
                      return DropdownMenuItem(value: p, child: Text(p.label));
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setLocalState(() => selected = v);
                      }
                    },
                    decoration: const InputDecoration(labelText: 'Provider'),
                  ),

                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Name (optional)',
                      hintText: 'e.g., Production, Staging, Personal',
                    ),
                  ),

                  const SizedBox(height: 12),
                  TextField(
                    controller: keyCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'API Key',
                      hintText: 'Paste your key here',
                    ),
                  ),

                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Is Default?'),
                    value: isDefaultLocal,
                    onChanged: (value) {
                      setLocalState(() => isDefaultLocal = value);
                    },
                  ),

                  const SizedBox(height: 18),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () async {
                          if (keyCtrl.text.trim().isEmpty) return;

                          await controller.createToken(
                            provider: selected,
                            name: nameCtrl.text,
                            apiKey: keyCtrl.text,
                            isDefault: isDefaultLocal,
                          );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('API key saved.'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: cs.onSurface.withOpacity(0.9),
                              ),
                            );
                            Navigator.of(context).pop();
                          }
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.isDesktop,
    required this.onCreate,
    required this.onRefreshUsage,
    required this.usagePeriodLabel,
  });

  final bool isDesktop;
  final VoidCallback onCreate;
  final VoidCallback onRefreshUsage;
  final String usagePeriodLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: TokensUI.cardDecoration(context),
      child: Row(
        children: [
          Icon(Icons.key_rounded, color: cs.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'API Keys',
                  style: TextStyle(
                    fontSize: isDesktop ? 18 : 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Manage providers, set a default key, and review usage.',
                  style: TextStyle(color: cs.onSurface.withOpacity(0.6)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.end,
            children: [
              if (isDesktop)
                _SubtleButton(
                  icon: Icons.refresh_rounded,
                  label: 'Refresh usage',
                  onTap: onRefreshUsage,
                ),
              ElevatedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create new key'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TokensListPanel extends StatelessWidget {
  const _TokensListPanel({required this.controller});
  final TokensController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: TokensUI.cardDecoration(context),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Your keys',
            subtitle: 'Select one to view usage and set default.',
          ),
          const SizedBox(height: 10),
          Expanded(
            child: controller.tokens.isEmpty
                ? _EmptyKeysState(
                    onCreate: () => _showCreateTokenDialog(context, controller),
                  )
                : ListView.separated(
                    itemCount: controller.tokens.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final t = controller.tokens[i];
                      final selected = controller.selectedTokenId == t.id;
                      return _TokenRow(
                        token: t,
                        selected: selected,
                        onSelect: () => controller.selectToken(t.id),
                        onSetDefault: () => controller.setDefaultById(t.id),
                        onDelete: () => controller.deleteToken(t.name),
                        onCopy: () {},
                      );
                    },
                  ),
          ),
          const SizedBox(height: 10),
          _FootnoteCard(
            text:
                'Keys are stored securely. For safety, show the full key only once at creation and then keep it masked.',
          ),
        ],
      ),
    );
  }
}

class _TokenRow extends StatelessWidget {
  const _TokenRow({
    required this.token,
    required this.selected,
    required this.onSelect,
    required this.onSetDefault,
    required this.onDelete,
    required this.onCopy,
  });

  final TokenEntry token;
  final bool selected;

  final VoidCallback onSelect;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final border = selected
        ? Border.all(color: cs.primary.withOpacity(0.35), width: 1.2)
        : Border.all(color: cs.onSurface.withOpacity(0.06));

    return InkWell(
      borderRadius: BorderRadius.circular(TokensUI.innerRadius),
      onTap: onSelect,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? cs.primary.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(TokensUI.innerRadius),
          border: border,
        ),
        child: Row(
          children: [
            _ProviderPill(provider: token.provider),
            const SizedBox(width: 10),
            Expanded(child: _TokenInfo(token: token)),
            const SizedBox(width: 10),
            IconButton(
              tooltip: token.isDefault ? 'Default key' : 'Set as default',
              onPressed: onSetDefault,
              icon: Icon(
                token.isDefault
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                color: token.isDefault
                    ? cs.primary
                    : cs.onSurface.withOpacity(0.45),
              ),
            ),
            // IconButton(
            //   tooltip: 'Copy',
            //   onPressed: onCopy,
            //   icon: Icon(
            //     Icons.copy_rounded,
            //     color: cs.onSurface.withOpacity(0.6),
            //   ),
            // ),
            IconButton(
              tooltip: 'Delete',
              onPressed: onDelete,
              icon: Icon(
                Icons.delete_outline_rounded,
                color: cs.error.withOpacity(0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TokenInfo extends StatelessWidget {
  const _TokenInfo({required this.token});
  final TokenEntry token;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    String dateLabel() {
      final d = token.createdAt;
      return '${d.year.toString().padLeft(4, '0')}-'
          '${d.month.toString().padLeft(2, '0')}-'
          '${d.day.toString().padLeft(2, '0')}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                token.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            if (token.isDefault)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: cs.primary.withOpacity(0.20)),
                ),
                child: Text(
                  'Default',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: cs.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          token.keyPreview,
          style: TextStyle(
            fontFamily: 'monospace',
            color: cs.onSurface.withOpacity(0.65),
          ),
        ),
        const SizedBox(height: 4),
        // Text(
        //   'Created $dateLabel() • ID ${token.id}',
        //   style: TextStyle(color: cs.onSurface.withOpacity(0.5), fontSize: 12),
        // ),
      ],
    );
  }
}

class _ProviderPill extends StatelessWidget {
  const _ProviderPill({required this.provider});
  final TokenProvider provider;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    IconData icon;
    switch (provider) {
      // case TokenProvider.openai:
      //   icon = Icons.auto_awesome_rounded;
      //   break;
      case TokenProvider.gemini:
        icon = Icons.bubble_chart_rounded;
        break;
      case TokenProvider.groq:
        icon = Icons.bolt_rounded;
        break;
      // case TokenProvider.custom:
      //   icon = Icons.extension_rounded;
      //   break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.onSurface.withOpacity(0.03),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.onSurface.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 6),
          Text(
            provider.label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _UsageDashboardPanel extends StatelessWidget {
  const _UsageDashboardPanel({required this.controller});
  final TokensController controller;

  bool get _showGlowingButton =>
      controller.tokens.isNotEmpty && controller.tokens.any((t) => t.isDefault);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selected = controller.selectedToken;
    final data = UsageDashboardData(
      entries: controller.usageEntries,
      periodLabel: controller.usage.periodLabel,
    );
    final latencySeries = controller.buildLatencySeries(data.entries);
    final statusCounts = data.statusCounts;
    final statusKeys = statusCounts.keys.toList()..sort();

    return Container(
      decoration: TokensUI.cardDecoration(context),
      padding: const EdgeInsets.all(14),
      child: Stack(
        children: [
          // Main content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(
                title: 'Usage dashboard',
                subtitle: selected == null
                    ? 'Select a key to view usage.'
                    : 'Provider: ${selected.provider.label} • Key: ${selected.name}',
              ),
              const SizedBox(height: 12),
              _UsageFilters(controller: controller),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 72),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _StatCard(
                            title: 'Requests',
                            value: controller.usage.loaded
                                ? '${data.totalRequests}'
                                : '—',
                            subtitle: data.periodLabel,
                            icon: Icons.swap_horiz_rounded,
                          ),
                          _StatCard(
                            title: 'Tokens',
                            value: controller.usage.loaded
                                ? '${data.totalTokens}'
                                : '—',
                            subtitle: data.periodLabel,
                            icon: Icons.data_usage_rounded,
                          ),
                          _StatCard(
                            title: 'Avg latency',
                            value: controller.usage.loaded
                                ? '${data.avgLatencyMs.toStringAsFixed(0)} ms'
                                : '—',
                            subtitle: data.periodLabel,
                            icon: Icons.speed,
                          ),
                          _StatCard(
                            title: 'Avg attempts',
                            value: controller.usage.loaded
                                ? data.avgAttempts.toStringAsFixed(1)
                                : '—',
                            subtitle: data.periodLabel,
                            icon: Icons.repeat_rounded,
                          ),
                          _StatCard(
                            title: 'PDF requests',
                            value: controller.usage.loaded
                                ? '${data.pdfRequests}'
                                : '—',
                            subtitle: data.periodLabel,
                            icon: Icons.picture_as_pdf,
                          ),
                          _StatCard(
                            title: 'Non-PDF requests',
                            value: controller.usage.loaded
                                ? '${data.nonPdfRequests}'
                                : '—',
                            subtitle: data.periodLabel,
                            icon: Icons.public,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _ChartCard(
                        title: 'Tokens over time',
                        child:
                            controller.usage.loaded &&
                                controller.usage.series.isNotEmpty
                            ? _UsageChart(series: controller.usage.series)
                            : _EmptyChartPlaceholder(
                                title: 'No token data yet',
                                subtitle:
                                    'Pick a date range and refresh to load usage.',
                              ),
                      ),
                      const SizedBox(height: 16),
                      _ChartCard(
                        title: 'Latency over time',
                        child:
                            controller.usage.loaded && latencySeries.isNotEmpty
                            ? _UsageChart(series: latencySeries)
                            : _EmptyChartPlaceholder(
                                title: 'No latency data yet',
                                subtitle:
                                    'Pick a date range and refresh to load usage.',
                              ),
                      ),
                      const SizedBox(height: 16),
                      _ChartCard(
                        title: 'Status codes',
                        child: controller.usage.loaded && statusKeys.isNotEmpty
                            ? Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: statusKeys
                                    .map(
                                      (code) => _MiniStatChip(
                                        label: '$code',
                                        value: '${statusCounts[code] ?? 0}',
                                      ),
                                    )
                                    .toList(),
                              )
                            : _EmptyChartPlaceholder(
                                title: 'No status data yet',
                                subtitle:
                                    'Pick a date range and refresh to load usage.',
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom-right glowing button (only when at least one default token exists)
          if (_showGlowingButton)
            Positioned(
              right: 6,
              bottom: 6,
              child: GlowingButton(
                icon: const Icon(Icons.play_lesson, color: Colors.white),
                text: Text("Continue"),
                onPressed: () => NavigationService.push(OnAttachmentScreen()),
              ),
            )
          else
            // Optional: show a small hint when button is hidden
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Add a default token to enable usage refresh.',
                  style: TextStyle(color: cs.onSurface.withOpacity(0.55)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UsageChart extends StatelessWidget {
  const _UsageChart({required this.series});
  final List<Offset> series;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LineChartPainter(
        series: series,
        lineColor: Theme.of(context).colorScheme.primary.withOpacity(0.85),
        gridColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _UsageFilters extends StatelessWidget {
  const _UsageFilters({required this.controller});

  final TokensController controller;

  @override
  Widget build(BuildContext context) {
    final models = controller.availableUsageModels;
    final selected = controller.selectedUsageModel;
    final range = controller.selectedUsageRange;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 240,
          child: DropdownButtonFormField<String>(
            value: selected ?? 'All models',
            items: [
              const DropdownMenuItem(
                value: 'All models',
                child: Text('All models'),
              ),
              ...models.map(
                (model) => DropdownMenuItem(
                  value: model,
                  child: Text(model, overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
            onChanged: (value) => controller.setUsageModel(value),
            decoration: const InputDecoration(
              labelText: 'Provider model',
              isDense: true,
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () async {
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2023),
              lastDate: DateTime.now(),
              initialDateRange: range,
            );
            if (picked != null) {
              controller.setUsageRange(picked);
            }
          },
          icon: const Icon(Icons.date_range),
          label: Text(
            range == null
                ? 'All time'
                : '${range.start.month}/${range.start.day} → ${range.end.month}/${range.end.day}',
          ),
        ),
        ElevatedButton.icon(
          onPressed: controller.refreshUsage,
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh'),
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.onSurface.withOpacity(0.02),
        borderRadius: BorderRadius.circular(TokensUI.innerRadius),
        border: Border.all(color: cs.onSurface.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          SizedBox(height: 160, child: child),
        ],
      ),
    );
  }
}

class _MiniStatChip extends StatelessWidget {
  const _MiniStatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: cs.onSurface.withOpacity(0.7))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.series,
    required this.lineColor,
    required this.gridColor,
  });

  final List<Offset> series;
  final Color lineColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty) return;

    // Grid
    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    const gridLines = 5;
    for (int i = 1; i < gridLines; i++) {
      final y = size.height * (i / gridLines);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Normalize series
    final xs = series.map((p) => p.dx).toList();
    final ys = series.map((p) => p.dy).toList();
    final minX = xs.reduce(math.min);
    final maxX = xs.reduce(math.max);
    final minY = ys.reduce(math.min);
    final maxY = ys.reduce(math.max);

    double nx(double x) => maxX == minX ? 0 : (x - minX) / (maxX - minX);
    double ny(double y) => maxY == minY ? 0.5 : (y - minY) / (maxY - minY);

    final path = Path();
    for (int i = 0; i < series.length; i++) {
      final p = series[i];
      final x = nx(p.dx) * size.width;
      final y = (1 - ny(p.dy)) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    // Soft fill
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..color = lineColor.withOpacity(0.10)
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.series != series ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor;
  }
}

class _EmptyChartPlaceholder extends StatelessWidget {
  const _EmptyChartPlaceholder({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart_rounded,
              size: 36,
              color: cs.onSurface.withOpacity(0.35),
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurface.withOpacity(0.55)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 340),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(TokensUI.innerRadius),
          border: Border.all(color: cs.onSurface.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: cs.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: cs.onSurface.withOpacity(0.6)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withOpacity(0.55),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(color: cs.onSurface.withOpacity(0.6))),
      ],
    );
  }
}

class _FootnoteCard extends StatelessWidget {
  const _FootnoteCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.onSurface.withOpacity(0.02),
        borderRadius: BorderRadius.circular(TokensUI.innerRadius),
        border: Border.all(color: cs.onSurface.withOpacity(0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: cs.onSurface.withOpacity(0.55),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: cs.onSurface.withOpacity(0.65)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubtleButton extends StatelessWidget {
  const _SubtleButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: cs.onSurface.withOpacity(0.03),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: cs.onSurface.withOpacity(0.06)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min, // IMPORTANT
            children: [
              Icon(icon, size: 18, color: cs.onSurface.withOpacity(0.7)),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogTitle extends StatelessWidget {
  const _DialogTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(subtitle, style: TextStyle(color: cs.onSurface.withOpacity(0.65))),
      ],
    );
  }
}

class _EmptyKeysState extends StatelessWidget {
  const _EmptyKeysState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cs.onSurface.withOpacity(0.02),
            borderRadius: BorderRadius.circular(TokensUI.innerRadius),
            border: Border.all(color: cs.onSurface.withOpacity(0.06)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // “Apple-ish” soft icon badge
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.primary.withOpacity(0.18)),
                ),
                child: Icon(
                  Icons.key_rounded,
                  size: 28,
                  color: cs.primary.withOpacity(0.90),
                ),
              ),
              const SizedBox(height: 14),

              Text(
                'No API Keys',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: cs.onSurface.withOpacity(0.92),
                ),
              ),
              const SizedBox(height: 6),

              Text(
                'Create your first key to start using providers and tracking usage.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  height: 1.35,
                  color: cs.onSurface.withOpacity(0.62),
                ),
              ),
              const SizedBox(height: 16),

              // Primary action
              SizedBox(
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    'Create new key',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Secondary hint row (subtle)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 16,
                    color: cs.onSurface.withOpacity(0.45),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'For security, the full key is shown once and then stored masked.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: cs.onSurface.withOpacity(0.52),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
