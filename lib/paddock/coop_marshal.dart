import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'config/coop_config.dart';
import 'core/coop_log.dart';
import 'core/coop_models.dart';
import 'infra/cold_tap_reader.dart';
import 'infra/coop_dispatch.dart';
import 'infra/coop_vault.dart';
import 'infra/pulse_hub.dart';
import 'infra/reach_scout.dart';
import 'infra/stride_client.dart';
import 'infra/trail_tracer.dart';

/// The routing brain. [decide] runs the cold-start → connectivity →
/// attribution → config pipeline and returns where the boot gate should go.
class CoopMarshal {
  CoopMarshal({
    required this.vault,
    required this.scout,
    required this.tracer,
    required this.dispatch,
    required this.pulse,
    required this.client,
    required this.runtimeEnabled,
  });

  final CoopVault vault;
  final ReachScout scout;
  final TrailTracer tracer;
  final CoopDispatch dispatch;
  final PulseHub pulse;
  final StrideClient client;
  final bool runtimeEnabled;

  bool get enabled => runtimeEnabled && CoopConfig.grayCredentialsReady;

  Future<CoopDest>? _decideFuture;

  /// De-duplicates only *concurrent* startup calls (the boot gate can build
  /// twice), then clears its cache so a later call — e.g. Retry from the
  /// offline screen after Wi-Fi returns — re-runs the whole pipeline instead
  /// of replaying a cached OfflineStop forever.
  Future<CoopDest> decide({
    required void Function(double value) onProgress,
  }) =>
      _decideFuture ??= _decide(onProgress: onProgress)
          .whenComplete(() => _decideFuture = null);

  Future<CoopDest> _decide({
    required void Function(double value) onProgress,
  }) async {
    if (!enabled) {
      chrTrace(
        () => '[CHR.MARSHAL] gate disabled runtime=$runtimeEnabled '
            'creds=${CoopConfig.grayCredentialsReady}',
      );
      onProgress(1);
      return const NativeStop();
    }

    chrTrace(() => '[CHR.MARSHAL] decide start route=${vault.route}');

    pulse.onTokenChanged = _refreshForToken;
    // Cold-start push destination is consumed FIRST — before push bootstrap,
    // connectivity or attribution — so a slow pipeline never loses the URL.
    final coldRoute = await ColdTapReader.consume();
    if (coldRoute != null) {
      await vault.saveRoute(CoopPath.portal);
      await vault.consumePushUrl();
      unawaited(_backgroundDispatch());
      onProgress(1);
      return PortalStop(coldRoute, coldLaunch: true);
    }

    onProgress(0.12);
    return switch (vault.route) {
      CoopPath.undecided => _firstDecision(onProgress),
      CoopPath.portal => _returningPortal(onProgress),
      CoopPath.native => _returningNative(onProgress),
    };
  }

  Future<CoopDest> _firstDecision(void Function(double) progress) async {
    if (!await scout.hasInterface()) {
      chrTrace(() => '[CHR.MARSHAL] first: no interface → offline');
      return const OfflineStop(returnToNative: false);
    }
    progress(0.28);
    try {
      await pulse.boot();
    } catch (_) {}
    if (!await scout.canReachNetwork()) {
      chrTrace(() => '[CHR.MARSHAL] first: DNS probe failed → offline');
      return const OfflineStop(returnToNative: false);
    }
    progress(0.48);
    await tracer.awaitSignals();
    progress(0.72);
    final reply = await _requestConfig();
    progress(1);
    chrTrace(
      () => '[CHR.MARSHAL] first: hasDest=${reply.hasDestination} '
          'url=${reply.url}',
    );
    if (reply.hasDestination) {
      await vault.saveRoute(CoopPath.portal);
      return PortalStop(reply.url!);
    }
    // Only a *successful* response with no URL commits the game. A network
    // failure keeps the install `undecided` so a later online launch can
    // still reach the WebView.
    await vault.saveRoute(CoopPath.native);
    return const NativeStop();
  }

  Future<CoopDest> _returningPortal(void Function(double) progress) async {
    if (!await scout.hasInterface()) {
      return const OfflineStop(returnToNative: false);
    }
    final pending = await vault.consumePushUrl();
    if (pending != null && pending.isNotEmpty) {
      progress(1);
      return PortalStop(pending);
    }
    final cached = await vault.savedUrl();
    if (cached != null && !vault.cachedUrlExpired) {
      progress(1);
      return PortalStop(cached);
    }

    await Future.wait<void>(<Future<void>>[pulse.boot(), tracer.start()]);
    if (!await scout.canReachNetwork()) {
      return const OfflineStop(returnToNative: false);
    }
    progress(0.62);
    await tracer.awaitSignals(installTimeout: const Duration(seconds: 5));
    final reply = await _requestConfig();
    progress(1);
    if (reply.hasDestination) return PortalStop(reply.url!);
    if (cached != null) return PortalStop(cached);
    return const OfflineStop(returnToNative: false);
  }

  Future<CoopDest> _returningNative(void Function(double) progress) async {
    if (!await scout.hasInterface()) {
      progress(1);
      return const NativeStop();
    }
    await Future.wait<void>(<Future<void>>[pulse.boot(), tracer.start()]);
    if (!await scout.canReachNetwork()) {
      progress(1);
      return const NativeStop();
    }
    progress(0.55);
    await tracer.awaitSignals();
    final reply = await _requestConfig();
    progress(1);
    if (!reply.hasDestination) return const NativeStop();
    await vault.saveRoute(CoopPath.portal);
    return PortalStop(reply.url!);
  }

  Future<CoopReply> _requestConfig({String? token}) async {
    final body = await tracer.compose(
      locale: Platform.localeName.replaceAll('-', '_'),
      pushToken: token ?? pulse.token,
    );
    if (kDebugMode && CoopConfig.debugForcePortal) {
      body['af_status'] = 'Non-organic';
      chrTrace(() => '[CHR.MARSHAL] DEBUG force portal: af_status=Non-organic');
    }
    return dispatch.request(body);
  }

  Future<void> _backgroundDispatch() async {
    try {
      await Future.wait<void>(<Future<void>>[
        pulse.boot(),
        tracer.awaitSignals(),
      ]);
      await _requestConfig();
    } catch (_) {}
  }

  Future<void> _refreshForToken(String token) async {
    try {
      await _requestConfig(token: token);
    } catch (_) {}
  }
}
