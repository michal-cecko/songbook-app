import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const _localizedValues = {
    'en': {
      'title': 'Songbook',
      'search_songs': 'Search songs',
      'search_hint': 'Search by title, artist, lyrics or tag',
      'no_songs_found': 'No songs found',
      'display_options': 'Display Options',
      'plain_lyrics': 'Plain Lyrics',
      'with_chords': 'With Chords',
      'close': 'Close',
      'sync': 'Sync',
      'sync_success': 'Songs synced successfully',
      'sync_error': 'Sync failed',
      'last_sync': 'Last sync:',
      'never': 'Never',
      'syncing': 'Syncing...',
      'fontSize': 'Font Size',
      'superscript': 'Superscript',
      'tags': 'Tags',
      'all_tags': 'All Tags',
      'artists': 'Artists',
      'all_artists': 'All Artists',
      'search_artists': 'Search artists',
      'table_header_number': '#',
      'table_header_title': 'Song Title',
      'table_header_artist': 'Artist',
      'table_header_tags': 'Tags',
      'table_header_bpm': 'BPM',
      'song_sets': 'Song Sets',
      'create_set': 'Create Set',
      'edit_set': 'Edit Set',
      'delete_set': 'Delete Set',
      'set_name': 'Set Name',
      'add_songs': 'Add Songs',
      'start_set': 'Start Set',
      'no_sets': 'No song sets yet',
      'create_first_set': 'Create your first set',
      'songs_in_set': 'songs',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'confirm_delete': 'Are you sure you want to delete this set?',
      'select_songs': 'Select Songs',
      'add_to_set': 'Add to Set',
      'remove_from_set': 'Remove from Set',
      'no_songs_in_set': 'No songs in this set',
      'add_songs_to_start': 'Add songs to start playing',
      'min_ago': 'min',
    },
    'sk': {
      'title': 'Spevník',
      'search_songs': 'Hľadať piesne',
      'search_hint': 'Hľadať podľa názvu, interpreta, textu alebo značky',
      'no_songs_found': 'Žiadne piesne nenájdené',
      'display_options': 'Možnosti zobrazenia',
      'plain_lyrics': 'Čistý text',
      'with_chords': 'S akordmi',
      'close': 'Zavrieť',
      'sync': 'Synchronizovať',
      'sync_success': 'Piesne boli úspešne synchronizované',
      'sync_error': 'Synchronizácia zlyhala',
      'last_sync': 'Posledná synch.:',
      'never': 'Nikdy',
      'syncing': 'Synchronizuje sa...',
      'fontSize': 'Veľkosť písma',
      'superscript': 'Horný index',
      'tags': 'Značky',
      'all_tags': 'Všetky značky',
      'artists': 'Interpreti',
      'all_artists': 'Všetci interpreti',
      'search_artists': 'Hľadať interpretov',
      'table_header_number': '#',
      'table_header_title': 'Názov piesne',
      'table_header_artist': 'Interpret',
      'table_header_tags': 'Značky',
      'table_header_bpm': 'Údery',
      'song_sets': 'Sety piesní',
      'create_set': 'Vytvoriť set',
      'edit_set': 'Upraviť set',
      'delete_set': 'Zmazať set',
      'set_name': 'Názov setu',
      'add_songs': 'Pridať piesne',
      'start_set': 'Spustiť set',
      'no_sets': 'Zatiaľ žiadne sety',
      'create_first_set': 'Vytvorte svoj prvý set',
      'songs_in_set': 'piesní',
      'cancel': 'Zrušiť',
      'save': 'Uložiť',
      'delete': 'Zmazať',
      'confirm_delete': 'Naozaj chcete zmazať tento set?',
      'select_songs': 'Vybrať piesne',
      'add_to_set': 'Pridať do setu',
      'remove_from_set': 'Odstrániť zo setu',
      'no_songs_in_set': 'Žiadne piesne v tomto sete',
      'add_songs_to_start': 'Pridajte piesne na začiatok prehrávania',
      'min_ago': 'min',
    },
  };

  String get title => _localizedValues[locale.languageCode]!['title']!;

  String get searchSongs =>
      _localizedValues[locale.languageCode]!['search_songs']!;

  String get searchHint =>
      _localizedValues[locale.languageCode]!['search_hint']!;

  String get noSongsFound =>
      _localizedValues[locale.languageCode]!['no_songs_found']!;

  String get displayOptions =>
      _localizedValues[locale.languageCode]!['display_options']!;

  String get plainLyrics =>
      _localizedValues[locale.languageCode]!['plain_lyrics']!;

  String get withChords =>
      _localizedValues[locale.languageCode]!['with_chords']!;

  String get close => _localizedValues[locale.languageCode]!['close']!;

  String get sync => _localizedValues[locale.languageCode]!['sync']!;

  String get syncSuccess =>
      _localizedValues[locale.languageCode]!['sync_success']!;

  String get syncError =>
      _localizedValues[locale.languageCode]!['sync_error']!;

  String get lastSync =>
      _localizedValues[locale.languageCode]!['last_sync']!;

  String get never => _localizedValues[locale.languageCode]!['never']!;

  String get syncing => _localizedValues[locale.languageCode]!['syncing']!;

  String get fontSize =>
      _localizedValues[locale.languageCode]!['fontSize']!;

  String get superscript =>
      _localizedValues[locale.languageCode]!['superscript']!;

  String get tags => _localizedValues[locale.languageCode]!['tags']!;

  String get allTags =>
      _localizedValues[locale.languageCode]!['all_tags']!;

  String get artists =>
      _localizedValues[locale.languageCode]!['artists']!;

  String get allArtists =>
      _localizedValues[locale.languageCode]!['all_artists']!;

  String get searchArtists =>
      _localizedValues[locale.languageCode]!['search_artists']!;

  String get tableHeaderNumber =>
      _localizedValues[locale.languageCode]!['table_header_number']!;

  String get tableHeaderTitle =>
      _localizedValues[locale.languageCode]!['table_header_title']!;

  String get tableHeaderArtist =>
      _localizedValues[locale.languageCode]!['table_header_artist']!;

  String get tableHeaderTags =>
      _localizedValues[locale.languageCode]!['table_header_tags']!;

  String get songSets =>
      _localizedValues[locale.languageCode]!['song_sets']!;

  String get createSet =>
      _localizedValues[locale.languageCode]!['create_set']!;

  String get tableHeaderBpm =>
      _localizedValues[locale.languageCode]!['table_header_bpm']!;

  String get editSet =>
      _localizedValues[locale.languageCode]!['edit_set']!;

  String get deleteSet =>
      _localizedValues[locale.languageCode]!['delete_set']!;

  String get setName =>
      _localizedValues[locale.languageCode]!['set_name']!;

  String get addSongs =>
      _localizedValues[locale.languageCode]!['add_songs']!;

  String get startSet =>
      _localizedValues[locale.languageCode]!['start_set']!;

  String get noSets => _localizedValues[locale.languageCode]!['no_sets']!;

  String get createFirstSet =>
      _localizedValues[locale.languageCode]!['create_first_set']!;

  String get songsInSet =>
      _localizedValues[locale.languageCode]!['songs_in_set']!;

  String get cancel =>
      _localizedValues[locale.languageCode]!['cancel']!;

  String get save => _localizedValues[locale.languageCode]!['save']!;

  String get delete =>
      _localizedValues[locale.languageCode]!['delete']!;

  String get confirmDelete =>
      _localizedValues[locale.languageCode]!['confirm_delete']!;

  String get selectSongs =>
      _localizedValues[locale.languageCode]!['select_songs']!;

  String get addToSet =>
      _localizedValues[locale.languageCode]!['add_to_set']!;

  String get removeFromSet =>
      _localizedValues[locale.languageCode]!['remove_from_set']!;

  String get noSongsInSet =>
      _localizedValues[locale.languageCode]!['no_songs_in_set']!;

  String get addSongsToStart =>
      _localizedValues[locale.languageCode]!['add_songs_to_start']!;

  String get minAgo =>
      _localizedValues[locale.languageCode]!['min_ago']!;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'sk'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) =>
      Future.value(AppLocalizations(locale));

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
