# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Spevník** (Slovak for "Songbook") — a Flutter app for managing and displaying song lyrics with chords. Targets Android, iOS, macOS, Linux, Windows, and Web. The primary locale is Slovak (sk_SK). Package name is `spevnik`.

## Common Commands

```bash
# Run the app
flutter run

# Run tests
flutter test

# Run a single test file
flutter test test/widget_test.dart

# Static analysis
flutter analyze

# Format code
dart format lib/

# Get dependencies
flutter pub get

# Build APK
flutter build apk

# Build iOS
flutter build ios
```

## Architecture

```
lib/
├── main.dart                  # Entry point (runApp only)
├── app.dart                   # MaterialApp widget, theme, localization setup
├── models/
│   ├── artist.dart            # Artist model (id, name)
│   ├── tag.dart               # Tag model (id, name, color hex)
│   ├── song.dart              # Song model (id, title, lyrics, number, bpm, artists, tags)
│   └── song_set.dart          # SongSet model (id, name, songIds, timestamps)
├── services/
│   └── song_service.dart      # API sync, local cache, asset loading, SharedPreferences
├── l10n/
│   └── app_localizations.dart # AppLocalizations with en/sk string dictionaries + delegate
├── utils/
│   ├── text_utils.dart        # normalizeText (Slovak diacritics), stripHtmlTags
│   └── color_utils.dart       # parseColor (hex string to Color)
├── screens/
│   ├── song_list_screen.dart  # Home screen: search, tag/artist filters, responsive list
│   ├── song_detail_screen.dart # Song lyrics with HTML parsing, chord display modes
│   ├── song_sets_screen.dart  # Song set management (CRUD)
│   ├── edit_song_set_screen.dart # Edit/create a song set with reorderable list
│   └── song_set_player_screen.dart # Paginated player for a set
```

### State Management

Uses `StatefulWidget` + `setState()` throughout. No Provider, Riverpod, or Bloc.

### Data Flow

`SongService` (all static methods) handles data loading with a fallback chain:
1. **API sync** — fetches from `https://dashboard.cecko.dev/api/` (endpoints: `/songs`, `/song-tags`) using HTTP Basic Auth
2. **Local cache** — JSON files (`songs.json`, `tags.json`) in app documents directory via `path_provider`
3. **Bundled assets** — `assets/songs.json` as final fallback

On web, only asset loading is used (no local cache).

User preferences (font sizes, last sync date, song sets) are stored via `SharedPreferences`, accessed through `SongService`.

### Search & Filtering

Full-text search across title, artist names, lyrics, tags, and song numbers. Supports multi-select tag and artist filtering. Text is normalized for Slovak diacritics via `normalizeText()` in `utils/text_utils.dart`.

### Internationalization

Custom `AppLocalizations` class in `l10n/app_localizations.dart` with hardcoded string dictionaries for `en_US` and `sk_SK`. Uses `intl` package and Flutter's localization delegates.

### Key Dependencies

- `path_provider` — local file system access
- `shared_preferences` — persistent key-value storage
- `flutter_quill` — rich text rendering for lyrics/chords
- `intl` + `flutter_localizations` — i18n support
- `http` — API calls

### Android Signing

Release builds require a `key.properties` file in `android/` with signing configuration. Application ID: `com.example.songbook_app`.
