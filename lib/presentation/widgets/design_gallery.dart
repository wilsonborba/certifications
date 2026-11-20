// certifications#52: the design system on one page, for review. It is not a
// route of the app: run it with `flutter run -d chrome -t lib/design_gallery.dart`.
import 'package:certifications/core/utils/my_background.dart';
import 'package:certifications/core/utils/my_theme.dart';
import 'package:flutter/material.dart';

const logoAsset = 'lib/presentation/assets/img/temp_logo.png';

class DesignGallery extends StatefulWidget {
  const DesignGallery({super.key, this.initialMode = ThemeMode.light});

  final ThemeMode initialMode;

  @override
  State<DesignGallery> createState() => _DesignGalleryState();
}

class _DesignGalleryState extends State<DesignGallery> {
  late ThemeMode _mode = widget.initialMode;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Certifications',
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    themeMode: _mode,
    home: _GalleryPage(
      dark: _mode == ThemeMode.dark,
      onDark: (dark) =>
          setState(() => _mode = dark ? ThemeMode.dark : ThemeMode.light),
    ),
  );
}

class _GalleryPage extends StatefulWidget {
  const _GalleryPage({required this.dark, required this.onDark});

  final bool dark;
  final ValueChanged<bool> onDark;

  @override
  State<_GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<_GalleryPage> {
  bool _switch = true;
  bool _checked = true;
  String _segment = 'Easy';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final cs = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 24,
        title: Row(
          children: [
            Image.asset(logoAsset, width: 32, height: 32),
            const SizedBox(width: 12),
            const Text('Certifications'),
          ],
        ),
        actions: [
          Text('Dark', style: text.bodyMedium),
          const SizedBox(width: 8),
          Switch(value: widget.dark, onChanged: widget.onDark),
          const SizedBox(width: 24),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _Section(
            title: 'Moving bubbles',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              child: SizedBox(
                height: 280,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const LiquidMetalBackground(seed: 7),
                    Center(
                      child: Text(
                        'Certifications',
                        style: text.displaySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _Section(
            title: 'Type: Ubuntu Sans, Thai in IBM Plex Sans Thai',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Display small', style: text.displaySmall),
                Text('Headline medium', style: text.headlineMedium),
                Text('Title large', style: text.titleLarge),
                Text(
                  'Body large: create a quiz from your sources.',
                  style: text.bodyLarge,
                ),
                Text(
                  'Corpo: crie um quiz a partir das suas fontes.',
                  style: text.bodyLarge,
                ),
                Text(
                  'เนื้อหา: สร้างแบบทดสอบจากแหล่งข้อมูลของคุณ',
                  style: text.bodyLarge,
                ),
                Text(
                  'Body small, secondary',
                  style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          _Section(
            title: 'Colour tokens (Nova)',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final (name, color) in [
                  ('primary', cs.primary),
                  ('on primary', cs.onPrimary),
                  ('surface', cs.surface),
                  ('surface 2', cs.surfaceContainerLow),
                  ('surface 3', cs.surfaceContainerHighest),
                  ('text', cs.onSurface),
                  ('text subtle', cs.onSurfaceVariant),
                  ('error', cs.error),
                ])
                  _Swatch(name: name, color: color),
              ],
            ),
          ),
          _Section(
            title: 'Components',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilledButton(
                      onPressed: () {},
                      child: const Text('Create quiz'),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Start'),
                    ),
                    OutlinedButton(
                      onPressed: () {},
                      child: const Text('Preview'),
                    ),
                    TextButton(onPressed: () {}, child: const Text('Cancel')),
                    const FilledButton(
                      onPressed: null,
                      child: Text('Disabled'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final (label, bg, fg) in const [
                      (
                        'Published',
                        NovaColors.positiveSurface,
                        NovaColors.positiveText,
                      ),
                      (
                        'Queued',
                        NovaColors.warningSurface,
                        NovaColors.warningText,
                      ),
                      (
                        'Failed',
                        NovaColors.negativeSurface,
                        NovaColors.negativeText,
                      ),
                      ('Draft', NovaColors.infoSurface, NovaColors.infoText),
                    ])
                      Chip(
                        label: Text(label),
                        backgroundColor: bg,
                        labelStyle: TextStyle(color: fg),
                        side: BorderSide.none,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                const SizedBox(
                  width: 360,
                  child: TextField(
                    decoration: InputDecoration(labelText: 'Study name'),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 420,
                  child: CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('Show explanations after each answer'),
                    value: _checked,
                    onChanged: (v) => setState(() => _checked = v ?? false),
                  ),
                ),
                SizedBox(
                  width: 420,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Public in the catalog'),
                    value: _switch,
                    onChanged: (v) => setState(() => _switch = v),
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'Easy', label: Text('Easy')),
                    ButtonSegment(value: 'Basic', label: Text('Basic')),
                  ],
                  selected: {_segment},
                  onSelectionChanged: (s) => setState(() => _segment = s.first),
                ),
                const SizedBox(height: 16),
                const SizedBox(
                  width: 360,
                  child: LinearProgressIndicator(value: .6),
                ),
                const SizedBox(height: 16),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('A plain card, no blur or glass.'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 32),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: 88,
          height: 56,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            border: Border.all(color: cs.outline),
          ),
        ),
        const SizedBox(height: 4),
        Text(name, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
