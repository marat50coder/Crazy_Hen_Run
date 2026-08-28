import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'foundation/constants/artwork.dart';
import 'foundation/constants/app_meta.dart';
import 'foundation/services/step_feed.dart';
import 'foundation/theme/palette.dart';
import 'foundation/theme/henyard_theme.dart';
import 'persistence/snapshot_store.dart';
import 'domain/hen_state.dart';
import 'domain/run_tracker.dart';
import 'ui/screens/onboarding/onboarding_screen.dart';
import 'ui/screens/root_shell.dart';
import 'ui/screens/splash/loading_screen.dart';

class HenyardApp extends StatefulWidget {
  const HenyardApp({super.key});

  @override
  State<HenyardApp> createState() => _CrazyHenRunAppState();
}

class _CrazyHenRunAppState extends State<HenyardApp> {
  HenState? _state;
  RunTracker? _runState;
  bool _booted = false;

  static const List<String> _preloadable = <String>[
    Artwork.logo,
    Artwork.background,
    Artwork.henChick,
    Artwork.henStanding,
    Artwork.henRunner,
    Artwork.henSprinter,
    Artwork.henLegend,
    Artwork.henHappy,
    Artwork.henCoach,
    Artwork.henCurious,
  ];

  Future<void> _warmUp() async {
    final store = await SnapshotStore.open();
    _state = HenState(store);
    _runState = RunTracker(store, StepFeed());

    // Decode the artwork up front so the first real screen never pops in.
    await Future.wait(
      _preloadable.map((path) async {
        final stream =
            AssetImage(path).resolve(ImageConfiguration.empty);
        final completer = Completer<void>();
        late final ImageStreamListener listener;
        listener = ImageStreamListener(
          (_, _) {
            stream.removeListener(listener);
            if (!completer.isCompleted) completer.complete();
          },
          onError: (_, _) {
            stream.removeListener(listener);
            if (!completer.isCompleted) completer.complete();
          },
        );
        stream.addListener(listener);
        return completer.future;
      }),
    );
  }

  void _onBootFinished() {
    // The app itself is portrait only; the loading screen was the one place
    // where landscape is allowed.
    SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    setState(() => _booted = true);
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    final runState = _runState;
    if (!_booted || state == null || runState == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: AppMeta.appName,
        theme: HenyardTheme.light(Meadow.moss),
        home: BootScreen(warmUp: _warmUp, onFinished: _onBootFinished),
      );
    }

    return MultiProvider(
      providers: <ChangeNotifierProvider<dynamic>>[
        ChangeNotifierProvider<HenState>.value(value: state),
        ChangeNotifierProvider<RunTracker>.value(value: runState),
      ],
      child: Consumer<HenState>(
        builder: (context, app, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: AppMeta.appName,
            themeMode: app.themeMode,
            theme: HenyardTheme.light(app.accentColor),
            darkTheme: HenyardTheme.dark(app.accentColor),
            builder: (context, child) => MediaQuery.withClampedTextScaling(
              minScaleFactor: 1,
              maxScaleFactor: 1.15,
              child: child ?? const SizedBox.shrink(),
            ),
            home: app.onboarded ? const AppShell() : const WelcomeScreen(),
          );
        },
      ),
    );
  }
}
