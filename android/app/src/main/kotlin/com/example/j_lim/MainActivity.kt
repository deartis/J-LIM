package com.example.j_lim

import android.app.ActivityManager
import android.app.usage.StorageStatsManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.TrafficStats
import android.net.Uri
import android.net.wifi.WifiManager
import android.os.BatteryManager
import android.os.Build
import android.os.Environment
import android.os.StatFs
import android.os.storage.StorageManager
import android.provider.Settings
import android.util.DisplayMetrics
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.FileReader
import java.net.Inet4Address
import java.net.NetworkInterface
import kotlin.math.roundToInt
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {

    private val CHANNEL = "com.jlim/device"

    // Para calcular TX/RX delta
    private var lastRxBytes = TrafficStats.getTotalRxBytes()
    private var lastTxBytes = TrafficStats.getTotalTxBytes()
    private var lastNetworkTime = System.currentTimeMillis()

    // Para calcular taxa de descarga da bateria
    private var lastBatteryPercent = -1
    private var lastBatteryTime = System.currentTimeMillis()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getRamInfo"           -> result.success(getRamInfo())
                    "getRamDetail"         -> result.success(getRamDetail())
                    "getCpuUsage"          -> thread {
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
                    "getCpuCores"          -> result.success(Runtime.getRuntime().availableProcessors())
                    "getCpuPerCore"        -> thread {
                        try {
                            val cores = getCpuPerCore()
                            android.os.Handler(android.os.Looper.getMainLooper()).post {
                                result.success(cores)
                            }
                        } catch (e: Exception) {
                            android.os.Handler(android.os.Looper.getMainLooper()).post {
                                result.success(emptyList<Double>())
                            }
                        }
                    }
                    "getStorageInfo"       -> result.success(getStorageInfo())
                    "getAppStorageList"    -> thread {
                        try {
                            val list = getAppStorageDetail()
                            android.os.Handler(android.os.Looper.getMainLooper()).post {
                                result.success(list)
                            }
                        } catch (e: Exception) {
                            android.os.Handler(android.os.Looper.getMainLooper()).post {
                                result.success(emptyList<Map<String, Any>>())
                            }
                        }
                    }
                    "getBatteryDetail"     -> result.success(getBatteryDetail())
                    "getNetworkInfo"       -> result.success(getNetworkInfo())
                    "getNetworkUsageByApp" -> thread {
                        try {
                            val list = getNetworkUsageByApp()
                            android.os.Handler(android.os.Looper.getMainLooper()).post {
                                result.success(list)
                            }
                        } catch (e: Exception) {
                            android.os.Handler(android.os.Looper.getMainLooper()).post {
                                result.success(emptyList<Map<String, Any>>())
                            }
                        }
                    }
                    "getDeviceInfo"        -> result.success(getDeviceInfo())
                    "getInstalledApps"     -> result.success(getInstalledApps())
                    "openAppSettings"      -> {
                        val pkg = call.argument<String>("package") ?: ""
                        openAppSettings(pkg)
                        result.success(null)
                    }
                    "uninstallApp"         -> {
                        val pkg = call.argument<String>("package") ?: ""
                        uninstallApp(pkg)
                        result.success(null)
                    }
                    "openStorageSettings"  -> {
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

    private fun getRamDetail(): Map<String, Any> {
        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val mi = ActivityManager.MemoryInfo()
        am.getMemoryInfo(mi)
        val used = mi.totalMem - mi.availMem
        return mapOf(
            "total"      to mi.totalMem,
            "available"  to mi.availMem,
            "used"       to used,
            "threshold"  to mi.threshold,
            "lowMemory"  to mi.lowMemory
        )
    }

    // ── CPU ──────────────────────────────────────────────────────────────────

    private fun readCpuStat(cpuId: String = "cpu"): Pair<Long, Long> {
        return try {
            val line = BufferedReader(FileReader("/proc/stat")).use { reader ->
                reader.lineSequence().firstOrNull { it.startsWith("$cpuId ") }
            } ?: return Pair(0L, 0L)
            val toks = line.trim().split("\\s+".toRegex()).drop(1).map { it.toLong() }
            val idle = toks[3] + if (toks.size > 4) toks[4] else 0L
            val total = toks.sum()
            Pair(idle, total)
        } catch (e: Exception) {
            Pair(0L, 0L)
        }
    }

    private fun getCpuUsage(): Double {
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

        // Fallback: média de frequência por core
        return try {
            val cores = Runtime.getRuntime().availableProcessors()
            var totalPct = 0.0
            var validCores = 0
            for (i in 0 until cores) {
                try {
                    val cur = java.io.File("/sys/devices/system/cpu/cpu$i/cpufreq/scaling_cur_freq").readText().trim().toDouble()
                    val max = java.io.File("/sys/devices/system/cpu/cpu$i/cpufreq/cpuinfo_max_freq").readText().trim().toDouble()
                    if (max > 0) { totalPct += (cur / max); validCores++ }
                } catch (_: Exception) {}
            }
            if (validCores > 0) (totalPct / validCores * 100.0).coerceIn(0.0, 100.0) else 0.0
        } catch (_: Exception) { 0.0 }
    }

    private fun getCpuPerCore(): List<Double> {
        val cores = Runtime.getRuntime().availableProcessors()
        val result = mutableListOf<Double>()

        // Tentar via /proc/stat por núcleo
        val before = (0 until cores).map { readCpuStat("cpu$it") }
        Thread.sleep(200)
        val after  = (0 until cores).map { readCpuStat("cpu$it") }

        for (i in 0 until cores) {
            val (idle1, total1) = before[i]
            val (idle2, total2) = after[i]
            val dt = (total2 - total1).toDouble()
            val di = (idle2  - idle1).toDouble()
            if (dt > 0.0) {
                result.add(((dt - di) / dt * 100.0).coerceIn(0.0, 100.0))
            } else {
                // Fallback: frequência
                try {
                    val cur = java.io.File("/sys/devices/system/cpu/cpu$i/cpufreq/scaling_cur_freq").readText().trim().toDouble()
                    val max = java.io.File("/sys/devices/system/cpu/cpu$i/cpufreq/cpuinfo_max_freq").readText().trim().toDouble()
                    result.add(if (max > 0) (cur / max * 100.0).coerceIn(0.0, 100.0) else 0.0)
                } catch (_: Exception) { result.add(0.0) }
            }
        }
        return result
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

    private fun getAppStorageDetail(): List<Map<String, Any>> {
        val pm = packageManager
        val apps = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.getInstalledApplications(PackageManager.ApplicationInfoFlags.of(0L))
        } else {
            @Suppress("DEPRECATION")
            pm.getInstalledApplications(0)
        }

        val storageStatsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            getSystemService(Context.STORAGE_STATS_SERVICE) as? StorageStatsManager
        } else null

        val storageManager = getSystemService(Context.STORAGE_SERVICE) as? StorageManager

        return apps
            .filter { (it.flags and ApplicationInfo.FLAG_SYSTEM) == 0 }
            .mapNotNull { info ->
                try {
                    val sourceDir = info.sourceDir ?: return@mapNotNull null
                    val apkSize = java.io.File(sourceDir).length()

                    var dataSize = 0L
                    var cacheSize = 0L

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && storageStatsManager != null && storageManager != null) {
                        try {
                            val uuid = storageManager.getUuidForPath(java.io.File(info.dataDir))
                            val uid = pm.getApplicationInfo(info.packageName, 0).uid
                            // StorageStatsManager.queryStatsForUid requires PACKAGE_USAGE_STATS permission
                            // Fallback to dataDir size if not available
                            val dataDir = java.io.File(info.dataDir)
                            if (dataDir.exists()) {
                                dataSize = dataDir.walkTopDown()
                                    .filter { it.isFile }
                                    .fold(0L) { acc, file -> acc + file.length() }
                            }
                        } catch (_: Exception) {
                            val dataDir = java.io.File(info.dataDir)
                            if (dataDir.exists()) {
                                try {
                                    dataSize = dataDir.walkTopDown()
                                        .filter { it.isFile }
                                        .fold(0L) { acc, file ->
                                            try { acc + file.length() } catch (_: Exception) { acc }
                                        }
                                } catch (_: Exception) {}
                            }
                        }

                        // Cache
                        try {
                            val cacheDir = java.io.File(info.dataDir, "cache")
                            if (cacheDir.exists()) {
                                cacheSize = cacheDir.walkTopDown()
                                    .filter { it.isFile }
                                    .fold(0L) { acc, file ->
                                        try { acc + file.length() } catch (_: Exception) { acc }
                                    }
                            }
                        } catch (_: Exception) {}
                    }

                    mapOf(
                        "packageName" to info.packageName,
                        "appName"     to (pm.getApplicationLabel(info).toString()),
                        "apkSize"     to apkSize,
                        "dataSize"    to dataSize,
                        "cacheSize"   to cacheSize,
                        "totalSize"   to (apkSize + dataSize)
                    )
                } catch (_: Exception) { null }
            }
            .sortedByDescending { it["totalSize"] as Long }
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

        // Estimativa de tempo restante (em minutos)
        var minutesRemaining = -1
        val bm = getSystemService(Context.BATTERY_SERVICE) as? BatteryManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            val chargeTimeMs = bm?.computeChargeTimeRemaining() ?: -1L
            if (chargeTimeMs > 0L && plugged != 0) {
                minutesRemaining = (chargeTimeMs / 1000 / 60).toInt()
            }
        }
        // Estimativa de descarga por taxa
        if (minutesRemaining < 0 && plugged == 0 && lastBatteryPercent >= 0 && percent < lastBatteryPercent) {
            val elapsed = (System.currentTimeMillis() - lastBatteryTime).toDouble() / 1000.0 / 60.0
            val dropped = (lastBatteryPercent - percent).toDouble()
            if (dropped > 0.0 && elapsed > 0.0) {
                val ratePerMin = dropped / elapsed
                minutesRemaining = (percent / ratePerMin).toInt()
            }
        }
        lastBatteryPercent = percent
        lastBatteryTime = System.currentTimeMillis()

        val statusStr = when (status) {
            BatteryManager.BATTERY_STATUS_CHARGING     -> "Carregando"
            BatteryManager.BATTERY_STATUS_DISCHARGING  -> "Descarregando"
            BatteryManager.BATTERY_STATUS_FULL         -> "Completo"
            BatteryManager.BATTERY_STATUS_NOT_CHARGING -> "Não carregando"
            else                                        -> "Desconhecido"
        }

        val healthStr = when (health) {
            BatteryManager.BATTERY_HEALTH_GOOD         -> "Boa"
            BatteryManager.BATTERY_HEALTH_OVERHEAT     -> "Superaquecimento"
            BatteryManager.BATTERY_HEALTH_DEAD         -> "Morta"
            BatteryManager.BATTERY_HEALTH_COLD         -> "Fria"
            BatteryManager.BATTERY_HEALTH_OVER_VOLTAGE -> "Sobretensão"
            else                                        -> "Desconhecida"
        }

        val pluggedStr = when (plugged) {
            BatteryManager.BATTERY_PLUGGED_AC       -> "Tomada AC"
            BatteryManager.BATTERY_PLUGGED_USB      -> "USB"
            BatteryManager.BATTERY_PLUGGED_WIRELESS -> "Sem fio"
            else                                     -> "Desconectado"
        }

        return mapOf(
            "percent"          to percent,
            "tempC"            to (temp / 10.0),
            "voltageMv"        to voltage,
            "status"           to statusStr,
            "health"           to healthStr,
            "plugged"          to pluggedStr,
            "minutesRemaining" to minutesRemaining
        )
    }

    // ── REDE ─────────────────────────────────────────────────────────────────

    private fun getNetworkInfo(): Map<String, Any> {
        val cm = getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val now = System.currentTimeMillis()
        val rxNow = TrafficStats.getTotalRxBytes()
        val txNow = TrafficStats.getTotalTxBytes()

        val elapsedMs = (now - lastNetworkTime).coerceAtLeast(1L)
        val rxSpeed = ((rxNow - lastRxBytes) * 1000L / elapsedMs) // bytes/s
        val txSpeed = ((txNow - lastTxBytes) * 1000L / elapsedMs)

        lastRxBytes = rxNow
        lastTxBytes = txNow
        lastNetworkTime = now

        var connectionType = "Sem conexão"
        var ipAddress = ""

        val network = cm.activeNetwork
        if (network != null) {
            val caps = cm.getNetworkCapabilities(network)
            connectionType = when {
                caps == null -> "Desconhecido"
                caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "Wi-Fi"
                caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> {
                    // Tentar detectar geração
                    "Dados Móveis"
                }
                caps.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "Ethernet"
                else -> "Outro"
            }
        }

        // IP local
        try {
            val interfaces = NetworkInterface.getNetworkInterfaces()
            if (interfaces != null) {
                for (iface in interfaces.toList()) {
                    if (iface.isLoopback || !iface.isUp) continue
                    for (addr in iface.inetAddresses.toList()) {
                        if (!addr.isLoopbackAddress && addr is Inet4Address) {
                            ipAddress = addr.hostAddress ?: ""
                            break
                        }
                    }
                    if (ipAddress.isNotEmpty()) break
                }
            }
        } catch (_: Exception) {}

        return mapOf(
            "rxSpeed"        to rxSpeed.coerceAtLeast(0L),
            "txSpeed"        to txSpeed.coerceAtLeast(0L),
            "totalRxBytes"   to rxNow.coerceAtLeast(0L),
            "totalTxBytes"   to txNow.coerceAtLeast(0L),
            "connectionType" to connectionType,
            "ipAddress"      to ipAddress
        )
    }

    private fun getNetworkUsageByApp(): List<Map<String, Any>> {
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
                    val uid = info.uid
                    val rx = TrafficStats.getUidRxBytes(uid)
                    val tx = TrafficStats.getUidTxBytes(uid)
                    if (rx <= 0 && tx <= 0) return@mapNotNull null
                    mapOf(
                        "packageName" to info.packageName,
                        "appName"     to pm.getApplicationLabel(info).toString(),
                        "rxBytes"     to rx,
                        "txBytes"     to tx,
                        "totalBytes"  to (rx + tx)
                    )
                } catch (_: Exception) { null }
            }
            .sortedByDescending { it["totalBytes"] as Long }
            .take(20)
    }

    // ── INFORMAÇÕES DO DISPOSITIVO ────────────────────────────────────────────

    private fun getDeviceInfo(): Map<String, Any> {
        val dm = DisplayMetrics()
        @Suppress("DEPRECATION")
        windowManager.defaultDisplay.getMetrics(dm)

        val kernel = try {
            System.getProperty("os.version") ?: "Desconhecido"
        } catch (_: Exception) { "Desconhecido" }

        val glRenderer = "Consulte a GPU em Configurações"

        return mapOf(
            "model"          to Build.MODEL,
            "manufacturer"   to Build.MANUFACTURER,
            "brand"          to Build.BRAND,
            "androidVersion" to Build.VERSION.RELEASE,
            "sdkInt"         to Build.VERSION.SDK_INT,
            "buildNumber"    to Build.DISPLAY,
            "hardware"       to Build.HARDWARE,
            "board"          to Build.BOARD,
            "kernelVersion"  to kernel,
            "baseband"       to (Build.getRadioVersion() ?: "N/A"),
            "cpuAbi"         to (Build.SUPPORTED_ABIS.firstOrNull() ?: "N/A"),
            "cpuAbiList"     to Build.SUPPORTED_ABIS.joinToString(", "),
            "cpuCores"       to Runtime.getRuntime().availableProcessors(),
            "screenWidth"    to dm.widthPixels,
            "screenHeight"   to dm.heightPixels,
            "screenDpi"      to dm.densityDpi,
            "screenDensity"  to dm.density,
            "refreshRate"    to try { (windowManager.defaultDisplay.refreshRate).toInt() } catch (_: Exception) { 60 },
            "fingerprint"    to Build.FINGERPRINT,
            "securityPatch"  to if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) Build.VERSION.SECURITY_PATCH else "N/A"
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
