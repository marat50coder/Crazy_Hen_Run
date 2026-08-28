# Henyard Daily

An offline habit tracker for iOS and Android. Every habit you close turns into
distance on a running track, and the hen in your pocket levels up as that
distance grows.

## Running it

```bash
flutter pub get
flutter run
```

Release builds are intentionally not part of the normal workflow — build one
when you are ready to ship:

```bash
flutter build apk --release
flutter build ipa --release
```

## Identity

| | |
|---|---|
| Product name | Crazy Hen Run |
| Bundle ID | `com.crazyhenrun.crazyhenrungame` |
| App ID | `6790464294` |
| Privacy Policy | https://crazyhennrun.com/privacy-policy.html |
| Support | https://crazyhennrun.com/support.html |

## How the source is laid out

```
lib/
  foundation/    constants, theme (colours, typography, spacing), utilities
  persistence/   models + the SharedPreferences-backed snapshot store
  domain/        HenState and RunTracker — ChangeNotifiers driving the UI
  ui/
    widgets/     the design system (cards, rings, track bar, heatmap, hen art)
    screens/     one folder per feature area
```

There is no backend, no account and no analytics. Habits, logs, journal
entries and the profile photo live on the device.

### Loading screen

`ui/screens/splash/loading_screen.dart` drives the bar through fixed
milestones. The percentage and the bar are rendered from the same value, so
they can never disagree, and 100% is only reached once initialisation has
finished. Portrait and landscape artwork are both supported; the rest of the
app is portrait only.

### Privacy Policy and Support

`ui/screens/web/web_doc_screen.dart` loads the live pages in a WebView and
injects the reader stylesheet from `web_reader_style.dart` so the text is
always black on white. If the network fails or stalls, the bundled copy in
`foundation/constants/embedded_docs.dart` is shown instead — the pages are
therefore reachable with or without a connection.

### Assets

`tool/webp_to_png.dart` renders previews of the WebP artwork, and
`tool/prepare_icons.dart` regenerates the adaptive launcher icon layers.
After changing `assets/icon.png`:

```bash
dart run tool/prepare_icons.dart
dart run flutter_launcher_icons
```
