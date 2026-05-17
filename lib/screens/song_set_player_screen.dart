import 'package:flutter/material.dart';

import '../models/song.dart';
import '../models/song_set.dart';
import 'song_detail_screen.dart';

class SongSetPlayerScreen extends StatefulWidget {
  final SongSet songSet;
  final List<Song> songs;

  const SongSetPlayerScreen({
    Key? key,
    required this.songSet,
    required this.songs,
  }) : super(key: key);

  @override
  _SongSetPlayerScreenState createState() => _SongSetPlayerScreenState();
}

class _SongSetPlayerScreenState extends State<SongSetPlayerScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToFirst() {
    _pageController.animateToPage(
      0,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNext() {
    if (_currentIndex < widget.songs.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToLast() {
    _pageController.animateToPage(
      widget.songs.length - 1,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.songSet.name),
        actions: [
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${_currentIndex + 1} / ${widget.songs.length}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.first_page),
                  onPressed: _currentIndex > 0 ? _goToFirst : null,
                  tooltip: 'First',
                  iconSize: 32,
                ),
                IconButton(
                  icon: Icon(Icons.chevron_left),
                  onPressed: _currentIndex > 0 ? _goToPrevious : null,
                  tooltip: 'Previous',
                  iconSize: 32,
                ),
                IconButton(
                  icon: Icon(Icons.chevron_right),
                  onPressed: _currentIndex < widget.songs.length - 1
                      ? _goToNext
                      : null,
                  tooltip: 'Next',
                  iconSize: 32,
                ),
                IconButton(
                  icon: Icon(Icons.last_page),
                  onPressed: _currentIndex < widget.songs.length - 1
                      ? _goToLast
                      : null,
                  tooltip: 'Last',
                  iconSize: 32,
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: widget.songs.length,
              itemBuilder: (context, index) {
                return SongDetailScreen(song: widget.songs[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
