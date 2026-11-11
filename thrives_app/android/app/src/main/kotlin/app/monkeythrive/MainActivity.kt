package app.monkeythrive

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.view.KeyEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        val volume = event.keyCode == KeyEvent.KEYCODE_VOLUME_UP ||
            event.keyCode == KeyEvent.KEYCODE_VOLUME_DOWN
        val handled = super.dispatchKeyEvent(event)
        // Flutter sees the key first. Consuming it keeps the ringer still
        // while the sigh opens. The web build has no Activity.
        if (volume) return true
        return handled
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "app.monkeythrive/crisis_dial",
        ).setMethodCallHandler { call, result ->
            if (call.method != "open") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val uriString = call.argument<String>("uri")
            if (uriString.isNullOrBlank()) {
                result.error("bad_uri", "Missing link", null)
                return@setMethodCallHandler
            }
            val parsed = Uri.parse(uriString)
            val scheme = parsed.scheme
            // ACTION_DIAL opens the dialer. ACTION_CALL would place the call
            // and would require CALL_PHONE. Neither path uses the network.
            val action = when (scheme) {
                "tel" -> Intent.ACTION_DIAL
                "sms" -> Intent.ACTION_SENDTO
                else -> {
                    result.error("bad_uri", "Only phone and text links are allowed", null)
                    return@setMethodCallHandler
                }
            }
            if (!parsed.host.isNullOrEmpty()) {
                result.error("bad_uri", "Network links are not allowed", null)
                return@setMethodCallHandler
            }
            try {
                startActivity(Intent(action, parsed))
                result.success(true)
            } catch (_: ActivityNotFoundException) {
                result.success(false)
            } catch (_: Exception) {
                result.success(false)
            }
        }
    }
}
