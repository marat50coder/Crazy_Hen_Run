package com.crazyhenrun.crazyhenrungame

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

/**
 * Host activity for the Henyard Daily Flutter engine on Android.
 *
 * The default [FlutterActivity] behaviour is exactly what we need – Flutter
 * takes over the entire window – but we still override [onCreate] to attach a
 * tiny debug log entry so cold starts are easy to spot in `logcat` without
 * pulling in any external analytics.
 */
class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        if (BuildInfo.DEBUG_LOGS) {
            android.util.Log.d(BuildInfo.TAG, "MainActivity.onCreate")
        }
    }

    override fun onResume() {
        super.onResume()
        if (BuildInfo.DEBUG_LOGS) {
            android.util.Log.d(BuildInfo.TAG, "MainActivity.onResume")
        }
    }
}

/** Compile-time constants used by lightweight diagnostic logging. */
internal object BuildInfo {
    /** Tag used by every log statement in this module. */
    const val TAG: String = "Henyard"

    /**
     * When ``true`` a small set of lifecycle transitions is written to
     * `logcat`. Kept ``false`` in release builds to avoid noise.
     */
    const val DEBUG_LOGS: Boolean = false
}
