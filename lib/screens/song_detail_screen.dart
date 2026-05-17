import 'package:flutter/material.dart';

import '../models/song.dart';
import '../services/song_service.dart';
import '../l10n/app_localizations.dart';
import '../utils/text_utils.dart';

enum ChordDisplayMode { plain, chords }

class SongDetailScreen extends StatefulWidget {
  final Song song;

  const SongDetailScreen({Key? key, required this.song}) : super(key: key);

  @override
  _SongDetailScreenState createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen> {
  ChordDisplayMode _displayMode = ChordDisplayMode.chords;
  double _fontSize = 16.0;
  static const double _minFontSize = 16.0;
  static const double _maxFontSize = 64.0;
  static const double _dialogFontSize = 16.0;

  @override
  void initState() {
    super.initState();
    _loadFontSize();
  }

  Future<void> _loadFontSize() async {
    final savedFontSize = await SongService.loadSongFontSize();
    setState(() {
      _fontSize = savedFontSize.clamp(_minFontSize, _maxFontSize);
    });
  }

  Future<void> _saveFontSize() async {
    await SongService.saveSongFontSize(_fontSize);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.song.number != null
            ? '${widget.song.number}. ${widget.song.title}'
            : widget.song.title),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: _showDisplayOptions,
            tooltip: l10n.displayOptions,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.song.number != null
                  ? '${widget.song.number}. ${widget.song.title}'
                  : widget.song.title,
              style: TextStyle(
                fontSize: _fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                if (widget.song.artists.isNotEmpty)
                  Expanded(
                    child: Text(
                      "by ${widget.song.artistNames}",
                      style: TextStyle(
                        fontSize: _fontSize,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16),
            if (widget.song.tags.isNotEmpty)
              Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (widget.song.bpm != null)
                      Chip(
                        label: Text(
                          '${l10n.tableHeaderBpm}: ${widget.song.bpm}',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: _fontSize * 0.8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor:
                            Theme.of(context).primaryColor.withOpacity(0.1),
                        shape: StadiumBorder(
                          side: BorderSide(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.5)),
                        ),
                      ),
                    ...widget.song.tags.map((tag) {
                      final tagColor = tag.color != null
                          ? Color(int.parse(
                              tag.color!.replaceAll('#', 'FF'),
                              radix: 16))
                          : Theme.of(context).primaryColor;
                      return Chip(
                        label: Text(
                          tag.name,
                          style: TextStyle(
                            color: tagColor,
                            fontSize: _fontSize * 0.8,
                          ),
                        ),
                        backgroundColor: tagColor.withOpacity(0.1),
                        shape: StadiumBorder(
                          side:
                              BorderSide(color: tagColor.withOpacity(0.5)),
                        ),
                      );
                    }).toList(),
                  ]),
            SizedBox(height: 24),
            _buildLyricsWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildLyricsWidget() {
    if (_displayMode == ChordDisplayMode.plain) {
      String plainText = stripHtmlTags(widget.song.lyrics);
      return Text(
        plainText,
        style: TextStyle(fontSize: _fontSize, height: 1.5),
      );
    }

    return RichText(
      text: _parseLyrics(widget.song.lyrics),
      textAlign: TextAlign.left,
    );
  }

  TextSpan _parseLyrics(String lyrics) {
    final List<InlineSpan> spans = [];

    String content = lyrics
        .replaceAll(RegExp(r'<p[^>]*>'), '')
        .replaceAll('</p>', '\n')
        .replaceAll('<br>', '\n')
        .replaceAll('<br/>', '\n')
        .replaceAll('<br />', '\n')
        .trim();

    final parts = <String>[];
    final buffer = StringBuffer();
    int i = 0;

    while (i < content.length) {
      if (content[i] == '<') {
        if (buffer.isNotEmpty) {
          parts.add(buffer.toString());
          buffer.clear();
        }

        int tagEnd = content.indexOf('>', i);
        if (tagEnd != -1) {
          parts.add(content.substring(i, tagEnd + 1));
          i = tagEnd + 1;
        } else {
          buffer.write(content[i]);
          i++;
        }
      } else {
        buffer.write(content[i]);
        i++;
      }
    }

    if (buffer.isNotEmpty) {
      parts.add(buffer.toString());
    }

    bool isBold = false;
    bool isItalic = false;
    bool isUnderlined = false;
    bool isSuperscript = false;

    for (String part in parts) {
      if (part.startsWith('<')) {
        if (part == '<sup>') {
          isSuperscript = true;
        } else if (part == '</sup>') {
          isSuperscript = false;
        } else if (part == '<b>' || part == '<strong>') {
          isBold = true;
        } else if (part == '</b>' || part == '</strong>') {
          isBold = false;
        } else if (part == '<i>' || part == '<em>') {
          isItalic = true;
        } else if (part == '</i>' || part == '</em>') {
          isItalic = false;
        } else if (part == '<u>') {
          isUnderlined = true;
        } else if (part == '</u>') {
          isUnderlined = false;
        }
      } else {
        if (part.isNotEmpty) {
          if (isSuperscript) {
            _addSuperscriptContent(part, spans);
          } else {
            _addTextWithStyle(part, spans, isBold, isItalic, isUnderlined);
          }
        }
      }
    }

    return TextSpan(children: spans);
  }

  void _addSuperscriptContent(String content, List<InlineSpan> spans) {
    String decodedContent = content
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&#039;', "'")
        .replaceAll('&apos;', "'");

    List<String> lines = decodedContent.split('\n');

    for (int i = 0; i < lines.length; i++) {
      if (lines[i].isNotEmpty) {
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Transform.translate(
            offset: Offset(0, -10),
            child: Text(
              lines[i],
              style: TextStyle(
                fontSize: _fontSize * 0.7,
                color: Colors.indigoAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ));
      }

      if (i < lines.length - 1) {
        spans.add(TextSpan(text: '\n'));
      }
    }
  }

  void _addTextWithStyle(String text, List<InlineSpan> spans, bool isBold,
      bool isItalic, bool isUnderlined) {
    String decodedText = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&#039;', "'")
        .replaceAll('&apos;', "'");

    List<String> lines = decodedText.split('\n');

    for (int i = 0; i < lines.length; i++) {
      if (lines[i].isNotEmpty) {
        spans.add(TextSpan(
          text: lines[i],
          style: TextStyle(
            fontSize: _fontSize,
            height: 1.5,
            color: Colors.black,
            fontWeight: isBold ? FontWeight.bold : null,
            fontStyle: isItalic ? FontStyle.italic : null,
            decoration: isUnderlined ? TextDecoration.underline : null,
          ),
        ));
      }

      if (i < lines.length - 1) {
        spans.add(TextSpan(text: '\n'));
      }
    }
  }

  void _showDisplayOptions() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.displayOptions,
            style: TextStyle(fontSize: _dialogFontSize)),
        content: StatefulBuilder(
          builder: (BuildContext dialogContext, StateSetter setStateDialog) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(l10n.plainLyrics,
                      style: TextStyle(fontSize: _dialogFontSize)),
                  leading: Radio<ChordDisplayMode>(
                    value: ChordDisplayMode.plain,
                    groupValue: _displayMode,
                    onChanged: (value) {
                      setState(() {
                        _displayMode = value!;
                      });
                      Navigator.pop(context);
                    },
                  ),
                ),
                ListTile(
                  title: Text(l10n.withChords,
                      style: TextStyle(fontSize: _dialogFontSize)),
                  leading: Radio<ChordDisplayMode>(
                    value: ChordDisplayMode.chords,
                    groupValue: _displayMode,
                    onChanged: (value) {
                      setState(() {
                        _displayMode = value!;
                      });
                      Navigator.pop(context);
                    },
                  ),
                ),
                SizedBox(height: 16),
                Text(l10n.fontSize,
                    style: TextStyle(fontSize: _dialogFontSize)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove, size: _dialogFontSize),
                      onPressed: _fontSize > _minFontSize
                          ? () {
                              setState(() {
                                _fontSize = (_fontSize - 2.0)
                                    .clamp(_minFontSize, _maxFontSize);
                              });
                              _saveFontSize();
                              setStateDialog(() {});
                            }
                          : null,
                      tooltip: l10n.fontSize,
                    ),
                    Text(
                      '${(_fontSize / _minFontSize * 100).round()}%',
                      style: TextStyle(fontSize: _dialogFontSize),
                    ),
                    IconButton(
                      icon: Icon(Icons.add, size: _dialogFontSize),
                      onPressed: _fontSize < _maxFontSize
                          ? () {
                              setState(() {
                                _fontSize = (_fontSize + 2.0)
                                    .clamp(_minFontSize, _maxFontSize);
                              });
                              _saveFontSize();
                              setStateDialog(() {});
                            }
                          : null,
                      tooltip: l10n.fontSize,
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh, size: _dialogFontSize),
                      onPressed: () {
                        setState(() {
                          _fontSize = _minFontSize;
                        });
                        _saveFontSize();
                        setStateDialog(() {});
                      },
                      tooltip: 'Reset Font Size',
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
            child:
                Text(l10n.close, style: TextStyle(fontSize: _dialogFontSize)),
          ),
        ],
      ),
    );
  }
}
