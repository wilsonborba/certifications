import 'package:certifications/core/utils/app_localizations.dart';
import 'package:certifications/core/utils/my_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The landing of Certifications (certifications#53, owner design review
/// 2026-11-20): the coloured bubbles hero with the call to action (Craft),
/// a calm row of five topics with their own pages, feature cards that
/// reveal their text on hover or focus, the three steps, the MVP and the
/// trust notes, in text-led sections with generous space (Vercel).

/// The asodya.com main palette, one colour per topic (Area 25).
abstract final class AsodyaPalette {
  static const green = Color(0xFF6EFF00);
  static const purple = Color(0xFFA201FF);
  static const cyan = Color(0xFF00E5FF);
  static const orange = Color(0xFFFF9100);
  static const mint = Color(0xFF00E676);
  static const night = Color(0xFF0B0C10);
}

/// A topic of the icon row and its page.
class LandingTopic {
  const LandingTopic(
    this.id,
    this.icon,
    this.color,
    this.label,
    this.title,
    this.body,
  );

  /// The page path segment: `/learn/<id>`.
  final String id;
  final IconData icon;
  final Color color;
  final String label, title;

  /// The body paragraphs, as string keys.
  final List<String> body;
}

const landingTopics = <LandingTopic>[
  LandingTopic(
    'sources',
    Icons.upload_file_rounded,
    AsodyaPalette.green,
    'lpSourcesLabel',
    'lpSourcesTitle',
    ['valPropTile2Desc', 'privacyBody'],
  ),
  LandingTopic(
    'questions',
    Icons.fact_check_outlined,
    AsodyaPalette.purple,
    'lpQuestionsLabel',
    'lpQuestionsTitle',
    ['valPropTile1Desc', 'verifyBeforePublish'],
  ),
  LandingTopic(
    'resume',
    Icons.history_rounded,
    AsodyaPalette.cyan,
    'lpResumeLabel',
    'lpResumeTitle',
    ['valPropTile4Desc', 'valPropTile3Desc'],
  ),
  LandingTopic(
    'certificates',
    Icons.workspace_premium_outlined,
    AsodyaPalette.orange,
    'lpCertificatesLabel',
    'lpCertificatesTitle',
    ['heroSub', 'valPropTile5Desc'],
  ),
  LandingTopic(
    'privacy',
    Icons.lock_outline_rounded,
    AsodyaPalette.mint,
    'lpPrivacyLabel',
    'lpPrivacyTitle',
    ['privacyBody', 'trustBody'],
  ),
];

/// The feature cards: icon, title and the text they reveal.
const landingCards = <(IconData, String, String)>[
  (Icons.search_rounded, 'lpCardTopics', 'valPropTile1Desc'),
  (Icons.description_outlined, 'lpCardMaterial', 'valPropTile2Desc'),
  (Icons.linear_scale_rounded, 'lpCardSteps', 'valPropTile3Desc'),
  (Icons.play_circle_outline_rounded, 'lpCardResume', 'valPropTile4Desc'),
  (Icons.leaderboard_outlined, 'lpCardShare', 'valPropTile5Desc'),
  (Icons.emoji_events_outlined, 'lpCardPlayful', 'playfulBody'),
];

const landingMaxWidth = 1200.0;

bool isNarrow(BuildContext context) => MediaQuery.sizeOf(context).width < 700;

/// What the landing buttons do. The screen gives the real browser actions;
/// tests give fakes, so this file stays free of browser-only code.
class LandingActions {
  const LandingActions({required this.onStart, required this.onWaitlist});

  /// Starts a new study (sign-in first without a session).
  final VoidCallback onStart;

  /// Joins the Pro waitlist (central api_for_apps route).
  final VoidCallback onWaitlist;
}

/// The width-limited column of a section with its gutters.
class Section extends StatelessWidget {
  const Section({
    super.key,
    required this.child,
    this.color,
    this.top = 96,
    this.bottom = 96,
  });

  final Widget child;
  final Color? color;
  final double top, bottom;

  @override
  Widget build(BuildContext context) {
    final narrow = isNarrow(context);
    return Container(
      width: double.infinity,
      color: color,
      padding: EdgeInsets.fromLTRB(
        narrow ? 20 : 48,
        narrow ? top * .66 : top,
        narrow ? 20 : 48,
        narrow ? bottom * .66 : bottom,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: landingMaxWidth),
          child: child,
        ),
      ),
    );
  }
}

