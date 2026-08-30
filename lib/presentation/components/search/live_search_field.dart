import 'package:flutter/material.dart';

/// Premium-styled, live/autocomplete-as-you-type search field: filtering
/// happens on every keystroke via [onChanged], with no submit step. Shared
/// by the standby studies list (#32), the completed quizzes list (#33) and
/// the Certificates tab's Public/Private sub-tabs (#39) so all four live
/// searches look and behave identically.
class LiveSearchField extends StatefulWidget {
  const LiveSearchField({
    super.key,
    required this.hintText,
    required this.onChanged,
  });

  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  State<LiveSearchField> createState() => _LiveSearchFieldState();
}

class _LiveSearchFieldState extends State<LiveSearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (context, value, _) {
        return TextField(
          controller: _controller,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixIcon: Icon(
              Icons.search,
              color: scheme.onSurface.withValues(alpha: 0.5),
            ),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      _controller.clear();
                      widget.onChanged('');
                    },
                  ),
            filled: true,
            fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.25)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.25)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: scheme.primary, width: 1.6),
            ),
          ),
        );
      },
    );
  }
}
