package com.example.my_app

import android.app.ActivityManager
import android.content.Context
import android.os.Build
import android.os.Environment
import android.os.StatFs
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.fidobox/diagnostics"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // Lines handling RAM and ROM diagnostics
                    "getRamInfo" -> result.success(getRamInfo())
                    "getRomInfo" -> result.success(getRomInfo())
                    else -> result.notImplemented()
                }
            }
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
}

