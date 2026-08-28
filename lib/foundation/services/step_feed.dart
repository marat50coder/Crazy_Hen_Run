import 'dart:async';

import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

/// Thin wrapper around the device step-counter sensor.
///
/// The hardware counter is cumulative since the last reboot, so callers get the
/// raw value plus the walking/idle status and decide how to turn it into a
/// per-day figure. No location is ever touched.
class StepFeed {
  StreamSubscription<StepCount>? _stepSub;
  StreamSubscription<PedestrianStatus>? _statusSub;

  bool _available = false;
  bool get available => _available;

  /// Ask for Motion & Fitness / Activity Recognition. Returns true if granted.
  Future<bool> ensurePermission() async {
    final status = await Permission.activityRecognition.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) return false;
    final result = await Permission.activityRecognition.request();
    return result.isGranted;
  }

  Future<bool> hasPermission() async =>
      Permission.activityRecognition.status.then((s) => s.isGranted);

  /// Start listening. [onSteps] fires with the cumulative sensor value;
  /// [onStatus] fires with 'walking' / 'stopped'; [onError] when no sensor.
  Future<void> start({
    required void Function(int cumulativeSteps) onSteps,
    void Function(String status)? onStatus,
    void Function(Object error)? onError,
  }) async {
    await stop();
    try {
      _stepSub = Pedometer.stepCountStream.listen(
        (event) {
          _available = true;
          onSteps(event.steps);
        },
        onError: (Object e) {
          _available = false;
          onError?.call(e);
        },
        cancelOnError: false,
      );
      if (onStatus != null) {
        _statusSub = Pedometer.pedestrianStatusStream.listen(
          (event) => onStatus(event.status),
          onError: (Object _) {},
          cancelOnError: false,
        );
      }
    } on Object catch (e) {
      _available = false;
      onError?.call(e);
    }
  }

  Future<void> stop() async {
    await _stepSub?.cancel();
    await _statusSub?.cancel();
    _stepSub = null;
    _statusSub = null;
  }
}
