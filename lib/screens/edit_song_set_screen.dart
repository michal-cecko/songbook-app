import 'package:flutter/material.dart';

import '../models/song.dart';
import '../models/song_set.dart';
import '../l10n/app_localizations.dart';

class EditSongSetScreen extends StatefulWidget {
  final SongSet songSet;
  final List<Song> allSongs;
  final Function(SongSet) onSave;

  const EditSongSetScreen({
    Key? key,
    required this.songSet,
    required this.allSongs,
    required this.onSave,
  }) : super(key: key);

  @override
  _EditSongSetScreenState createState() => _EditSongSetScreenState();
}

class _EditSongSetScreenState extends State<EditSongSetScreen> {
  late TextEditingController _nameController;
  late List<int> _selectedSongIds;
  TextEditingController _searchController = TextEditingController();
  List<Song> _filteredSongs = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.songSet.name);
    _selectedSongIds = List.from(widget.songSet.songIds);
    _filteredSongs = List.from(widget.allSongs);
    _searchController.addListener(_filterSongs);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterSongs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredSongs = widget.allSongs.where((song) {
        return song.title.toLowerCase().contains(query) ||
            song.artistNames.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _toggleSong(int songId) {
    setState(() {
      if (_selectedSongIds.contains(songId)) {
        _selectedSongIds.remove(songId);
      } else {
        _selectedSongIds.add(songId);
      }
    });
  }

  void _saveSet() {
    if (_nameController.text.trim().isEmpty) {
      return;
    }

    final updatedSet = SongSet(
      id: widget.songSet.id,
      name: _nameController.text.trim(),
      songIds: _selectedSongIds,
      createdAt: widget.songSet.createdAt,
      updatedAt: DateTime.now(),
    );

    widget.onSave(updatedSet);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editSet),
        actions: [
          IconButton(
            iconSize: 40,
            icon: Icon(Icons.save),
            onPressed: _saveSet,
            tooltip: l10n.save,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _nameController,
              style: TextStyle(fontSize: 28),
              decoration: InputDecoration(
                labelText: l10n.setName,
                labelStyle: TextStyle(fontSize: 24),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(16),
                        color: Colors.grey[200],
                        child: Row(
                          children: [
                            Icon(Icons.playlist_play, size: 40),
                            SizedBox(width: 12),
                            Text(
                              '${l10n.songsInSet} (${_selectedSongIds.length})',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _selectedSongIds.isEmpty
                            ? Center(
                                child: Text(
                                  l10n.noSongsInSet,
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 24),
                                ),
                              )
                            : ReorderableListView.builder(
                                itemCount: _selectedSongIds.length,
                                onReorder: (oldIndex, newIndex) {
                                  setState(() {
                                    if (newIndex > oldIndex) {
                                      newIndex -= 1;
                                    }
                                    final item =
                                        _selectedSongIds.removeAt(oldIndex);
                                    _selectedSongIds.insert(newIndex, item);
                                  });
                                },
                                itemBuilder: (context, index) {
                                  final songId = _selectedSongIds[index];
                                  final song = widget.allSongs.firstWhere(
                                    (s) => s.id == songId,
                                    orElse: () => widget.allSongs.first,
                                  );

                                  return ListTile(
                                    key: ValueKey(songId),
                                    leading: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24,
                                      ),
                                    ),
                                    title: Text(song.title,
                                        style: TextStyle(fontSize: 24)),
                                    subtitle: Text(song.artistNames,
                                        style: TextStyle(fontSize: 20)),
                                    trailing: IconButton(
                                      iconSize: 40,
                                      icon: Icon(Icons.remove_circle,
                                          color: Colors.red),
                                      onPressed: () => _toggleSong(songId),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
                VerticalDivider(width: 1),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(16),
                        color: Colors.grey[200],
                        child: Row(
                          children: [
                            Icon(Icons.library_music, size: 40),
                            SizedBox(width: 12),
                            Text(
                              l10n.selectSongs,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(fontSize: 24),
                          decoration: InputDecoration(
                            hintText: l10n.searchSongs,
                            hintStyle: TextStyle(fontSize: 24),
                            prefixIcon: Icon(Icons.search, size: 32),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _filteredSongs.length,
                          itemBuilder: (context, index) {
                            final song = _filteredSongs[index];
                            final isSelected =
                                _selectedSongIds.contains(song.id);

                            return ListTile(
                              title: Text(song.title,
                                  style: TextStyle(fontSize: 24)),
                              subtitle: Text(song.artistNames,
                                  style: TextStyle(fontSize: 20)),
                              trailing: IconButton(
                                iconSize: 40,
                                icon: Icon(
                                  isSelected
                                      ? Icons.remove_circle
                                      : Icons.add_circle,
                                  color:
                                      isSelected ? Colors.red : Colors.green,
                                ),
                                onPressed: () => _toggleSong(song.id),
                              ),
                              selected: isSelected,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
