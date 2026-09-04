# Crazy Hen Run

An offline habit tracker and running companion for iOS and Android. Every habit
you close turns into distance on a track, and the hen in your pocket levels up
as that distance grows.

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

There is no product backend and no account. Habits, logs, journal entries
and the profile photo live on the device. AppsFlyer measures installs and
anonymous usage only.

### Loading screen

`ui/screens/splash/loading_screen.dart` drives the bar through fixed
milestones. The percentage and the bar are rendered from the same value, so
they can never disagree, and 100% is only reached once initialisation has
finished. Portrait and landscape artwork are both supported; the rest of the
app is portrait only.

### Privacy Policy and Support

`ui/screens/legal/legal_doc_screen.dart` renders the bundled copy from
`foundation/constants/embedded_docs.dart` as native Flutter widgets. Optional
Email and Safari buttons leave the app via the system Mail composer or the
system browser. There is no in-app WebView.

### Assets

`tool/webp_to_png.dart` renders previews of the WebP artwork, and
`tool/prepare_icons.dart` regenerates the adaptive launcher icon layers.
After changing `assets/henyard_mark.png`:

```bash
dart run tool/prepare_icons.dart
dart run flutter_launcher_icons
```
