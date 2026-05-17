import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../models/song.dart';
import '../models/tag.dart';
import '../models/artist.dart';
import '../models/song_set.dart';

class SongService {
  static const String _apiUrl = 'https://adminka.synapps.sk/api/songs';
  static const String _tagsApiUrl = 'https://adminka.synapps.sk/api/song-tags';
  static const String _apiUser = 'api_user';
  static const String _apiPassword = '***REMOVED***';

  static Map<String, String> _getAuthHeaders() {
    final credentials = base64Encode(utf8.encode('$_apiUser:$_apiPassword'));
    return {
      'Authorization': 'Basic $credentials',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  static void _sortSongs(List<Song> songs) {
    songs.sort((a, b) {
      if (a.number == null && b.number == null)
        return a.title.compareTo(b.title);
      if (a.number == null) return 1;
      if (b.number == null) return -1;
      return a.number!.compareTo(b.number!);
    });
  }

  static List<Artist> extractAllArtists(List<Song> songs) {
    final Map<int, Artist> artistMap = {};
    for (final song in songs) {
      for (final artist in song.artists) {
        artistMap[artist.id] = artist;
      }
    }
    final artists = artistMap.values.toList();
    artists.sort((a, b) => a.name.compareTo(b.name));
    return artists;
  }

  /// Fetches songs and tags from the remote API.
  /// Returns a record of (songs, tags).
  static Future<({List<Song> songs, List<Tag> tags})> syncFromApi() async {
    final headers = _getAuthHeaders();

    final responses = await Future.wait([
      http.get(Uri.parse(_apiUrl), headers: headers),
      http.get(Uri.parse(_tagsApiUrl), headers: headers),
    ].map((requestFuture) =>
        requestFuture.timeout(const Duration(seconds: 30))));

    for (var response in responses) {
      if (response.statusCode != 200) {
        throw Exception(
            'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    }

    final songsData = json.decode(responses[0].body);
    final tagsData = json.decode(responses[1].body);

    final songs =
        (songsData as List).map((json) => Song.fromJson(json)).toList();
    _sortSongs(songs);

    final tags =
        (tagsData as List).map((json) => Tag.fromJson(json)).toList();

    return (songs: songs, tags: tags);
  }

  /// Loads songs and tags from the local file cache.
  static Future<({List<Song> songs, List<Tag> tags})> loadFromCache() async {
    final directory = await getApplicationDocumentsDirectory();
    final songsFile = File('${directory.path}/songs.json');
    final tagsFile = File('${directory.path}/tags.json');

    if (!await songsFile.exists() || !await tagsFile.exists()) {
      throw Exception('Cache files not found');
    }

    final songsData = json.decode(await songsFile.readAsString());
    final tagsData = json.decode(await tagsFile.readAsString());

    final songs =
        (songsData as List).map((json) => Song.fromJson(json)).toList();
    _sortSongs(songs);

    final tags =
        (tagsData as List).map((json) => Tag.fromJson(json)).toList();

    return (songs: songs, tags: tags);
  }

  /// Loads songs and tags from bundled assets.
  static Future<({List<Song> songs, List<Tag> tags})> loadFromAssets() async {
    String songsResponse;
    try {
      songsResponse = await rootBundle.loadString('assets/songs.json');
    } catch (e) {
      throw Exception('assets/songs.json missing. Check pubspec.yaml');
    }

    String tagsResponse;
    try {
      tagsResponse = await rootBundle.loadString('assets/tags.json');
    } catch (e) {
      throw Exception('assets/tags.json missing. Check pubspec.yaml');
    }

    final songsData = json.decode(songsResponse);
    final tagsData = json.decode(tagsResponse);

    final songs =
        (songsData as List).map((json) => Song.fromJson(json)).toList();
    _sortSongs(songs);

    final tags =
        (tagsData as List).map((json) => Tag.fromJson(json)).toList();

    return (songs: songs, tags: tags);
  }

  /// Saves songs and tags to the local file cache.
  static Future<void> saveToCache(List<Song> songs, List<Tag> tags) async {
    if (kIsWeb) return;

    final directory = await getApplicationDocumentsDirectory();
    final songsFile = File('${directory.path}/songs.json');
    final tagsFile = File('${directory.path}/tags.json');

    final serializedSongs = songs
        .map((song) => {
              'id': song.id,
              'title': song.title,
              'lyrics': song.lyrics,
              'number': song.number,
              'bpm': song.bpm,
              'artists': song.artists.map((a) => a.toJson()).toList(),
              'tags': song.tags.map((t) => t.toJson()).toList(),
            })
        .toList();

    final serializedTags = tags.map((tag) => tag.toJson()).toList();

    await songsFile.writeAsString(json.encode(serializedSongs));
    await tagsFile.writeAsString(json.encode(serializedTags));
  }

  // --- Preferences ---

  static Future<double> loadListFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('list_font_size') ?? 16.0;
  }

  static Future<void> saveListFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('list_font_size', size);
  }

  static Future<double> loadSongFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble('song_font_size') ?? 16.0;
  }

  static Future<void> saveSongFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('song_font_size', size);
  }

  static Future<DateTime?> loadLastSyncDate() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncTimestamp = prefs.getInt('last_sync_timestamp');
    if (lastSyncTimestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(lastSyncTimestamp);
    }
    return null;
  }

  static Future<DateTime> saveLastSyncDate() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setInt('last_sync_timestamp', now.millisecondsSinceEpoch);
    return now;
  }

  // --- Song Sets ---

  static Future<List<SongSet>> loadSongSets() async {
    final prefs = await SharedPreferences.getInstance();
    final setsJson = prefs.getString('song_sets');

    if (setsJson != null) {
      final List<dynamic> decoded = json.decode(setsJson);
      return decoded.map((json) => SongSet.fromJson(json)).toList();
    }
    return [];
  }

  static Future<void> saveSongSets(List<SongSet> sets) async {
    final prefs = await SharedPreferences.getInstance();
    final setsJson = json.encode(sets.map((set) => set.toJson()).toList());
    await prefs.setString('song_sets', setsJson);
  }
}
