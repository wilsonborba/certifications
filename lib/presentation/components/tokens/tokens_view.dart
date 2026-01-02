import 'dart:math' as math;
import 'package:accredit/domain/services/api_certification_manager.dart';
import 'package:flutter/material.dart';

/// Represents a provider option (Grok/Gemini/OpenAI etc.)
enum TokenProvider {
  //openai('ChatGPT / OpenAI'),
  gemini('Google Gemini'),
  groq('Groq (groq.com)');

  const TokenProvider(this.label);
  final String label;
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

/// Main Token screen state holder.
/// In production, you can replace this with your state management of choice.
class TokensController extends ChangeNotifier {
  TokensController() {
    // Demo data (safe placeholders). Replace with backend load.
    tokens = [
      TokenEntry(
        id: 126,
        provider: TokenProvider.gemini,
        name: 'Gemini test',
        keyPreview: 'gm-•••••••••••••••••••3Qp',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      TokenEntry(
        id: 127,
        provider: TokenProvider.groq,
        name: 'Grok staging',
        keyPreview: 'xai-•••••••••••••••••••A1m',
        createdAt: DateTime.now().subtract(const Duration(days: 18)),
      ),
    ];

    selectedTokenId = tokens.first.id;
  }

  late List<TokenEntry> tokens;
  int? selectedTokenId;

  CertificationManager certificationManager = CertificationManager();

  UsageSnapshot usage = UsageSnapshot(loaded: false, series: const []);

  TokenEntry? get selectedToken {
    if (selectedTokenId == null) return null;
    return tokens
        .where((t) => t.id == selectedTokenId)
        .cast<TokenEntry?>()
        .first;
  }

  void selectToken(int id) {
    selectedTokenId = id;
    notifyListeners();
  }

  /// Stub: call backend to set default token, then update local state.
  Future<void> setDefault(int id) async {
    for (final t in tokens) {
      t.isDefault = (t.id == id);
    }
    notifyListeners();
  }

  /// Stub: call backend to delete token.
  Future<void> deleteToken(int id) async {
    tokens.removeWhere((t) => t.id == id);
    if (selectedTokenId == id) {
      selectedTokenId = tokens.isEmpty ? null : tokens.first.id;
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
      provider.label,
      name,
      apiKey,
      isDefault,
    );

    final newId = (tokens.isEmpty
        ? 100
        : tokens.map((e) => e.id).reduce(math.max) + 1);

    final preview = _maskKey(apiKey);
    final entry = TokenEntry(
      id: newId,
      provider: provider,
      name: name.trim().isEmpty ? provider.label : name.trim(),
      keyPreview: preview,
      createdAt: DateTime.now(),
      isDefault: isDefault,
    );

    if (entry.isDefault) {
      for (final t in tokens) t.isDefault = false;
    }

    tokens.insert(0, entry);
    selectedTokenId = entry.id;
    notifyListeners();
  }

  /// Stub: refresh usage dashboard from backend.
  Future<void> refreshUsage() async {
    // Placeholder "loaded" usage with fake series; replace with real data.
    usage = UsageSnapshot(
      loaded: true,
      periodLabel: 'Last 7 days',
      totalRequests: 104400,
      totalTokens: 880000,
      costUsd: 49.00,
      series: List.generate(24, (i) {
        final x = i.toDouble();
        final y = 20 + 15 * math.sin(i / 3) + (i % 7) * 1.2;
        return Offset(x, y.toDouble());
      }),
    );
    notifyListeners();
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
              onCreate: () => _showCreateTokenDialog(context),
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

  Future<void> _showCreateTokenDialog(BuildContext context) async {
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
                                  backgroundColor: cs.onSurface.withOpacity(
                                    0.9,
                                  ),
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
            child: ListView.separated(
              itemCount: controller.tokens.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final t = controller.tokens[i];
                final selected = controller.selectedTokenId == t.id;
                return _TokenRow(
                  token: t,
                  selected: selected,
                  onSelect: () => controller.selectToken(t.id),
                  onSetDefault: () => controller.setDefault(t.id),
                  onDelete: () => controller.deleteToken(t.id),
                  onCopy: () {
                    // Placeholder: wire to clipboard later.
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copy action (wire to clipboard)'),
                      ),
                    );
                  },
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selected = controller.selectedToken;

    return Container(
      decoration: TokensUI.cardDecoration(context),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: 'Usage dashboard',
            subtitle: selected == null
                ? 'Select a key to view usage.'
                : 'Provider: ${selected.provider.label} • Key: ${selected.name}',
          ),
          const SizedBox(height: 12),

          // Stats row
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _StatCard(
                title: 'Requests',
                value: controller.usage.loaded
                    ? '${controller.usage.totalRequests ?? 0}'
                    : '—',
                subtitle: controller.usage.periodLabel,
                icon: Icons.swap_horiz_rounded,
              ),
              _StatCard(
                title: 'Tokens',
                value: controller.usage.loaded
                    ? '${controller.usage.totalTokens ?? 0}'
                    : '—',
                subtitle: controller.usage.periodLabel,
                icon: Icons.data_usage_rounded,
              ),
              _StatCard(
                title: 'Cost',
                value: controller.usage.loaded
                    ? '\$${(controller.usage.costUsd ?? 0).toStringAsFixed(2)}'
                    : '—',
                subtitle: controller.usage.periodLabel,
                icon: Icons.payments_rounded,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Chart
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.onSurface.withOpacity(0.02),
                borderRadius: BorderRadius.circular(TokensUI.innerRadius),
                border: Border.all(color: cs.onSurface.withOpacity(0.06)),
              ),
              child:
                  controller.usage.loaded && controller.usage.series.isNotEmpty
                  ? _UsageChart(series: controller.usage.series)
                  : _EmptyChartPlaceholder(
                      title: 'Usage chart not loaded',
                      subtitle:
                          'Press “Refresh usage” to fetch usage metrics from your backend.',
                    ),
            ),
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              _SubtleButton(
                icon: Icons.refresh_rounded,
                label: 'Refresh usage',
                onTap: () => controller.refreshUsage(),
              ),
              const SizedBox(width: 10),
              Text(
                'Backend not connected yet.',
                style: TextStyle(color: cs.onSurface.withOpacity(0.55)),
              ),
            ],
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