/// A section heading with its short lead, at reading width.
class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {super.key, this.lead, this.center = false});

  final String title;
  final String? lead;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final narrow = isNarrow(context);
    return Column(
      crossAxisAlignment: center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: text.headlineMedium!.copyWith(
              fontSize: narrow ? 28 : 36,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
        ),
        if (lead != null) ...[
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Text(
              lead!,
              textAlign: center ? TextAlign.center : TextAlign.start,
              style: text.bodyLarge!.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class LandingBody extends StatelessWidget {
  const LandingBody({super.key, required this.actions, required this.footer});

  final LandingActions actions;
  final Widget footer;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      LandingHero(actions: actions),
      Section(
        key: const Key('topics-section'),
        child: Column(
          children: [
            SectionHeading(
              context.tr('lpRowTitle'),
              lead: context.tr('lpRowLead'),
              center: true,
            ),
            const SizedBox(height: 48),
            const TopicRow(),
          ],
        ),
      ),
      Section(
        key: const Key('cards-section'),
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeading(
              context.tr('whatCreate'),
              lead: context.tr('lpCardsHint'),
            ),
            const SizedBox(height: 40),
            const FeatureCardGrid(),
          ],
        ),
      ),
      const Section(key: Key('steps-section'), child: StepsSection()),
      Section(
        key: const Key('mvp-section'),
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: MvpSection(actions: actions),
      ),
      const Section(key: Key('trust-section'), child: TrustSection()),
      footer,
    ],
  );
}

/// The hero: the moving bubbles with the title, the promise and the actions
/// on them (Craft). The bubbles stay still under reduced motion.
class LandingHero extends StatelessWidget {
  const LandingHero({super.key, required this.actions});

  final LandingActions actions;

