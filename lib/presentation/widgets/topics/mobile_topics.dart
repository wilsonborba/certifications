import 'package:accredit/presentation/components/quiz/futuristic_loading.dart';
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
  @override
  int get initialPerPage => 4;

  // ----------------------- UI: Header (mobile) -----------------------
  Widget _buildHeaderBar() {
    final cs = Theme.of(context).colorScheme;
    final subtle = cs.onSurface.withAlpha((0.65 * 255).toInt());

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Label bar with accent line
          Row(
            children: [
              Expanded(child: Divider(height: 1, thickness: 1, color: cs.outlineVariant)),
              // const SizedBox(width: 12),
              // Row(
              //   children: [
              //     Container(
              //       height: 8,
              //       width: 8,
              //       decoration: BoxDecoration(
              //         color: cs.primary,
              //         borderRadius: BorderRadius.circular(99),
              //       ),
              //     ),
              //     const SizedBox(width: 8),
              //     Text(
              //       'Topics',
              //       style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: cs.onSurface),
              //     ),
              //   ],
              // ),
              // const SizedBox(width: 12),
              Expanded(child: Divider(height: 1, thickness: 1, color: cs.outlineVariant)),
            ],
          ),
          const SizedBox(height: 12),

          // Search row (pill + action)
          Row(
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  height: 46,
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: cs.primary.withAlpha((0.15 * 255).toInt())),
                    boxShadow: [
                      // soft neumorphic lift
                      BoxShadow(
                        color: Colors.black.withAlpha((0.04 * 255).toInt()),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: Colors.white.withAlpha((0.8 * 255).toInt()),
                        blurRadius: 6,
                        offset: const Offset(-1, -1),
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    controller: qCtrl,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => startSearch(),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Search topics…',
                      hintStyle: TextStyle(color: subtle),
                      prefixIcon: Icon(Icons.search, color: subtle),
                      contentPadding: const EdgeInsets.only(top: 10),
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
              const SizedBox(width: 10),
              SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: startSearch,
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Search'),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                ),
              ),
              if (searchMode) ...[
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Clear search',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: clearSearch,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(Icons.close, color: cs.onSurface),
                    ),
                  ),
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
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          childAspectRatio: 1.0,
          crossAxisSpacing: 0.0,
          mainAxisSpacing: 12,
          mainAxisExtent: 190,
        ),
        itemBuilder: (ctx, i) {
          final ident = getTopicIdentifications(items[i])!;
              return TopicsCard(
                itemName: widget.itemName,
                identification: ident.inputIdentification,
                title: ident.titleIdentification!,
                about: 'Open this topic to generate a quiz.',
                link: ident.linkIdentification!,
                imageUrl: safeImageFromIdent(ident),

            // mobile sizing
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            titleFontSize: 16,
            titleFontWeight: 600,
            buttonMinHeight: 44,
            buttonMinWidth: 88,
            imageWidth: 104,
            imageHeight: 68,
            gap: 12,
            showDivider: true,
          );
        },
      ),
    );
  }

  // ----------------------- UI: Footer -----------------------
  Widget _buildFooter() {
    final cs = Theme.of(context).colorScheme;
    final (startIndex, endIndex, curPage, curHasMore) = windowInfo;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      child: Column(
        children: [
          Divider(height: 1, thickness: 1, color: cs.outlineVariant),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (isBusy || curPage <= 1) ? null : loadPrev,
                  icon: const Icon(Icons.arrow_upward, size: 16),
                  label: const Text('Previous', style: TextStyle(fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    minimumSize: const Size.fromHeight(44),
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    disabledBackgroundColor: cs.surfaceContainerHighest ,
                    disabledForegroundColor: cs.onSurface.withAlpha((0.4 * 255).toInt()),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Glassy page chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withAlpha((0.7 * 255).toInt()),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: cs.primary.withAlpha((0.18 * 255).toInt())),
                ),
                child: Text(
                  visibleItems.isEmpty
                      ? 'Page $curPage'
                      : 'Page $curPage | $startIndex–$endIndex',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: cs.onSurface),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (isBusy || !curHasMore) ? null : loadNext,
                  icon: const Icon(Icons.arrow_downward, size: 16),
                  label: const Text('Next', style: TextStyle(fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    minimumSize: const Size.fromHeight(44),
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    disabledBackgroundColor: cs.surfaceContainerHighest,
                    disabledForegroundColor: cs.onSurface.withAlpha((0.4 * 255).toInt()),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    final cs = Theme.of(context).colorScheme;
    final hasAny = visibleItems.isNotEmpty;

    final initialLoading = Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: FuturisticLoading(
            messages:  [
                  'Loading topics…',
                  'Preparing your topics…',
                  'Just a moment longer…',
                  'Almost there…',
                ],
            isActive: hasAny ? false : true,
            transparentBackground: true,
          ),
      ),
    );

    final emptyState = Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Text(
        'No topics available right now,\nplease check back later or contact support@asodya.com',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, color: cs.onSurface),
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
        title: Text('Choose a topic', style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w800)),
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
                      child: FuturisticLoading(
                          messages:  [
                                'Fetching topics…',
                                'Some topics take longer to load…',
                                'Checking availability…',
                                'Still working on it…',
                                'Almost there…',
                              ],
                          isActive: isBusy,
                          transparentBackground: true,
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
