# Crazy Hen Run

An offline habit tracker for Android. Every habit you close turns into distance
on a running track, and the hen in your pocket levels up as that distance grows.

## Running it

```bash
flutter pub get
flutter run
```

The app targets Android only. Release builds are intentionally not part of the
normal workflow — build one when you are ready to ship:

```bash
flutter build apk --release
```

## Identity

| | |
|---|---|
| Bundle ID | `com.crazyhenrun.crazyhenrungame` |
| App ID | `6790464294` |
| Privacy Policy | https://crazyhennrun.com/privacy-policy.html |
| Support | https://crazyhennrun.com/support.html |

## How it is put together

```
lib/
  core/        constants, theme (colours, typography, spacing), small utilities
  data/        models + the SharedPreferences backed local store
  state/       AppState — a single ChangeNotifier holding all app logic
  ui/
    widgets/   the design system (cards, rings, track bar, heatmap, hen art)
    screens/   one folder per feature area
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

`ui/screens/web/web_page_screen.dart` loads the live pages in a WebView and
injects CSS so the text is always black on white. If the network fails or
stalls, the bundled copy in `core/constants/offline_pages.dart` is shown
instead — the pages are therefore reachable with or without a connection.

### Assets

`tool/webp_to_png.dart` renders previews of the WebP artwork, and
`tool/prepare_icons.dart` regenerates the adaptive launcher icon layers.
After changing `assets/icon.png`:

```bash
dart run tool/prepare_icons.dart
dart run flutter_launcher_icons
```
