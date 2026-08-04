import 'package:flutter/foundation.dart';

/// Debug-only tracer. The closure AND its string literals are stripped from
/// release builds by the `assert`, so no gray-flow log text ships in the
/// binary (where it would be a grep-able fingerprint).
void chrTrace(String Function() message) {
  assert(() {
    debugPrint(message());
    return true;
  }());
}
