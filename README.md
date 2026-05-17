# Spevník

A Flutter app for managing and displaying song lyrics with chords. Built as a personal gift — a custom songbook for my dad.

> **Spevník** is Slovak for "songbook". Primary locale: `sk_SK`.

## Features

- Browse songs by title, artist, or tag
- Lyrics with **inline chord notation** (rendered via HTML `<sup>` tags)
- **Song sets** — grouped playlists for gigs / rehearsals
- Local-first: songs cached in `SharedPreferences`, synced from an optional remote API
- Targets **Android, iOS, macOS, Linux, Windows, and Web** from one codebase

## Stack

- **Flutter 3.6+** / Dart
- `flutter_quill` ^11 for rich-text editing
- `path_provider` + `shared_preferences` for local persistence
- `intl` + `flutter_localizations` for Slovak locale

## Architecture

```
lib/
├── main.dart                  # Entry point
├── app.dart                   # MaterialApp + theme + l10n setup
├── models/
│   ├── artist.dart            # id, name
│   ├── tag.dart               # id, name, color (hex)
│   ├── song.dart              # id, title, lyrics, number, bpm, artists, tags
│   └── song_set.dart          # id, name, songIds, timestamps
├── services/
│   └── song_service.dart      # API sync, local cache, asset loading
├── screens/                   # UI pages
├── utils/
├── l10n/                      # Slovak translations
└── ...
```

## Common commands

```bash
flutter pub get                # install deps
flutter run                    # run on connected device / simulator
flutter test                   # run unit + widget tests
flutter analyze                # static analysis
dart format lib/               # auto-format

flutter build apk              # Android
flutter build ios              # iOS (needs Xcode)
flutter build macos            # macOS
flutter build web              # Web
```

## License

[MIT](LICENSE) © Michal Čečko

## API credentials (build-time)

The app authenticates to `adminka.synapps.sk/api/*` via HTTP Basic Auth. Credentials are injected at build time using `--dart-define`:

```bash
flutter run \
  --dart-define=SONGBOOK_API_USER=api_user \
  --dart-define=SONGBOOK_API_PASSWORD=<secret>

flutter build apk \
  --dart-define=SONGBOOK_API_USER=api_user \
  --dart-define=SONGBOOK_API_PASSWORD=<secret>
```

Optional overrides: `SONGBOOK_API_URL`, `SONGBOOK_TAGS_API_URL`.

If unset, the API calls fail unauthorized and the app falls back to the bundled `assets/songs.json` demo data.
