import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_assets.dart';
import 'core/constants/app_config.dart';
import 'core/services/pedometer_service.dart';
import 'core/theme/app_palette.dart';
import 'core/theme/app_theme.dart';
import 'data/local_store.dart';
import 'state/app_state.dart';
import 'state/run_state.dart';
import 'ui/screens/onboarding/onboarding_screen.dart';
import 'ui/screens/root_shell.dart';
import 'ui/screens/splash/loading_screen.dart';

class CrazyHenRunApp extends StatefulWidget {
  const CrazyHenRunApp({super.key});

  @override
  State<CrazyHenRunApp> createState() => _CrazyHenRunAppState();
}

class _CrazyHenRunAppState extends State<CrazyHenRunApp> {
  AppState? _state;
  RunState? _runState;
  bool _booted = false;

  static const List<String> _preloadable = <String>[
    AppAssets.logo,
    AppAssets.background,
    AppAssets.henChick,
    AppAssets.henStanding,
    AppAssets.henRunner,
    AppAssets.henSprinter,
    AppAssets.henLegend,
    AppAssets.henHappy,
    AppAssets.henCoach,
    AppAssets.henCurious,
  ];

  Future<void> _warmUp() async {
    final store = await LocalStore.open();
    _state = AppState(store);
    _runState = RunState(store, PedometerService());

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
        title: AppConfig.appName,
        theme: AppTheme.light(Brand.moss),
        home: LoadingScreen(warmUp: _warmUp, onFinished: _onBootFinished),
      );
    }

    return MultiProvider(
      providers: <ChangeNotifierProvider<dynamic>>[
        ChangeNotifierProvider<AppState>.value(value: state),
        ChangeNotifierProvider<RunState>.value(value: runState),
      ],
      child: Consumer<AppState>(
        builder: (context, app, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: AppConfig.appName,
            themeMode: app.themeMode,
            theme: AppTheme.light(app.accentColor),
            darkTheme: AppTheme.dark(app.accentColor),
            builder: (context, child) => MediaQuery.withClampedTextScaling(
              minScaleFactor: 1,
              maxScaleFactor: 1.15,
              child: child ?? const SizedBox.shrink(),
            ),
            home: app.onboarded ? const RootShell() : const OnboardingScreen(),
          );
        },
      ),
    );
  }
}
