package com.example.my_app

import android.app.ActivityManager
import android.content.Context
import android.os.Build
import android.os.Environment
import android.os.StatFs
import android.net.wifi.WifiManager
import android.provider.Settings
import android.view.KeyEvent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.fidobox/diagnostics"
    private val KEY_EVENT_CHANNEL = "com.fidobox/diagnostics_keyevents"
    private var keyEventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // Lines handling RAM and ROM diagnostics
                    "getRamInfo" -> result.success(getRamInfo())
                    "getRomInfo" -> result.success(getRomInfo())
                    "isWifiEnabled" -> result.success(isWifiEnabled())
                    "getAndroidId" -> result.success(getAndroidId())
                    else -> result.notImplemented()
                }
            }

        // EventChannel phát trực tiếp sự kiện phím vật lý lên Flutter (Layer 1)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, KEY_EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    keyEventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    keyEventSink = null
                }
            })
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        // Bắt sự kiện phím vật lý khi nhấn xuống (ACTION_DOWN)
        if (event.action == KeyEvent.ACTION_DOWN) {
            when (event.keyCode) {
                KeyEvent.KEYCODE_VOLUME_UP -> {
                    keyEventSink?.success(24)
                }
                KeyEvent.KEYCODE_VOLUME_DOWN -> {
                    keyEventSink?.success(25)
                }
                KeyEvent.KEYCODE_BACK -> {
                    keyEventSink?.success(4)
                }
            }
        }
        return super.dispatchKeyEvent(event)
    }

    // ===== Helpers RAM / ROM =====
    private fun getRamInfo(): Map<String, Any?> {
        return try {
            val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            val mi = ActivityManager.MemoryInfo()
            am.getMemoryInfo(mi)
            val total = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN) mi.totalMem else null
            val free = mi.availMem
            mapOf("freeBytes" to free, "totalBytes" to total)
        } catch (e: Exception) {
            mapOf("freeBytes" to null, "totalBytes" to null)
        }
    }

    private fun getRomInfo(): Map<String, Any?> {
        return try {
            val dataDir = Environment.getDataDirectory()
            val stat = StatFs(dataDir.path)

            val blockSize = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) stat.blockSizeLong else @Suppress("DEPRECATION") stat.blockSize.toLong()
            val totalBlocks = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) stat.blockCountLong else @Suppress("DEPRECATION") stat.blockCount.toLong()
            val availBlocks = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR2) stat.availableBlocksLong else @Suppress("DEPRECATION") stat.availableBlocks.toLong()

            val totalBytes = blockSize * totalBlocks
            val freeBytes = blockSize * availBlocks
            mapOf("freeBytes" to freeBytes, "totalBytes" to totalBytes)
        } catch (e: Exception) {
            mapOf("freeBytes" to null, "totalBytes" to null)
        }
    }

    private fun isWifiEnabled(): Boolean {
        return try {
            val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            wifiManager.isWifiEnabled
        } catch (e: Exception) {
            false
        }
    }

    private fun getAndroidId(): String {
        return try {
            Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID) ?: "unknown"
        } catch (e: Exception) {
            "unknown"
        }
    }
}

