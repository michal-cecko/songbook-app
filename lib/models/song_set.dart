class SongSet {
  final String id;
  String name;
  List<int> songIds;
  DateTime createdAt;
  DateTime updatedAt;

  SongSet({
    required this.id,
    required this.name,
    required this.songIds,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SongSet.fromJson(Map<String, dynamic> json) {
    return SongSet(
      id: json['id'],
      name: json['name'],
      songIds: List<int>.from(json['songIds']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'songIds': songIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
