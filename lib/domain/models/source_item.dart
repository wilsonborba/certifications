

class SourceItem {
  final String mode;        // "playful" | "serious"
  final String sourceName;  // e.g. "apps", "newspapers"
  final bool hasTopic;
  final String itemName;    // e.g. "google"
  final String itemImg;
  dynamic expirationTime; // expiration time

  SourceItem({
    required this.mode,
    required this.sourceName,
    required this.hasTopic,
    required this.itemName,
    required this.itemImg,
    this.expirationTime,
  });

  factory SourceItem.fromJson(Map<String, dynamic> j) => SourceItem(
        mode: (j['mode'] ?? '').toString(),
        sourceName: (j['source_name'] ?? '').toString(),
        hasTopic: j['has_topic'] == true,
        itemName: (j['item_name'] ?? '').toString(),
        itemImg: (j['item_img'] ?? '').toString(),
        expirationTime: j['expiration_time'],
      );
}