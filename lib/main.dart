import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'gate_app.dart';
import 'paddock/config/coop_config.dart';
import 'paddock/coop_marshal.dart';
import 'paddock/core/coop_log.dart';
import 'paddock/infra/coop_dispatch.dart';
import 'paddock/infra/coop_vault.dart';
import 'paddock/infra/pulse_hub.dart';
import 'paddock/infra/reach_scout.dart';
import 'paddock/infra/stride_client.dart';
import 'paddock/infra/trail_tracer.dart';

/// Entry point. Warms up the gray-flow services, initialises Firebase (for
/// push) independently of App Check, and mounts [HenGateApp]. The white game
/// (`CrazyHenRunApp`) runs its own bootstrap once the organic path is chosen.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final vault = CoopVault();
  final client = StrideClient();
  await Future.wait<void>(<Future<void>>[
    vault.initialize(),
    client.prepare(),
  ]);

  chrTrace(
    () => '[CHR.BOOT] credentialsReady=${CoopConfig.grayCredentialsReady} '
        'endpoint=${CoopConfig.endpoint} '
        'afKeyLen=${CoopConfig.appsFlyerKey.length} '
        'fbNum=${CoopConfig.firebaseProjectNumber}',
  );

  var productionServicesReady = false;
  if (CoopConfig.grayCredentialsReady) {
    try {
      await Firebase.initializeApp();
      productionServicesReady = true;
      chrTrace(() => '[CHR.BOOT] Firebase.initializeApp OK');
    } catch (error) {
      chrTrace(() => '[CHR.BOOT] Firebase.initializeApp failed: $error');
    }
    if (productionServicesReady) {
      try {
        await FirebaseAppCheck.instance.activate(
          providerApple: kDebugMode
              ? const AppleDebugProvider()
              : const AppleAppAttestWithDeviceCheckFallbackProvider(),
        );
      } catch (error) {
        // App Check must never block FCM / gray routing.
        chrTrace(() => '[CHR.BOOT] AppCheck skipped: $error');
      }
    }
  } else {
    chrTrace(
      () => '[CHR.BOOT] gray gate DISABLED — missing credentials. Game only.',
    );
  }

  final scout = ReachScout();
  // Attribution + config POST must run even if Firebase failed to init; only
  // push/FCM needs productionServicesReady.
  final pulse = PulseHub(vault, enabled: productionServicesReady);
  final tracer = TrailTracer(client);
  final marshal = CoopMarshal(
    vault: vault,
    scout: scout,
    tracer: tracer,
    dispatch: CoopDispatch(client, vault),
    pulse: pulse,
    client: client,
    runtimeEnabled: CoopConfig.grayCredentialsReady,
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF02311D),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(HenGateApp(marshal: marshal));
}
