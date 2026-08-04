import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Connectivity + reachability checks. [hasInterface] is a cheap radio check;
/// [canReachNetwork] time-boxes a DNS lookup against well-known hosts (never
/// our own domain) so a VPN or an un-propagated app domain can't produce a
/// false offline, and the retry button can never hang.
class ReachScout {
  final Connectivity _connectivity = Connectivity();

  Future<bool> hasInterface() async {
    try {
      final status = await _connectivity.checkConnectivity();
      return status.any((value) => value != ConnectivityResult.none);
    } catch (_) {
      return false;
    }
  }

  Future<bool> canReachNetwork() async {
    if (!await hasInterface()) return false;
    for (final host in const <String>['apple.com', 'icloud.com']) {
      try {
        final records =
            await InternetAddress.lookup(host).timeout(
          const Duration(seconds: 3),
        );
        if (records.any((record) => record.rawAddress.isNotEmpty)) {
          return true;
        }
      } catch (_) {
        // Try the next host before declaring offline.
      }
    }
    return false;
  }

  Stream<List<ConnectivityResult>> get changes =>
      _connectivity.onConnectivityChanged;
}