  @override
  Widget build(BuildContext context) {
    final narrow = isNarrow(context);
    final text = Theme.of(context).textTheme;
    return Stack(
      key: const Key('landing-hero'),
      children: [
        Positioned.fill(
          child: ExcludeSemantics(
            child: LiquidMetalBackground(
              blobCount: narrow ? 6 : 10,
              blurSigma: 22,
              speed: 28,
            ),
          ),
        ),
        Section(
          top: narrow ? 120 : 160,
          bottom: narrow ? 120 : 160,
          child: Column(
            children: [
              Text(
                context.tr('learnQuizCertified').toUpperCase(),
                style: text.labelLarge!.copyWith(letterSpacing: 2),
              ),
              const SizedBox(height: 20),
              Semantics(
                header: true,
                child: Text(
                  context.tr('welcomeTitle'),
                  key: const Key('hero-title'),
                  textAlign: TextAlign.center,
                  style: text.displayMedium!.copyWith(
                    fontSize: narrow ? 40 : 64,
                    fontWeight: FontWeight.w700,
                    height: 1.08,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Text(
                  context.tr('heroSub'),
                  textAlign: TextAlign.center,
                  style: text.titleMedium!.copyWith(height: 1.5),
                ),
              ),
              const SizedBox(height: 36),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  ElevatedButton(
                    key: const Key('hero-start'),
                    onPressed: actions.onStart,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 18,
                      ),
                    ),
                    child: Text(context.tr('valPropCtaGetStarted')),
                  ),
                  OutlinedButton(
                    key: const Key('hero-waitlist'),
                    onPressed: actions.onWaitlist,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 18,
                      ),
                      backgroundColor: Theme.of(context).colorScheme.surface,
                    ),
                    child: Text(context.tr('valPropCtaJoinWaitlist')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The visible state of an interactive element, for tests and styling.
enum Interaction { rest, hover, focus, pressed }

/// Pointer, keyboard and press handling with a hand cursor; Enter and Space
/// activate. Focus marks show in keyboard mode only (focus-visible).
class InteractiveRegion extends StatefulWidget {
  const InteractiveRegion({
    super.key,
    required this.onTap,
    required this.builder,
  });

  final VoidCallback? onTap;
  final Widget Function(BuildContext context, Interaction state) builder;

  @override
  State<InteractiveRegion> createState() => InteractiveState();
}

class InteractiveState extends State<InteractiveRegion> {
  bool _hover = false, _focus = false, _pressed = false;

  Interaction get state => _pressed
      ? Interaction.pressed
      : _focus &&
            FocusManager.instance.highlightMode ==
                FocusHighlightMode.traditional
      ? Interaction.focus
      : _hover
      ? Interaction.hover
      : Interaction.rest;

  @override
  Widget build(BuildContext context) => Focus(
    onFocusChange: (v) => setState(() => _focus = v),
    onKeyEvent: (node, event) {
      if (widget.onTap != null &&
          event is KeyDownEvent &&
          (event.logicalKey == LogicalKeyboardKey.enter ||
              event.logicalKey == LogicalKeyboardKey.space)) {
        widget.onTap!();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    },
    child: MouseRegion(
      cursor: widget.onTap == null
          ? MouseCursor.defer
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: widget.builder(context, state),
      ),
    ),
  );
}

Duration _motion(BuildContext context, int ms) =>
    MediaQuery.of(context).disableAnimations
    ? Duration.zero
    : Duration(milliseconds: ms);

/// The row of five topics. Each has its own colour; hover grows its tile
/// and fills it with the colour; focus shows a ring; each opens its page.
class TopicRow extends StatelessWidget {
  const TopicRow({super.key});

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: isNarrow(context) ? 12 : 28,
    runSpacing: 24,
    children: [
      for (final topic in landingTopics)
        TopicTile(
          key: Key('topic-${topic.id}'),
          topic: topic,
          onOpen: () => Navigator.of(context).pushNamed('/learn/${topic.id}'),
        ),
    ],
  );
}

class TopicTile extends StatelessWidget {
  const TopicTile({super.key, required this.topic, required this.onOpen});

  final LandingTopic topic;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: context.tr(topic.label),
      child: InteractiveRegion(
        onTap: onOpen,
        builder: (context, state) {
          final active = state != Interaction.rest;
          return SizedBox(
            width: 128,
            child: Column(
              children: [
                AnimatedScale(
                  duration: _motion(context, 160),
                  scale: state == Interaction.pressed
                      ? .96
                      : active
                      ? 1.08
                      : 1,
                  child: AnimatedContainer(
                    key: Key('topic-tile-${topic.id}'),
                    duration: _motion(context, 160),
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: active
                          ? topic.color
                          : topic.color.withValues(alpha: .22),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: state == Interaction.focus
                            ? scheme.onSurface
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      topic.icon,
                      size: 34,
                      color: active ? AsodyaPalette.night : scheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  context.tr(topic.label),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: active
                        ? TextDecoration.underline
                        : TextDecoration.none,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Feature cards (Craft "How people use", with features): the icon and the
/// title rest; hover or focus reveals the text. On a narrow touch screen,
/// which has no hover, the text always shows.
class FeatureCardGrid extends StatelessWidget {
  const FeatureCardGrid({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final columns = c.maxWidth >= 900
          ? 3
          : c.maxWidth >= 560
          ? 2
          : 1;
      final width = (c.maxWidth - (columns - 1) * 16) / columns;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final (icon, title, body) in landingCards)
            SizedBox(
              width: width,
              child: FeatureCard(
                key: Key('card-$title'),
                icon: icon,
                title: context.tr(title),
                body: context.tr(body),
                alwaysOpen: columns == 1,
              ),
            ),
        ],
      );
    },
  );
}

class FeatureCard extends StatelessWidget {
  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.alwaysOpen = false,
  });

  final IconData icon;
  final String title, body;
  final bool alwaysOpen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Semantics(
      label: title,
      hint: body,
      child: InteractiveRegion(
        // Focusable for keyboard readers; there is nothing to open.
        onTap: () {},
        builder: (context, state) {
          final open = alwaysOpen || state != Interaction.rest;
          return AnimatedContainer(
            key: const Key('feature-card-surface'),
            duration: _motion(context, 180),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: state == Interaction.pressed
                  ? scheme.surfaceContainerHigh
                  : scheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: state == Interaction.focus
                    ? scheme.primary
                    : open && !alwaysOpen
                    ? scheme.outline
                    : scheme.outlineVariant,
                width: state == Interaction.focus ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 28, color: scheme.primary),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: text.titleLarge!.copyWith(fontWeight: FontWeight.w700),
                ),
                // AnimatedSize with a zero duration re-lays itself out, so
                // reduced motion shows the result without it.
                if (MediaQuery.of(context).disableAnimations)
                  open
                      ? Padding(
                          key: const Key('feature-card-body'),
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            body,
                            style: text.bodyMedium!.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                        )
                      : Padding(
                          key: const Key('feature-card-teaser'),
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodyMedium!.copyWith(
                              color: scheme.onSurfaceVariant,
                              height: 1.5,
                            ),
                          ),
                        ),
                if (!MediaQuery.of(context).disableAnimations)
                  AnimatedSize(
                    duration: _motion(context, 180),
                    alignment: Alignment.topCenter,
                    child: open
                        ? Padding(
                            key: const Key('feature-card-body'),
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              body,
                              style: text.bodyMedium!.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.5,
                              ),
                            ),
                          )
                        : Padding(
                            key: const Key('feature-card-teaser'),
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodyMedium!.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.5,
                              ),
                            ),
                          ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// How it works in three steps.
class StepsSection extends StatelessWidget {
  const StepsSection({super.key});

  static const steps = [
    (Icons.upload_file_rounded, 'attachPdf'),
    (Icons.quiz_outlined, 'takeQuiz'),
    (Icons.ios_share_rounded, 'shareCertification'),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final items = [
      for (final (i, (icon, label)) in steps.indexed)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${i + 1}',
                style: text.titleMedium!.copyWith(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(icon, size: 22, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.tr(label),
                        style: text.titleMedium!.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading(
          context.tr('howItWorks'),
          lead: context.tr('lpStepsLead'),
        ),
        const SizedBox(height: 40),
        if (isNarrow(context))
          for (final item in items) ...[item, const SizedBox(height: 20)]
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: 32),
                Expanded(child: items[i]),
              ],
            ],
          ),
      ],
    );
  }
}

/// The MVP today: what is free now, with the plans and the waitlist.
class MvpSection extends StatelessWidget {
  const MvpSection({super.key, required this.actions});

  final LandingActions actions;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading(context.tr('mvpToday'), lead: context.tr('plansIntro')),
        const SizedBox(height: 28),
        for (final key in const [
          'bulletFree',
          'bulletMaterial',
          'bulletMultiple',
          'bulletShareable',
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 22,
                  color: scheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(context.tr(key), style: text.bodyLarge)),
              ],
            ),
          ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton(
              key: const Key('mvp-plans'),
              onPressed: () => Navigator.of(context).pushNamed('/plans'),
              child: Text(context.tr('lpSeePlans')),
            ),
            TextButton(
              key: const Key('mvp-waitlist'),
              onPressed: actions.onWaitlist,
              child: Text(context.tr('valPropCtaJoinWaitlist')),
            ),
          ],
        ),
      ],
    );
  }
}

