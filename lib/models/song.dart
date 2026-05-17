import 'artist.dart';
import 'tag.dart';

class Song {
  final int id;
  final String title;
  final String lyrics;
  final int? number;
  final String? bpm;
  final List<Artist> artists;
  final List<Tag> tags;

  Song({
    required this.id,
    required this.title,
    required this.lyrics,
    this.number,
    this.bpm,
    required this.artists,
    required this.tags,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'],
      title: json['title'],
      lyrics: json['lyrics'] ?? '',
      number: json['number'],
      bpm: json['bpm']?.toString(),
      artists: (json['artists'] as List<dynamic>?)
              ?.map((artist) => Artist.fromJson(artist))
              .toList() ??
          [],
      tags: (json['tags'] as List<dynamic>?)
              ?.map((tag) => Tag.fromJson(tag))
              .toList() ??
          [],
    );
  }

  String get artistNames => artists.map((artist) => artist.name).join(', ');

  String get tagNames => tags.map((tag) => tag.name).join(', ');
}
