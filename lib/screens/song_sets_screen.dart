import 'package:flutter/material.dart';

import '../models/song.dart';
import '../models/song_set.dart';
import '../services/song_service.dart';
import '../l10n/app_localizations.dart';
import 'edit_song_set_screen.dart';
import 'song_set_player_screen.dart';

class SongSetsScreen extends StatefulWidget {
  final List<Song> allSongs;

  const SongSetsScreen({Key? key, required this.allSongs}) : super(key: key);

  @override
  _SongSetsScreenState createState() => _SongSetsScreenState();
}

class _SongSetsScreenState extends State<SongSetsScreen> {
  List<SongSet> _songSets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSongSets();
  }

  Future<void> _loadSongSets() async {
    try {
      final sets = await SongService.loadSongSets();
      setState(() {
        _songSets = sets;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading song sets: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSongSets() async {
    try {
      await SongService.saveSongSets(_songSets);
    } catch (e) {
      print('Error saving song sets: $e');
    }
  }

  void _createNewSet() {
    final l10n = AppLocalizations.of(context);
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: Text(l10n.createSet, style: TextStyle(fontSize: 32)),
        ),
        content: Container(
          width: 600,
          child: TextField(
            controller: nameController,
            style: TextStyle(fontSize: 24),
            decoration: InputDecoration(
              labelText: l10n.setName,
              labelStyle: TextStyle(fontSize: 24),
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel, style: TextStyle(fontSize: 24)),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                final newSet = SongSet(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text.trim(),
                  songIds: [],
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                setState(() {
                  _songSets.add(newSet);
                });
                _saveSongSets();
                Navigator.pop(context);

                _editSet(newSet);
              }
            },
            child: Text(l10n.save, style: TextStyle(fontSize: 24)),
          ),
        ],
      ),
    );
  }

  void _editSet(SongSet songSet) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditSongSetScreen(
          songSet: songSet,
          allSongs: widget.allSongs,
          onSave: (updatedSet) {
            setState(() {
              final index =
                  _songSets.indexWhere((s) => s.id == updatedSet.id);
              if (index != -1) {
                _songSets[index] = updatedSet;
              }
            });
            _saveSongSets();
          },
        ),
      ),
    );
  }

  void _deleteSet(SongSet songSet) {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteSet, style: TextStyle(fontSize: 32)),
        content: Text(l10n.confirmDelete, style: TextStyle(fontSize: 24)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel, style: TextStyle(fontSize: 24)),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _songSets.removeWhere((s) => s.id == songSet.id);
              });
              _saveSongSets();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete, style: TextStyle(fontSize: 24)),
          ),
        ],
      ),
    );
  }

  void _startSet(SongSet songSet) {
    final songs = songSet.songIds
        .map((id) => widget.allSongs.firstWhere(
              (song) => song.id == id,
              orElse: () => widget.allSongs.first,
            ))
        .toList();

    if (songs.isEmpty) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noSongsInSet)),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SongSetPlayerScreen(
          songSet: songSet,
          songs: songs,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.songSets)),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.songSets),
      ),
      body: _songSets.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.library_music, size: 120, color: Colors.grey),
                  SizedBox(height: 24),
                  Text(
                    l10n.noSets,
                    style: TextStyle(fontSize: 32, color: Colors.grey),
                  ),
                  SizedBox(height: 12),
                  Text(
                    l10n.createFirstSet,
                    style: TextStyle(fontSize: 20, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _songSets.length,
              itemBuilder: (context, index) {
                final songSet = _songSets[index];
                return Card(
                  margin:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(24),
                    title: Text(
                      songSet.name,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '${songSet.songIds.length} ${l10n.songsInSet}',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          iconSize: 40,
                          icon: Icon(Icons.edit),
                          onPressed: () => _editSet(songSet),
                          tooltip: l10n.editSet,
                        ),
                        IconButton(
                          iconSize: 40,
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteSet(songSet),
                          tooltip: l10n.deleteSet,
                        ),
                      ],
                    ),
                    onTap: () => _startSet(songSet),
                  ),
                );
              },
            ),
      floatingActionButton: SizedBox(
        width: 112,
        height: 112,
        child: FloatingActionButton(
          onPressed: _createNewSet,
          child: Icon(Icons.add, size: 56),
          tooltip: l10n.createSet,
        ),
      ),
    );
  }
}
