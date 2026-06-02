package com.example.j_lim

import android.app.ActivityManager
import android.app.usage.StorageStatsManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.BatteryManager
import android.os.Build
import android.os.Environment
import android.os.StatFs
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.FileReader
import java.io.IOException
import kotlin.math.roundToInt
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.jlim/device"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getRamInfo"        -> result.success(getRamInfo())
                    "getCpuUsage"       -> thread {
                        try {
                            val usage = getCpuUsage()
                            android.os.Handler(android.os.Looper.getMainLooper()).post {
                                result.success(usage)
                            }
                        } catch (e: Exception) {
                            android.os.Handler(android.os.Looper.getMainLooper()).post {
                                result.success(0.0)
                            }
                        }
                    }
                    "getCpuCores"       -> result.success(Runtime.getRuntime().availableProcessors())
                    "getStorageInfo"    -> result.success(getStorageInfo())
                    "getAppStorageList" -> result.success(getAppStorageList())
                    "getBatteryDetail"  -> result.success(getBatteryDetail())
                    "getInstalledApps"  -> result.success(getInstalledApps())
                    "openAppSettings"   -> {
                        val pkg = call.argument<String>("package") ?: ""
                        openAppSettings(pkg)
                        result.success(null)
                    }
                    "uninstallApp"      -> {
                        val pkg = call.argument<String>("package") ?: ""
                        uninstallApp(pkg)
                        result.success(null)
                    }
                    "openStorageSettings" -> {
                        startActivity(Intent(Settings.ACTION_INTERNAL_STORAGE_SETTINGS))
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // ── RAM ──────────────────────────────────────────────────────────────────

    private fun getRamInfo(): Map<String, Long> {
        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val mi = ActivityManager.MemoryInfo()
        am.getMemoryInfo(mi)
        val used = mi.totalMem - mi.availMem
        return mapOf(
            "total"     to mi.totalMem,
            "available" to mi.availMem,
            "used"      to used
        )
    }

    // ── CPU ──────────────────────────────────────────────────────────────────
    // Lê /proc/stat duas vezes com intervalo para calcular uso real

    private fun getCpuUsage(): Double {
        // 1. Tentativa via /proc/stat (funciona no Android < 8)
        fun readCpuStat(): Pair<Long, Long> {
            return try {
                val line = BufferedReader(FileReader("/proc/stat")).use { it.readLine() }
                val toks = line.trim().split("\\s+".toRegex()).drop(1).map { it.toLong() }
                val idle = toks[3] + toks[4]
                val total = toks.sum()
                Pair(idle, total)
            } catch (e: Exception) {
                Pair(0L, 0L)
            }
        }

        val (idle1, total1) = readCpuStat()
        if (total1 > 0L) {
            Thread.sleep(200)
            val (idle2, total2) = readCpuStat()
            val deltaTotal = (total2 - total1).toDouble()
            val deltaIdle  = (idle2  - idle1).toDouble()
            if (deltaTotal > 0.0) {
                return ((deltaTotal - deltaIdle) / deltaTotal * 100).coerceIn(0.0, 100.0)
            }
        }

        // 2. Fallback para Android 8+: Media de uso de frequencia dos cores (seguro, nao bloqueado)
        return try {
            val cores = Runtime.getRuntime().availableProcessors()
            var totalPct = 0.0
            var validCores = 0
            for (i in 0 until cores) {
                try {
                    val curFreqStr = java.io.File("/sys/devices/system/cpu/cpu$i/cpufreq/scaling_cur_freq").readText().trim()
                    val maxFreqStr = java.io.File("/sys/devices/system/cpu/cpu$i/cpufreq/cpuinfo_max_freq").readText().trim()
                    val curFreq = curFreqStr.toDouble()
                    val maxFreq = maxFreqStr.toDouble()
                    if (maxFreq > 0) {
                        totalPct += (curFreq / maxFreq)
                        validCores++
                    }
                } catch (e: Exception) {
                    // Ignora core offline ou sem permissao
                }
            }
            if (validCores > 0) {
                (totalPct / validCores * 100.0).coerceIn(0.0, 100.0)
            } else {
                0.0
            }
        } catch (e: Exception) {
            0.0
        }
    }

    // ── ARMAZENAMENTO ────────────────────────────────────────────────────────

    private fun getStorageInfo(): Map<String, Long> {
        val stat = StatFs(Environment.getDataDirectory().path)
        val total = stat.totalBytes
        val free  = stat.availableBytes
        return mapOf(
            "total" to total,
            "free"  to free,
            "used"  to (total - free)
        )
    }

    private fun getAppStorageList(): List<Map<String, Any>> {
        val pm = packageManager
        val apps = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.getInstalledApplications(PackageManager.ApplicationInfoFlags.of(0L))
        } else {
            @Suppress("DEPRECATION")
            pm.getInstalledApplications(0)
        }

        return apps
            .filter { (it.flags and ApplicationInfo.FLAG_SYSTEM) == 0 }
            .mapNotNull { info ->
                try {
                    val sourceDir = info.sourceDir ?: return@mapNotNull null
                    val apkSize = java.io.File(sourceDir).length()
                    mapOf(
                        "packageName" to info.packageName,
                        "appName"     to (pm.getApplicationLabel(info).toString()),
                        "apkSize"     to apkSize
                    )
                } catch (e: Exception) { null }
            }
            .sortedByDescending { it["apkSize"] as Long }
    }

    // ── BATERIA ──────────────────────────────────────────────────────────────

    private fun getBatteryDetail(): Map<String, Any> {
        val filter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        val intent = registerReceiver(null, filter) ?: return emptyMap()

        val level   = intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
        val scale   = intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
        val temp    = intent.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, -1)
        val voltage = intent.getIntExtra(BatteryManager.EXTRA_VOLTAGE, -1)
        val status  = intent.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
        val health  = intent.getIntExtra(BatteryManager.EXTRA_HEALTH, -1)
        val plugged = intent.getIntExtra(BatteryManager.EXTRA_PLUGGED, -1)

        val percent = if (scale > 0) (level.toFloat() / scale * 100).roundToInt() else 0

        val statusStr = when (status) {
            BatteryManager.BATTERY_STATUS_CHARGING    -> "Carregando"
            BatteryManager.BATTERY_STATUS_DISCHARGING -> "Descarregando"
            BatteryManager.BATTERY_STATUS_FULL        -> "Completo"
            BatteryManager.BATTERY_STATUS_NOT_CHARGING -> "Não carregando"
            else -> "Desconhecido"
        }

        val healthStr = when (health) {
            BatteryManager.BATTERY_HEALTH_GOOD         -> "Boa"
            BatteryManager.BATTERY_HEALTH_OVERHEAT     -> "Superaquecimento"
            BatteryManager.BATTERY_HEALTH_DEAD         -> "Morta"
            BatteryManager.BATTERY_HEALTH_COLD         -> "Fria"
            BatteryManager.BATTERY_HEALTH_OVER_VOLTAGE -> "Sobretensão"
            else -> "Desconhecida"
        }

        val pluggedStr = when (plugged) {
            BatteryManager.BATTERY_PLUGGED_AC  -> "Tomada AC"
            BatteryManager.BATTERY_PLUGGED_USB -> "USB"
            BatteryManager.BATTERY_PLUGGED_WIRELESS -> "Sem fio"
            else -> "Desconectado"
        }

        return mapOf(
            "percent"    to percent,
            "tempC"      to (temp / 10.0),
            "voltageMv"  to voltage,
            "status"     to statusStr,
            "health"     to healthStr,
            "plugged"    to pluggedStr,
        )
    }

    // ── APPS INSTALADOS ──────────────────────────────────────────────────────

    private fun getInstalledApps(): List<Map<String, Any>> {
        val pm = packageManager
        val apps = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.getInstalledApplications(PackageManager.ApplicationInfoFlags.of(0L))
        } else {
            @Suppress("DEPRECATION")
            pm.getInstalledApplications(0)
        }

        return apps
            .filter { (it.flags and ApplicationInfo.FLAG_SYSTEM) == 0 }
            .map { info ->
                mapOf(
                    "packageName" to info.packageName,
                    "appName"     to pm.getApplicationLabel(info).toString(),
                    "isSystem"    to false
                )
            }
            .sortedBy { it["appName"] as String }
    }

    // ── AÇÕES ────────────────────────────────────────────────────────────────

    private fun openAppSettings(packageName: String) {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.parse("package:$packageName")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }

    private fun uninstallApp(packageName: String) {
        val intent = Intent(Intent.ACTION_DELETE).apply {
            data = Uri.parse("package:$packageName")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }
}
