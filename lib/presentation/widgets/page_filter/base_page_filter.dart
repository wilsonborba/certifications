import 'dart:convert';
import 'dart:typed_data';
import 'package:accredit/domain/models/topic_identifications.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// ------------------------------------------------------------
/// Public API to plug into your existing service layer
/// ------------------------------------------------------------

typedef PdfInputFetcher = Future<PdfInputInfo> Function(String documentId);

PdfInputInfo parsePdfInputInfo(http.Response resp) {
  final jsonMap = json.decode(resp.body) as Map<String, dynamic>;
  final data = jsonMap['data'] as Map<String, dynamic>;
  final meta = data['metadata'] as Map<String, dynamic>;
  final pages = (meta['pages'] as num).toInt();
  return PdfInputInfo(pages: pages, pdfUrl: null);
}

/// ------------------------------------------------------------
/// BasePageFilter (reusable for Desktop & Mobile)
/// ------------------------------------------------------------

class BasePageFilter extends StatefulWidget {
  final String documentId;
  final Uint8List pdfBytes;
  final String fileName;

  final PdfInputFetcher fetcher;
  final void Function(Set<int> selectedPages) onContinue;

  final int maxRanges;
  final bool desktopLayout;

  const BasePageFilter({
    super.key,
    required this.documentId,
    required this.fetcher,
    required this.onContinue,
    this.maxRanges = 3,
    this.desktopLayout = true,
    required this.pdfBytes,
    required this.fileName,
  });

  @override
  State<BasePageFilter> createState() => _BasePageFilterState();
}

class _BasePageFilterState extends State<BasePageFilter> {
  int? _totalPages;
  bool _loading = true;
  String? _error;

