import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tap-able subtle link (Apple-ish). Opens a glassy dialog asking for a URL.
/// On valid submit, calls [onRequest] with the URL and shows a brief success.
class WantText extends StatefulWidget {
  const WantText({
    Key? key,
    this.onRequest,
    this.purple = const Color(0xFF7C4DFF),
    this.label = 'Want another app? Click here!',
  }) : super(key: key);

  final ValueChanged<String>? onRequest;
  final Color purple;
  final String label;

  @override
  State<WantText> createState() => _WantTextState();
}

class _WantTextState extends State<WantText> {
  bool _hover = false;

  Future<void> _openDialog() async {
    final result = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: Colors.black.withAlpha((0.18 * 255).toInt()),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, __, ___) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16 * anim.value, sigmaY: 16 * anim.value),
          child: Opacity(
            opacity: anim.value,
            child: Center(
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.98, end: 1.0).animate(curved),
                child: _LinkRequestDialog(purple: widget.purple),
              ),
            ),
          ),
        );
      },
    );
    if (result != null && result.isNotEmpty) {
      widget.onRequest?.call(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.titleMedium ?? const TextStyle(fontSize: 16);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: _openDialog,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: (_hover
                    ? Colors.black.withAlpha((0.05 * 255).toInt())
                    : Colors.black.withAlpha((0.03 * 255).toInt())),
            border: Border.all(
              color: Colors.black.withAlpha((0.08 * 255).toInt()),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_circle_outline,
                  size: 18,
                  color: _hover ? widget.purple : Colors.black.withAlpha((0.7 * 255).toInt())),
              const SizedBox(width: 8),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 160),
                style: base.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _hover ? widget.purple : Colors.black87,
                ),
                child: Text(widget.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Glassy, simple request dialog. Validates http/https.
/// Success state shows for ~2s then pops with the url as result.
class _LinkRequestDialog extends StatefulWidget {
  const _LinkRequestDialog({required this.purple});
  final Color purple;

  @override
  State<_LinkRequestDialog> createState() => _LinkRequestDialogState();
}

class _LinkRequestDialogState extends State<_LinkRequestDialog> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  bool _valid = false;
  bool _success = false;
  String? _finalUrl;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged() {
    final v = _controller.text.trim();
    final ok = _isValidUrl(v);
    if (ok != _valid) setState(() => _valid = ok);
  }

  bool _isValidUrl(String v) {
    if (v.isEmpty) return false;
    final uri = Uri.tryParse(v);
    if (uri == null) return false;
    final schemeOk = uri.scheme == 'http' || uri.scheme == 'https';
    final hostOk = (uri.host).isNotEmpty && uri.host.contains('.');
    return schemeOk && hostOk;
  }

  void _submit() {
    final v = _controller.text.trim();
    if (!_isValidUrl(v)) return;
    HapticFeedback.lightImpact();
    setState(() {
      _success = true;
      _finalUrl = v;
    });
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) Navigator.of(context).pop(_finalUrl);
    });
  }

  @override
  Widget build(BuildContext context) {
    final radius = 18.0;
    final insets = MediaQuery.of(context).viewInsets;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: insets.bottom + 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            color: Colors.white.withAlpha((0.68 * 255).toInt()),
            border: Border.all(color: Colors.white.withAlpha((0.75 * 255).toInt()), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha((0.08 * 255).toInt()),
                blurRadius: 26,
                spreadRadius: 2,
                offset: const Offset(0, 14),
              ),
            ],
            gradient: LinearGradient(
              colors: [
                Colors.white.withAlpha((0.74 * 255).toInt()),
                Colors.white.withAlpha((0.60 * 255).toInt()),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _success
                      ? _SuccessBox(url: _finalUrl ?? '', purple: widget.purple)
                      : _FormBox(
                          controller: _controller,
                          focusNode: _focus,
                          valid: _valid,
                          purple: widget.purple,
                          onSubmit: _submit,
                          onClose: () => Navigator.of(context).maybePop(),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormBox extends StatelessWidget {
  const _FormBox({
    required this.controller,
    required this.focusNode,
    required this.valid,
    required this.purple,
    required this.onSubmit,
    required this.onClose,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool valid;
  final Color purple;
  final VoidCallback onSubmit;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return Column(
      key: const ValueKey('form'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Request a link',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black87),
            ),
            IconButton(
              tooltip: 'Close',
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // field
        TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: true,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSubmit(),
          decoration: InputDecoration(
            labelText: 'Website URL',
            hintText: 'https://example.com',
            filled: true,
            fillColor: Colors.white.withAlpha((0.72 * 255).toInt()),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.black.withAlpha((0.08 * 255).toInt())),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: purple, width: 2),
            ),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(
                valid ? Icons.check_circle : Icons.link_outlined,
                color: valid ? Colors.green : Colors.black54,
              ),
            ),
            suffixIconConstraints: const BoxConstraints(minHeight: 40, minWidth: 40),
          ),
        ),

        const SizedBox(height: 12),

        // action
        SizedBox(
          height: 44,
          child: FilledButton(
            onPressed: valid ? onSubmit : null,
            style: FilledButton.styleFrom(
              backgroundColor: valid ? purple : Colors.grey.withAlpha((0.30 * 255).toInt()),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: valid ? 1.5 : 0,
            ),
            child: const Text('Request', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),

        const SizedBox(height: 6),
        Text(
          'Only links starting with http:// or https:// are accepted.',
          style: t.textTheme.bodySmall?.copyWith(color: Colors.black54),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _SuccessBox extends StatelessWidget {
  const _SuccessBox({required this.url, required this.purple});
  final String url;
  final Color purple;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Column(
      key: const ValueKey('success'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 86,
          width: 86,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Colors.green.withAlpha((0.20 * 255).toInt()), Colors.green.withAlpha((0.45 * 255).toInt())],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withAlpha((0.22 * 255).toInt()),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 48),
        ),
        const SizedBox(height: 12),
        Text(
          'Request received',
          style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: Colors.black87),
        ),
        const SizedBox(height: 6),
        Text(
          url,
          textAlign: TextAlign.center,
          style: t.textTheme.bodySmall?.copyWith(color: Colors.black87),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
