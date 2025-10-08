import 'package:accredit/presentation/components/topics/topics_card.dart';
import 'package:flutter/material.dart';

import 'package:accredit/presentation/widgets/topics/base_topics.dart';


/// DesktopTopics renders the topics grid for desktop layout
/// and wires up search/pagination via BaseTopicsState (no duplication).
class DesktopTopics extends BaseTopics {
  const DesktopTopics({super.key, required String itemName})
      : super(itemName: itemName);

  @override
  State<DesktopTopics> createState() => _DesktopTopicsState();
}

class _DesktopTopicsState extends BaseTopicsState<DesktopTopics> {
  // Desktop default page size
  @override
  int get initialPerPage => 15;

  // ----------------------- UI: Header -----------------------
  Widget _buildHeaderBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 40, left: 24, right: 24, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              Expanded(child: Divider(height: 1, thickness: 1)),
              SizedBox(width: 12),
              Text('Topics', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
              SizedBox(width: 12),
              Expanded(child: Divider(height: 1, thickness: 1)),
            ],
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: TextField(
                        controller: qCtrl,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => startSearch(),
                        decoration: const InputDecoration(
                          hintText: 'Search topics…',
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                          enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFCCCCCC), width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF888888), width: 1)),
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 1)),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 1)),
                      
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: startSearch,
                      icon:  Icon(Icons.search, size: 18, color: Theme.of(context).colorScheme.onPrimary),
                      label:  Text('Search', style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onPrimary)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  )),
                  if (searchMode) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: clearSearch,
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Clear'),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final bool isNarrow = maxW < 1100; // tweak if needed
        final int columns = isNarrow ? 1 : 4;
        final items = visibleItems;

        return Padding(
          key: gridKey,
          padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 30),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(), // outer scroll drives
            itemCount: items.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              childAspectRatio: 1.0,
              crossAxisSpacing: 5,
              mainAxisSpacing: 12,
              mainAxisExtent: 180,
            ),
            itemBuilder: (ctx, i) {
              final ident = getTopicIdentifications(items[i])!; // already validated upstream
              return TopicsCard(
                title: ident.titleIdentification!,
                about: 'About',
                link: ident.linkIdentification!,
                imageUrl: safeImageFromIdent(ident),

                // desktop sizing
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                titleFontSize: 18,
                titleFontWeight: 600,
                buttonMinHeight: 60,
                buttonMinWidth: 80,
                imageWidth: 120,
                imageHeight: 72,
                gap: 12,
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
    final (startIndex, endIndex, curPage, curHasMore) = windowInfo;

    return Column(
      children: [
        const SizedBox(height: 24),
        const Divider(height: 1, thickness: 1, indent: 120, endIndent: 120),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: (loading || curPage <= 1) ? null : loadPrev,
              icon: const Icon(Icons.arrow_upward, size: 14),
              label: const Text('Load previous page', style: TextStyle(fontSize: 14)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(80, 60),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFFF7F7F7),
              ),
              child: Text(
                visibleItems.isEmpty
                    ? 'Page $curPage'
                    : 'Page $curPage | Items $startIndex–$endIndex',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: (loading || !curHasMore) ? null : loadNext,
              icon: const Icon(Icons.arrow_downward, size: 14),
              label: const Text('Load next page', style: TextStyle(fontSize: 14)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(80, 60),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  // ----------------------- Scaffold -----------------------
  @override
  Widget build(BuildContext context) {
    final hasAny = visibleItems.isNotEmpty;

    final initialLoading = Column(
      children: const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text('Loading topics, please wait...', style: TextStyle(fontSize: 16)),
        ),
        SizedBox(height: 16),
        SizedBox(height: 32, width: 32, child: CircularProgressIndicator()),
        SizedBox(height: 24),
      ],
    );

    final emptyState = const Padding(
      padding: EdgeInsets.symmetric(vertical: 24, horizontal: 40),
      child: Text(
        'No topics available right now, please check back later, or contact support@asodya.com',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16),
      ),
    );

    return Scaffold(
          backgroundColor: const Color.fromARGB(255, 248, 248, 248),
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            backgroundColor: const Color.fromARGB(255, 36, 36, 36),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeaderBar(),

                  // 1) First-ever initial load (topics)
                  if (!initialDone && !hasAny) initialLoading

                  // 2) Any ongoing load (topics OR search) => show spinner even if list empty
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
                                    position: Tween<Offset>(
                                      begin: const Offset(0, .25),
                                      end: Offset.zero,
                                    ).animate(anim),
                                    child: child,
                                  ),
                                ),
                                child: Text(
                                  loadingPhrases[loadingIndex],
                                  key: ValueKey<int>(loadingIndex),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )

                  // 3) Loaded but empty
                  else if (!hasAny)
                    emptyState

                  // 4) Normal grid
                  else
                    _buildGrid(context),

                  // 5) Footer
                  _buildFooter(),
                ],
              ),
            ),
          ),
        );
  }
}
