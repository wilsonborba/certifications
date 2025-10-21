import 'package:flutter/material.dart';

/// Drop this widget anywhere (e.g., inside a Column).
/// When clicked, it opens a popup that asks for a website link.
/// If the user submits a valid http/https URL, the dialog closes
/// and calls [onRequest] with the URL.
class WantText extends StatefulWidget {
  const WantText({
    Key? key,
    this.onRequest,
    this.purple = const Color(0xFF7C4DFF), // main purple color
  }) : super(key: key);

  /// Called with the valid URL after the user presses "Request".
  final ValueChanged<String>? onRequest;

  /// Main accent color (purple by default).
  final Color purple;

  @override
  State<WantText> createState() => _WantTextState();
}

class _WantTextState extends State<WantText> {
  bool _hovering = false;

  Future<void> _openDialog() async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: true, // clicking outside closes the popup
      builder: (ctx) => _LinkRequestDialog(purple: widget.purple),
    );

    if (result != null && result.isNotEmpty) {
      widget.onRequest?.call(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.titleMedium ??
        const TextStyle(fontSize: 18);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit:  (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: _openDialog,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 150),
          scale: _hovering ? 1.05 : 1.0,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 150),
            style: baseStyle.copyWith(
              color: _hovering ? Colors.grey : Colors.black,
              // decoration: _hovering ? TextDecoration.underline : TextDecoration.none,
              fontWeight: _hovering ? FontWeight.w700 : FontWeight.w600,
            ),
            child: const Text('What i want is not here!'),
          ),
        ),
      ),
    );
  }
}

/// Internal dialog widget.
/// White theme, purple accents, responsive width, corner close button,
/// validates only http/https URLs and enables Request accordingly.
class _LinkRequestDialog extends StatefulWidget {
  const _LinkRequestDialog({required this.purple});

  final Color purple;

  @override
  State<_LinkRequestDialog> createState() => _LinkRequestDialogState();
}

class _LinkRequestDialogState extends State<_LinkRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    final ok = _validateUrl(_controller.text);
    if (ok != _isValid) {
      setState(() {
        _isValid = ok;
      });
    }
  }

  bool _validateUrl(String input) {
  final trimmed = input.trim();

  // Basic sanity check
  if (trimmed.isEmpty) return false;

  // Regex pattern for a valid website URL
  final pattern = r'^(https?:\/\/)' // must start with http:// or https://
      r'(([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,})' // domain name (example.com)
      r'(:\d+)?' // optional port
      r'(\/[^\s]*)?$'; // optional path/query/etc.

  final regex = RegExp(pattern);

  return regex.hasMatch(trimmed);
}


  void _submit() {
    if (_isValid) {
      Navigator.of(context).pop(_controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    // White theme surface with purple main color
    final base = Theme.of(context);
    final dialogTheme = base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: widget.purple,
        secondary: widget.purple,
        surface: Colors.white,
        onSurface: Colors.black87,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFFF7F7F7),
        border: OutlineInputBorder(),
      ),
    );

    return Theme(
      data: dialogTheme,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive width: up to 480 on desktop, ~90% on small screens
          final screenWidth = MediaQuery.of(context).size.width;
          final maxWidth = screenWidth < 520 ? screenWidth * 0.9 : 480.0;

          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
                // Height will wrap content naturally
              ),
              child: Stack(
                children: [
                  // Close button in the top-right corner
                  Positioned(
                    top: 6,
                    right: 6,
                    child: IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close),
                      color: Colors.black54,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20 + 36, 20, 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Request a link',
                            style: base.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _controller,
                            autofocus: true,
                            keyboardType: TextInputType.url,
                            decoration: const InputDecoration(
                              labelText: 'Website URL',
                              hintText: 'https://example.com',
                            ),
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a URL';
                              }
                              return _validateUrl(value)
                                  ? null
                                  : 'Enter a valid http:// or https:// URL';
                            },
                            onFieldSubmitted: (_) => _submit(),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isValid
                                        ? widget.purple
                                        : Colors.grey.shade300,
                                    foregroundColor:
                                        _isValid ? Colors.white : Colors.black45,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: _isValid ? 2 : 0,
                                  ),
                                  onPressed: _isValid ? _submit : null,
                                  child: const Text('Request'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Only links starting with http:// or https:// are accepted.',
                            style: base.textTheme.bodySmall?.copyWith(
                              color: Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
