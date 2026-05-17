import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';

import '../models/song.dart';
import '../models/tag.dart';
import '../models/artist.dart';
import '../services/song_service.dart';
import '../l10n/app_localizations.dart';
import '../utils/text_utils.dart';
import '../utils/color_utils.dart';
import 'song_detail_screen.dart';
import 'song_sets_screen.dart';

class SongListScreen extends StatefulWidget {
  @override
  _SongListScreenState createState() => _SongListScreenState();
}

class _SongListScreenState extends State<SongListScreen> {
  List<Song> _songs = [];
  List<Song> _filteredSongs = [];
  List<Tag> _allTags = [];
  List<Artist> _allArtists = [];
  TextEditingController _searchController = TextEditingController();
  TextEditingController _artistSearchController = TextEditingController();
  bool _isLoading = true;
  bool _isSyncing = false;
  bool _isOffline = false;
  DateTime? _lastSyncDate;
  double _fontSize = 16.0;
  String? _loadingError;

  Set<int> _selectedTagIds = {};
  Set<int> _selectedArtistIds = {};
  List<Artist> _filteredArtists = [];
  bool _showArtistDropdown = false;

  static const double _minFontSize = 12.0;
  static const double _maxFontSize = 24.0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadLastSyncDate();
    _loadFontSize();
    _searchController.addListener(_filterSongs);
    _artistSearchController.addListener(_filterArtists);
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _loadingError = null;
      });

      if (kIsWeb) {
        await _loadFromAssets();
      } else {
        try {
          await _syncData();
        } catch (syncError) {
          print('Sync failed, loading from cache: $syncError');
          setState(() {
            _loadingError = null;
            _isLoading = true;
          });
          try {
            await _loadFromCache();
          } catch (cacheError) {
            print('Cache load failed, loading from assets: $cacheError');
            try {
              await _loadFromAssets();
            } catch (assetsError) {
              print('Assets load failed: $assetsError');
              throw Exception('All data loading methods failed');
            }
          }
        }
      }
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _loadingError = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadFromAssets() async {
    try {
      final data = await SongService.loadFromAssets();
      setState(() {
        _songs = data.songs;
        _allTags = data.tags;
        _allArtists = SongService.extractAllArtists(_songs);
        _filteredArtists = List.from(_allArtists);
        _filteredSongs = List.from(_songs);
        _isLoading = false;
        _loadingError = null;
      });
    } catch (e) {
      print('Asset load error: $e');
      setState(() {
        _isLoading = false;
        _loadingError =
            'Failed to load default data. Please connect to internet.';
      });
    }
  }

  Future<void> _loadFromCache() async {
    try {
      final data = await SongService.loadFromCache();
      setState(() {
        _songs = data.songs;
        _allTags = data.tags;
        _allArtists = SongService.extractAllArtists(_songs);
        _filteredArtists = List.from(_allArtists);
        _filteredSongs = List.from(_songs);
        _isLoading = false;
        _loadingError = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      throw Exception('Failed to load from cache: $e');
    }
  }

  Future<void> _syncData() async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
      _loadingError = null;
    });

    try {
      final data = await SongService.syncFromApi();

      setState(() {
        _songs = data.songs;
        _allTags = data.tags;
        _allArtists = SongService.extractAllArtists(_songs);
        _filteredArtists = List.from(_allArtists);
        _filteredSongs = List.from(_songs);
        _selectedTagIds = {};
        _selectedArtistIds = {};
        _isLoading = false;
      });

      await SongService.saveToCache(_songs, _allTags);
      _lastSyncDate = await SongService.saveLastSyncDate();
      setState(() {});

      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${l10n.syncSuccess} (${_songs.length} songs)')));
    } catch (e) {
      print('Error syncing data: $e');
      setState(() {
        _loadingError = e.toString();
        _isLoading = false;
      });
      rethrow;
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  Future<void> _loadFontSize() async {
    final savedFontSize = await SongService.loadListFontSize();
    setState(() {
      _fontSize = savedFontSize.clamp(_minFontSize, _maxFontSize);
    });
  }

  Future<void> _saveFontSize() async {
    await SongService.saveListFontSize(_fontSize);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _artistSearchController.dispose();
    super.dispose();
  }

  void _filterArtists() {
    final query = normalizeText(_artistSearchController.text);
    setState(() {
      _filteredArtists = _allArtists.where((artist) {
        return normalizeText(artist.name).contains(query);
      }).toList();
    });
  }

  void _toggleArtistFilter(int artistId) {
    setState(() {
      if (_selectedArtistIds.contains(artistId)) {
        _selectedArtistIds.remove(artistId);
      } else {
        _selectedArtistIds.add(artistId);
      }
      _filterSongs();
    });
  }

  String _getSelectedArtistsDisplayText() {
    if (_selectedArtistIds.isEmpty) {
      return AppLocalizations.of(context).allArtists;
    }

    final selectedArtists = _allArtists
        .where((artist) => _selectedArtistIds.contains(artist.id))
        .map((artist) => artist.name)
        .toList();

    if (selectedArtists.length <= 5) {
      return selectedArtists.join(', ');
    } else {
      final first5 = selectedArtists.take(5).toList();
      return '${first5.join(', ')}...';
    }
  }

  Future<void> _loadLastSyncDate() async {
    final date = await SongService.loadLastSyncDate();
    if (date != null) {
      setState(() {
        _lastSyncDate = date;
      });
    }
  }

  String _formatLastSync() {
    final l10n = AppLocalizations.of(context);
    if (_lastSyncDate == null) {
      return l10n.never;
    }
    final now = DateTime.now();
    final difference = now.difference(_lastSyncDate!);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${l10n.minAgo}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('dd.MM.yyyy HH:mm').format(_lastSyncDate!);
    }
  }

  Widget _buildSongListItem(Song song, bool isTablet) {
    if (isTablet) {
      return Card(
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SongDetailScreen(song: song),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    song.number?.toString() ?? '',
                    style: TextStyle(
                      fontSize: _fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    song.title,
                    style: TextStyle(
                      fontSize: _fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    song.artistNames,
                    style: TextStyle(fontSize: _fontSize * 0.9),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: song.tags.isNotEmpty
                      ? Wrap(
                          spacing: 4,
                          children: song.tags.take(4).map((tag) {
                            final tagColor = parseColor(tag.color) ??
                                Theme.of(context).primaryColor;
                            return Chip(
                              label: Text(
                                tag.name,
                                style: TextStyle(
                                  fontSize: _fontSize * 0.7,
                                  color: tagColor,
                                ),
                              ),
                              padding: EdgeInsets.zero,
                              labelPadding:
                                  EdgeInsets.symmetric(horizontal: 6),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: tagColor.withOpacity(0.1),
                              shape: StadiumBorder(
                                side: BorderSide(
                                    color: tagColor.withOpacity(0.3)),
                              ),
                            );
                          }).toList(),
                        )
                      : SizedBox(),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    song.bpm?.toString() ?? '',
                    style: TextStyle(fontSize: _fontSize * 0.9),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return ListTile(
        leading: song.number != null
            ? Container(
                width: 40,
                alignment: Alignment.center,
                child: Text(
                  song.number.toString(),
                  style: TextStyle(
                    fontSize: _fontSize,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        title: Text(
          song.title,
          style: TextStyle(fontSize: _fontSize),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (song.artists.isNotEmpty)
              Text(
                song.artistNames,
                style: TextStyle(fontSize: _fontSize * 0.9),
              ),
            if (song.bpm != null)
              Text(
                'BPM: ${song.bpm}',
                style: TextStyle(
                  fontSize: _fontSize * 0.8,
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
        trailing: song.tags.isNotEmpty
            ? Wrap(
                spacing: 4,
                children: song.tags.take(3).map((tag) {
                  final tagColor =
                      parseColor(tag.color) ?? Theme.of(context).primaryColor;
                  return Chip(
                    label: Text(
                      tag.name,
                      style: TextStyle(
                        fontSize: _fontSize * 0.7,
                        color: tagColor,
                      ),
                    ),
                    padding: EdgeInsets.zero,
                    labelPadding: EdgeInsets.symmetric(horizontal: 8),
                    backgroundColor: tagColor.withOpacity(0.1),
                    shape: StadiumBorder(
                      side: BorderSide(color: tagColor.withOpacity(0.3)),
                    ),
                  );
                }).toList(),
              )
            : null,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SongDetailScreen(song: song),
            ),
          );
        },
      );
    }
  }

  void _filterSongs() {
    final query = normalizeText(_searchController.text);
    setState(() {
      _filteredSongs = _songs.where((song) {
        final titleMatch = normalizeText(song.title).contains(query);
        final artistMatch = normalizeText(song.artistNames).contains(query);
        final lyricsMatch = normalizeText(song.lyrics).contains(query);
        final tagMatch = normalizeText(song.tagNames).contains(query);
        final numberMatch =
            song.number?.toString().contains(_searchController.text) ?? false;

        final tagFilter = _selectedTagIds.isEmpty ||
            song.tags.any((tag) => _selectedTagIds.contains(tag.id));

        final artistFilter = _selectedArtistIds.isEmpty ||
            song.artists
                .any((artist) => _selectedArtistIds.contains(artist.id));

        return (titleMatch ||
                artistMatch ||
                lyricsMatch ||
                tagMatch ||
                numberMatch) &&
            tagFilter &&
            artistFilter;
      }).toList();
    });
  }

  void _toggleTagFilter(int tagId) {
    setState(() {
      if (_selectedTagIds.contains(tagId)) {
        _selectedTagIds.remove(tagId);
      } else {
        _selectedTagIds.add(tagId);
      }
      _filterSongs();
    });
  }

  bool _isTablet(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final shortestSide = mediaQuery.size.shortestSide;
    return shortestSide > 600;
  }

  void _showFontSizeSettings() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.fontSize),
        content: StatefulBuilder(
          builder: (BuildContext dialogContext, StateSetter setStateDialog) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    '${l10n.fontSize}: ${(_fontSize / _minFontSize * 100).round()}%'),
                SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove),
                      onPressed: _fontSize > _minFontSize
                          ? () {
                              setState(() {
                                _fontSize = (_fontSize - 1.0)
                                    .clamp(_minFontSize, _maxFontSize);
                              });
                              _saveFontSize();
                              setStateDialog(() {});
                            }
                          : null,
                    ),
                    Text('${(_fontSize / _minFontSize * 100).round()}%'),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: _fontSize < _maxFontSize
                          ? () {
                              setState(() {
                                _fontSize = (_fontSize + 1.0)
                                    .clamp(_minFontSize, _maxFontSize);
                              });
                              _saveFontSize();
                              setStateDialog(() {});
                            }
                          : null,
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh),
                      onPressed: () {
                        setState(() {
                          _fontSize = 16.0;
                        });
                        _saveFontSize();
                        setStateDialog(() {});
                      },
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  void _navigateToSongSets() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SongSetsScreen(allSongs: _songs),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isTablet = _isTablet(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.title)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(_isSyncing ? l10n.syncing : 'Loading...'),
            ],
          ),
        ),
      );
    }

    if (_loadingError != null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.title)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_loadingError',
                  style: TextStyle(color: Colors.red)),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadData,
                child: Text('Retry'),
              ),
              if (!kIsWeb) SizedBox(height: 10),
              if (!kIsWeb)
                ElevatedButton(
                  onPressed: _loadFromAssets,
                  child: Text('Load from Assets'),
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.title),
        actions: [
          IconButton(
            iconSize: 36.0,
            icon: Icon(Icons.library_music),
            onPressed: _navigateToSongSets,
            tooltip: l10n.songSets,
          ),
          SizedBox(width: 12),
          IconButton(
            iconSize: 36.0,
            icon: Icon(Icons.text_fields),
            onPressed: _showFontSizeSettings,
            tooltip: l10n.fontSize,
          ),
          if (!_isOffline) ...[
            SizedBox(width: 12),
            IconButton(
              iconSize: 36.0,
              icon: _isSyncing
                  ? SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    )
                  : Icon(Icons.sync),
              onPressed: _isSyncing ? null : _syncData,
              tooltip: _isSyncing ? l10n.syncing : l10n.sync,
            ),
          ],
          SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: TextStyle(fontSize: _fontSize),
                  decoration: InputDecoration(
                    labelText: l10n.searchSongs,
                    labelStyle: TextStyle(fontSize: _fontSize),
                    hintText: l10n.searchHint,
                    hintStyle: TextStyle(fontSize: _fontSize * 0.9),
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                // Artist filter section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.artists,
                      style: TextStyle(
                        fontSize: _fontSize * 0.9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _selectedArtistIds.isEmpty
                              ? null
                              : () {
                                  setState(() {
                                    _selectedArtistIds.clear();
                                    _showArtistDropdown = false;
                                    _filterSongs();
                                  });
                                },
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            backgroundColor: _selectedArtistIds.isEmpty
                                ? Colors.grey[300]
                                : Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            l10n.allArtists,
                            style: TextStyle(fontSize: _fontSize * 0.9),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _showArtistDropdown = !_showArtistDropdown;
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _getSelectedArtistsDisplayText(),
                                      style:
                                          TextStyle(fontSize: _fontSize * 0.9),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(_showArtistDropdown
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_showArtistDropdown)
                      Container(
                        margin: EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.all(8),
                              child: TextField(
                                controller: _artistSearchController,
                                style: TextStyle(fontSize: _fontSize * 0.9),
                                decoration: InputDecoration(
                                  labelText: l10n.searchArtists,
                                  prefixIcon: Icon(Icons.search, size: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 8),
                                ),
                              ),
                            ),
                            Container(
                              height: 200,
                              child: ListView(
                                children: [
                                  CheckboxListTile(
                                    title: Text(
                                      l10n.allArtists,
                                      style: TextStyle(
                                        fontSize: _fontSize * 0.9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    value: _selectedArtistIds.isEmpty,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedArtistIds.clear();
                                        _filterSongs();
                                      });
                                    },
                                    dense: true,
                                  ),
                                  Divider(height: 1),
                                  ..._filteredArtists.map((artist) {
                                    final isSelected =
                                        _selectedArtistIds.contains(artist.id);
                                    return CheckboxListTile(
                                      title: Text(
                                        artist.name,
                                        style: TextStyle(
                                            fontSize: _fontSize * 0.9),
                                      ),
                                      value: isSelected,
                                      onChanged: (value) =>
                                          _toggleArtistFilter(artist.id),
                                      dense: true,
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 8),
                // Tag filter section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.tags,
                      style: TextStyle(
                        fontSize: _fontSize * 0.9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        FilterChip(
                          label: Text(l10n.allTags),
                          selected: _selectedTagIds.isEmpty,
                          onSelected: (_) {
                            setState(() {
                              _selectedTagIds.clear();
                              _filterSongs();
                            });
                          },
                          selectedColor:
                              Theme.of(context).primaryColor.withOpacity(0.2),
                          checkmarkColor: Theme.of(context).primaryColor,
                          labelStyle: TextStyle(
                            color: _selectedTagIds.isEmpty
                                ? Theme.of(context).primaryColor
                                : null,
                          ),
                        ),
                        ..._allTags.map((tag) {
                          final isSelected = _selectedTagIds.contains(tag.id);
                          final tagColor = parseColor(tag.color) ??
                              Theme.of(context).primaryColor;
                          return FilterChip(
                            label: Text(
                              tag.name,
                              style: TextStyle(
                                color: isSelected ? tagColor : null,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) => _toggleTagFilter(tag.id),
                            selectedColor: tagColor.withOpacity(0.2),
                            checkmarkColor: tagColor,
                            backgroundColor: tagColor.withOpacity(0.1),
                            shape: StadiumBorder(
                              side:
                                  BorderSide(color: tagColor.withOpacity(0.3)),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ],
                ),
                if (_lastSyncDate != null || _isSyncing)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '${l10n.lastSync} ${_formatLastSync()}',
                      style: TextStyle(
                        fontSize: _fontSize * 0.8,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (isTablet && _filteredSongs.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Text(
                      l10n.tableHeaderNumber,
                      style: TextStyle(
                        fontSize: _fontSize * 0.9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      l10n.tableHeaderTitle,
                      style: TextStyle(
                        fontSize: _fontSize * 0.9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      l10n.tableHeaderArtist,
                      style: TextStyle(
                        fontSize: _fontSize * 0.9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      l10n.tableHeaderTags,
                      style: TextStyle(
                        fontSize: _fontSize * 0.9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      l10n.tableHeaderBpm,
                      style: TextStyle(
                        fontSize: _fontSize * 0.9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _filteredSongs.isEmpty
                ? Center(
                    child: Text(
                      l10n.noSongsFound,
                      style: TextStyle(fontSize: _fontSize),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredSongs.length,
                    itemBuilder: (context, index) {
                      final song = _filteredSongs[index];
                      return _buildSongListItem(song, isTablet);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