  final List<_IntRange> _ranges = [];
  final Set<int> _individual = <int>{};

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final info = await widget.fetcher(widget.documentId);
      if (!mounted) return;
      setState(() {
        _totalPages = info.pages;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load PDF input.';
        _loading = false;
      });
    }
  }

  bool get _ready => !_loading && _error == null && (_totalPages ?? 0) > 0;

  Set<int> get _selectedPages {
    final sel = <int>{};
    for (final r in _ranges) {
      for (int p = r.start; p <= r.end; p++) {
        sel.add(p);
      }
    }
    sel.addAll(_individual);
    return sel;
  }

  List<int> get _availableIndividualPages {
    final tp = _totalPages ?? 0;
    if (tp == 0) return const [];
    final covered = <int>{};
    for (final r in _ranges) {
      for (int p = r.start; p <= r.end; p++) covered.add(p);
    }
    final out = <int>[];
    for (int p = 1; p <= tp; p++) {
      if (!covered.contains(p)) out.add(p);
    }
    return out;
  }

  _IntRange _clampRange(_IntRange r) {
    final tp = _totalPages ?? 0;
    int s = r.start.clamp(1, tp);
    int e = r.end.clamp(1, tp);
    if (e < s) {
      final t = s;
      s = e;
      e = t;
    }
    return _IntRange(s, e);
  }

  void _addRange() {
    if ((_totalPages ?? 0) == 0) return;
    if (_ranges.length >= widget.maxRanges) return;
    final tp = _totalPages!;
    var candidate = _IntRange(
      (tp / 4).round(),
      (tp / 4).round() + (tp / 10).clamp(1, 10).toInt(),
    );
    candidate = _clampRange(candidate);

    if (_overlapsAny(candidate)) {
      candidate = _clampRange(_IntRange(1, (tp >= 5) ? 5 : tp));
    }
    setState(() {
      _ranges.add(candidate);
      _individual.removeWhere((p) => candidate.contains(p));
    });
  }

  bool _overlapsAny(_IntRange r) => _ranges.any((o) => o != r && o.overlaps(r));

  void _removeLastRange() {
    if (_ranges.isEmpty) return;
    setState(() {
      _ranges.removeLast();
    });
  }

  void _updateRange(int index, _IntRange next) {
    if (index < 0 || index >= _ranges.length) return;
    next = _clampRange(next);

    for (int i = 0; i < _ranges.length; i++) {
      if (i == index) continue;
      final other = _ranges[i];
      if (next.overlaps(other)) {
        if (next.center <= other.center) {
          next = _IntRange(next.start, other.start - 1);
        } else {
          next = _IntRange(other.end + 1, next.end);
        }
        next = _clampRange(next);
      }
    }

    setState(() {
      _ranges[index] = next;
      for (final r in _ranges) {
        _individual.removeWhere((p) => r.contains(p));
      }
    });
  }

  void _toggleIndividual(int p) {
    final allowed = _availableIndividualPages.contains(p);
    if (!allowed) return;
    setState(() {
      if (_individual.contains(p)) {
        _individual.remove(p);
      } else {
        _individual.add(p);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null || !_ready) {
      return Scaffold(
        body: Center(
          child: Text(
            _error ?? 'Unable to load PDF.',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    final selected = _selectedPages;

    return _ScaffoldShell(
      desktop: widget.desktopLayout,
      title: _TitleRow(
        desktop: widget.desktopLayout,
        total: _totalPages!,
        selected: selected.length, // 👈 add this
      ),
      left: _LeftSelectors(
        totalPages: _totalPages!,
        ranges: _ranges,
        onAddRange: _addRange,
        onRemoveRange: _removeLastRange,
        onRangeChanged: _updateRange,
        individualChoices: _availableIndividualPages,
        selectedIndividuals: _individual,
        onToggleIndividual: _toggleIndividual,
      ),
      // ✅ Here's the actual PDF viewer using memory bytes:
      right: Center(
        child: SizedBox(
          width: 500,
          height: 600,
          child: SfPdfViewer.memory(widget.pdfBytes),
        ),
      ),
      rightFooter: _ContinueButton(
        enabled: selected.isNotEmpty,
        onPressed: () => widget.onContinue(selected),
      ),
    );
  }
}

class _IntRange {
  final int start;
  final int end;
  const _IntRange(this.start, this.end);
  bool contains(int p) => p >= start && p <= end;
  bool overlaps(_IntRange other) => !(end < other.start || start > other.end);
  double get center => (start + end) / 2.0;
}

/// ------------------------ UI atoms ------------------------

class _TitleRow extends StatelessWidget {
  final int total;
  final int selected;
  final bool desktop;

  const _TitleRow({
    Key? key,
    required this.total,
    required this.selected,
    required this.desktop,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : (selected / total).clamp(0.0, 1.0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(width: 8),
        // Image.asset(
        //   'lib/presentation/assets/img/book.png',
        //   fit: BoxFit.contain,
        //   height: 200,
        // ),
        const SizedBox(width: 12),
        desktop
            ? Text(
                'Select pages',
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.w800),
              )
            : Text(
                'Select pages',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
              ),
        const Spacer(),

        // --- Pretty, visible counter badge ---
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(
                  context,
                ).colorScheme.primary.withAlpha((.90 * 255).toInt()),
                Theme.of(
                  context,
                ).colorScheme.primary.withAlpha((.75 * 255).toInt()),
              ],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Selected',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, .20),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: Text(
                      '$selected / $total',
                      key: ValueKey<int>(selected),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // tiny progress bar
              SizedBox(
                width: 160,
                height: 6,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: ratio,
                    backgroundColor: Colors.white.withAlpha(
                      (.25 * 255).toInt(),
                    ),
                    color: Colors.white,
                    minHeight: 6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScaffoldShell extends StatelessWidget {
  final bool desktop;
  final Widget title;
  final Widget left;
  final Widget right;
  final Widget rightFooter;

  const _ScaffoldShell({
    required this.desktop,
    required this.title,
    required this.left,
    required this.right,
    required this.rightFooter,
  });

  @override
  Widget build(BuildContext context) {
    if (desktop) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          backgroundColor: const Color(0xFF242424),
        ),
        backgroundColor: const Color(0xFFF7F7F7),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                title,
                const SizedBox(height: 12),
                const SizedBox(height: 12),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 7,
                        child: SingleChildScrollView(child: left),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 8,
                        child: Column(
                          children: [
                            Expanded(child: right),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: rightFooter,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            title,
            const SizedBox(height: 12),

            const SizedBox(height: 12),
            left,
            const SizedBox(height: 16),
            SizedBox(height: 340, child: right),
            const SizedBox(height: 12),
            Align(alignment: Alignment.centerRight, child: rightFooter),
          ],
        ),
      ),
    );
  }
}

class _LeftSelectors extends StatelessWidget {
  final int totalPages;
  final List<_IntRange> ranges;
  final VoidCallback onAddRange;
  final VoidCallback onRemoveRange;
  final void Function(int index, _IntRange next) onRangeChanged;
  final List<int> individualChoices;
  final Set<int> selectedIndividuals;
  final void Function(int p) onToggleIndividual;

  const _LeftSelectors({
    required this.totalPages,
    required this.ranges,
    required this.onAddRange,
    required this.onRemoveRange,
    required this.onRangeChanged,
    required this.individualChoices,
    required this.selectedIndividuals,
    required this.onToggleIndividual,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Opacity(
          opacity: 0.4,
          child: Row(
            children: [
              Checkbox(value: false, onChanged: null),
              SizedBox(width: 6),
              Text('Select All', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        Row(
          children: [
            Text(
              'Ranges',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            _RoundIconButton(icon: Icons.add, onTap: onAddRange),
            const SizedBox(width: 8),
            _RoundIconButton(
              icon: Icons.remove,
              onTap: ranges.isEmpty ? null : onRemoveRange,
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (int i = 0; i < ranges.length; i++) ...[
          _RangeTile(
            totalPages: totalPages,
            range: ranges[i],
            onChange: (r) => onRangeChanged(i, r),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 12),
        Text(
          'Individual pages',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        _PageBoxes(
          pages: individualChoices,
          selected: selectedIndividuals,
          onToggle: onToggleIndividual,
        ),
      ],
    );
  }
}

class _RangeTile extends StatelessWidget {
  final int totalPages;
  final _IntRange range;
  final void Function(_IntRange) onChange;

  const _RangeTile({
    required this.totalPages,
    required this.range,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final divisions = (totalPages - 1).clamp(1, 10000);
    final start = range.start.toDouble();
    final end = range.end.toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RangeSlider(
          values: RangeValues(start, end),
          min: 1,
          max: totalPages.toDouble(),
          divisions: divisions,
          labels: RangeLabels('${range.start}', '${range.end}'),
          onChanged: (v) {
            final s = v.start.round();
            final e = v.end.round();
            onChange(_IntRange(s, e));
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${range.start}-${range.end}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Text(
              '1–$totalPages',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}

class _PageBoxes extends StatelessWidget {
  final List<int> pages;
  final Set<int> selected;
  final void Function(int) onToggle;

  const _PageBoxes({
    required this.pages,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (pages.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: _boxDecoration(context),
        alignment: Alignment.center,
        child: const Text(
          'No remaining pages',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: _boxDecoration(context),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final p in pages)
            ChoiceChip(
              label: Text('$p'),
              selected: selected.contains(p),
              onSelected: (_) => onToggle(p),
              showCheckmark: false,
              labelStyle: TextStyle(
                color: selected.contains(p) ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
              selectedColor: Theme.of(context).colorScheme.primary,
              side: const BorderSide(color: Color(0xFFBDBDBD)),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
        ],
      ),
    );
  }

  BoxDecoration _boxDecoration(BuildContext context) => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: const Color(0xFFE0E0E0)),
    boxShadow: const [
      BoxShadow(
        blurRadius: 10,
        spreadRadius: 1,
        offset: Offset(0, 2),
        color: Color(0x11000000),
      ),
    ],
  );
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _RoundIconButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Ink(
      decoration: BoxDecoration(
        color: onTap == null ? Colors.black12 : Colors.white,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18, color: Colors.black87),
        ),
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;
  const _ContinueButton({required this.enabled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: const Icon(Icons.double_arrow_rounded),
      label: const Text('Continue'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: const StadiumBorder(),
      ),
    );
  }
}
