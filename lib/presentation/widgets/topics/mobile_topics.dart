import 'package:accredit/presentation/components/topics/topics_card.dart';
import 'package:flutter/material.dart';

import 'package:accredit/presentation/widgets/topics/base_topics.dart';


class MobileTopics extends BaseTopics {
  const MobileTopics({super.key, required String itemName})
      : super(itemName: itemName);

  @override
  State<MobileTopics> createState() => _MobileTopicsState();
}

class _MobileTopicsState extends BaseTopicsState<MobileTopics> {
  // Mobile page size
  @override
  int get initialPerPage => 4;

  // ----------------------- UI: Header (mobile) -----------------------
  Widget _buildHeaderBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              Expanded(child: Divider(height: 1, thickness: 1)),
              SizedBox(width: 12),
              Text('Topics', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(width: 12),
              Expanded(child: Divider(height: 1, thickness: 1)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: TextField(
                    controller: qCtrl,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => startSearch(),
                    decoration: const InputDecoration(
                      hintText: 'Search topics…',
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Search'),
                ),
              ),
              if (searchMode) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Clear search',
                  onPressed: clearSearch,
                  icon: const Icon(Icons.close),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ----------------------- UI: Grid (1 column) -----------------------
  Widget _buildGrid(BuildContext context) {
    final items = visibleItems;

    return Padding(
      key: gridKey,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(), // outer scroll drives
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          childAspectRatio: 1.0,
          crossAxisSpacing: 0.0,
          mainAxisSpacing: 12,
          mainAxisExtent: 180, // same height as desktop cards
        ),
        itemBuilder: (ctx, i) {
          final ident = getTopicIdentifications(items[i])!; // validated upstream
          return TopicsCard(
            title: ident.titleIdentification!,
            about: 'About',
            link: ident.linkIdentification!,
            imageUrl: safeImageFromIdent(ident),

            // mobile sizing
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            titleFontSize: 16,
            titleFontWeight: 600,
            buttonMinHeight: 44,
            buttonMinWidth: 80,
            imageWidth: 96,
            imageHeight: 64,
            gap: 10,
            showDivider: true,
          );
        },
      ),
    );
  }

  // ----------------------- UI: Footer -----------------------
  Widget _buildFooter() {
    final (startIndex, endIndex, curPage, curHasMore) = windowInfo;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          const Divider(height: 1, thickness: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              // Prev
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (isBusy || curPage <= 1) ? null : loadPrev,
                  icon: const Icon(Icons.arrow_upward, size: 16),
                  label: const Text('Previous', style: TextStyle(fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Center info chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFFF7F7F7),
                ),
                child: Text(
                  visibleItems.isEmpty
                      ? 'Page $curPage'
                      : 'Page $curPage | $startIndex–$endIndex',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              // Next
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (isBusy || !curHasMore) ? null : loadNext,
                  icon: const Icon(Icons.arrow_downward, size: 16),
                  label: const Text('Next', style: TextStyle(fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ----------------------- Scaffold -----------------------
  @override
  Widget build(BuildContext context) {
    final hasAny = visibleItems.isNotEmpty;

    final initialLoading = Column(
      children: const [
        Padding(
          padding: EdgeInsets.only(top: 24),
          child: Text('Loading topics, please wait...', style: TextStyle(fontSize: 14)),
        ),
        SizedBox(height: 16),
        SizedBox(height: 28, width: 28, child: CircularProgressIndicator()),
        SizedBox(height: 16),
      ],
    );

    final emptyState = const Padding(
      padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Text(
        'No topics available right now, please check back later,\n'
        'or contact support@asodya.com',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14),
      ),
    );

    return Scaffold(
        backgroundColor: const Color.fromARGB(255, 248, 248, 248),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          backgroundColor: const Color(0xFF242424),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeaderBar(),

                // 1) First-ever initial load
                if (!initialDone && !hasAny) initialLoading

                // 2) Any ongoing load (topics OR search) => spinner even when empty
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

                _buildFooter(),
              ],
            ),
          ),
        ),
      );
  }
}