/// Trust and transparency in three short text cards.
class TrustSection extends StatelessWidget {
  const TrustSection({super.key});

  static const notes = [
    (Icons.key_off_outlined, 'trustTitle', 'trustBody'),
    (Icons.lock_outline_rounded, 'privacyTitle', 'privacyBody'),
    (Icons.fact_check_outlined, 'lpVerifyTitle', 'verifyBeforePublish'),
  ];

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final cards = [
      for (final (icon, title, body) in notes)
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 26, color: scheme.primary),
              const SizedBox(height: 14),
              Text(
                context.tr(title),
                style: text.titleMedium!.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr(body),
                style: text.bodyMedium!.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading(context.tr('trustTransparency')),
        const SizedBox(height: 32),
        if (isNarrow(context))
          for (final card in cards) ...[card, const SizedBox(height: 16)]
        else
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(width: 16),
                  Expanded(child: cards[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// The page of one topic of the icon row (`/learn/<topic>`): complementary
/// information that the top bar does not hold.
class LearnBody extends StatelessWidget {
  const LearnBody({super.key, required this.topicId, required this.onStart});

  final String topicId;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final topic = landingTopics.where((t) => t.id == topicId).firstOrNull;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Section(
      key: Key('learn-$topicId'),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                key: const Key('learn-back'),
                onPressed: () => Navigator.of(context).canPop()
                    ? Navigator.of(context).pop()
                    : Navigator.of(context).pushReplacementNamed('/'),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: Text(context.tr('lpBack')),
              ),
              const SizedBox(height: 32),
              if (topic == null)
                Text(context.tr('lpNotFound'), style: text.titleLarge)
              else ...[
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: topic.color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(topic.icon, size: 34, color: AsodyaPalette.night),
                ),
                const SizedBox(height: 28),
                Semantics(
                  header: true,
                  child: Text(
                    context.tr(topic.title),
                    style: text.displaySmall!.copyWith(
                      fontSize: isNarrow(context) ? 32 : 44,
                      fontWeight: FontWeight.w700,
                      height: 1.12,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                for (final key in topic.body)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      context.tr(key),
                      style: text.bodyLarge!.copyWith(
                        height: 1.6,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                ElevatedButton(
                  key: const Key('learn-start'),
                  onPressed: onStart,
                  child: Text(context.tr('valPropCtaGetStarted')),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
