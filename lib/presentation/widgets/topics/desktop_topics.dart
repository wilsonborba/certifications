import 'package:accredit/presentation/components/topics/topics_card.dart';
import 'package:flutter/material.dart';
import 'package:accredit/presentation/widgets/topics/base_topics.dart';

class DesktopTopics extends BaseTopics {
  const DesktopTopics({super.key, required String itemName})
      : super(itemName: itemName);

  @override
  State<DesktopTopics> createState() => _DesktopTopicsState();
}

class _DesktopTopicsState extends BaseTopicsState<DesktopTopics> {
  @override
  int get initialPerPage => 15;

  // ----------------------- UI: Header -----------------------
  Widget _buildHeaderBar() {
    final cs = Theme.of(context).colorScheme;
    final subtle = cs.onSurface.withAlpha((.65 * 255).toInt());

    return Padding(
      padding: const EdgeInsets.only(top: 36, left: 32, right: 32, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Divider(height: 1, thickness: 1, color: cs.outlineVariant)),
              
              // ShaderMask(
              //   shaderCallback: (rect) => LinearGradient(
              //     colors: [cs.primary, cs.primary.withAlpha((.6 * 255).toInt())],
              //   ).createShader(rect),
              //   child: const Text('Topics', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: Colors.white)),
              // ),
              
              Expanded(child: Divider(height: 1, thickness: 1, color: cs.outlineVariant)),
            ],
          ),
          const SizedBox(height: 22),
          Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Row(
                children: [
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      height: 52,
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: cs.primary.withAlpha((0.15 * 255).toInt())),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withAlpha((0.05 * 255).toInt()), blurRadius: 18, offset: const Offset(0, 10)),
                          BoxShadow(color: Colors.white.withAlpha((0.9 * 255).toInt()), blurRadius: 8, offset: const Offset(-1, -1), spreadRadius: -2),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      child: TextField(
                        controller: qCtrl,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => startSearch(),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Search topics…',
                          hintStyle: TextStyle(color: subtle),
                          prefixIcon: Icon(Icons.search, color: subtle),
                          contentPadding: const EdgeInsets.only(top: 14),
                          focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(999),
      borderSide: const BorderSide(
        color: Colors.transparent, // your purple when clicked
        width: 2,
      ),
    ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: startSearch,
                      icon: Icon(Icons.search, size: 18, color: cs.onPrimary),
                      label: Text('Search', style: TextStyle(fontSize: 14, color: cs.onPrimary)),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: cs.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                      ),
                    ),
                  ),
                  if (searchMode) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: clearSearch,
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Clear'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: cs.onSurface,
                          side: BorderSide(color: cs.outlineVariant),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------- UI: Grid -----------------------
  Widget _buildGrid(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final bool isNarrow = maxW < 1200;
        final int columns = isNarrow ? 2 : 4;
        final items = visibleItems;

        return Padding(
          key: gridKey,
          padding: const EdgeInsets.symmetric(horizontal: 72, vertical: 28),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              childAspectRatio: 1.0,
              crossAxisSpacing: 18,
              mainAxisSpacing: 18,
              mainAxisExtent: 196,
            ),
            itemBuilder: (ctx, i) {
              final ident = getTopicIdentifications(items[i])!;
              return TopicsCard(
                itemName: widget.itemName,
                identification: ident.inputIdentification,
                title: ident.titleIdentification!,
                about: 'About',
                link: ident.linkIdentification!,
                imageUrl: safeImageFromIdent(ident),

                // desktop sizing
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                titleFontSize: 18,
                titleFontWeight: 700,
                buttonMinHeight: 52,
                buttonMinWidth: 100,
                imageWidth: 132,
                imageHeight: 86,
                gap: 16,
                showDivider: true,
              );
            },
          ),
        );
      },
    );
  }

  // ----------------------- UI: Footer -----------------------
  Widget _buildFooter() {
    final cs = Theme.of(context).colorScheme;
    final (startIndex, endIndex, curPage, curHasMore) = windowInfo;

    return Column(
      children: [
        const SizedBox(height: 24),
        Divider(height: 1, thickness: 1, indent: 120, endIndent: 120, color: cs.outlineVariant),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: (loading || curPage <= 1) ? null : loadPrev,
              icon: const Icon(Icons.arrow_upward, size: 14),
              label: const Text('Previous', style: TextStyle(fontSize: 14)),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                minimumSize: const Size(160, 56),
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                disabledBackgroundColor: cs.surfaceContainerHighest ,
                disabledForegroundColor: cs.onSurface.withAlpha((0.4 * 255).toInt()),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest .withAlpha((0.75 * 255).toInt()),
                border: Border.all(color: cs.primary.withAlpha((0.18 * 255).toInt())),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                visibleItems.isEmpty
                    ? 'Page $curPage'
                    : 'Page $curPage | Items $startIndex–$endIndex',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: cs.onSurface),
              ),
            ),
            ElevatedButton.icon(
              onPressed: (loading || !curHasMore) ? null : loadNext,
              icon: const Icon(Icons.arrow_downward, size: 14),
              label: const Text('Next', style: TextStyle(fontSize: 14)),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                minimumSize: const Size(160, 56),
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                disabledBackgroundColor: cs.surfaceContainerHighest ,
                disabledForegroundColor: cs.onSurface.withAlpha((0.4 * 255).toInt()),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 64),
      ],
    );
  }

  // ----------------------- Scaffold -----------------------
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasAny = visibleItems.isNotEmpty;

    final initialLoading = Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text('Loading topics, please wait…', style: TextStyle(fontSize: 16, color: cs.onSurface)),
        ),
        const SizedBox(height: 16),
        const SizedBox(height: 32, width: 32, child: CircularProgressIndicator()),
        const SizedBox(height: 24),
      ],
    );

    final emptyState = Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 40),
      child: Text(
        'No topics available right now.\nPlease check back later or contact support@asodya.com',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16, color: cs.onSurface),
      ),
    );

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Choose a topic', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w900)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeaderBar(),
              if (!initialDone && !hasAny) initialLoading
              else if (isBusy)
                SizedBox(
                  height: lastGridHeight > 0 ? lastGridHeight : 180,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 28, width: 28, child: CircularProgressIndicator()),
                          const SizedBox(height: 12),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, anim) => FadeTransition(
                              opacity: anim,
                              child: SlideTransition(
                                position: Tween<Offset>(begin: const Offset(0, .25), end: Offset.zero).animate(anim),
                                child: child,
                              ),
                            ),
                            child: Text(
                              loadingPhrases[loadingIndex],
                              key: ValueKey<int>(loadingIndex),
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: cs.onSurface),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (!hasAny)
                emptyState
              else
                _buildGrid(context),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }
}
