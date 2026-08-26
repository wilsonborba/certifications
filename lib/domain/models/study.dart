class StudySource {
  StudySource.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      kind = json['kind'] as String,
      filename = json['filename'] as String,
      status = json['status'] as String,
      sizeBytes = (json['size_bytes'] as num).toInt(),
      selection = json['selection'] as Map<String, dynamic>?;
  final String id, kind, filename, status;
  final int sizeBytes;
  final Map<String, dynamic>? selection;
}

class Study {
  Study.fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      name = json['name'] as String,
      status = json['status'] as String,
      activeSizeBytes = (json['active_size_bytes'] as num? ?? 0).toInt(),
      sources = ((json['sources'] as List? ?? []).cast<Map<String, dynamic>>())
          .map(StudySource.fromJson)
          .toList();
  final String id, name, status;
  final int activeSizeBytes;
  final List<StudySource> sources;
}
