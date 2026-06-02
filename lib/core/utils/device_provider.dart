import 'dart:async';
import 'package:flutter/foundation.dart';
import '../utils/device_channel.dart';

// ── Modelo para ponto do histórico de sessão ──────────────────────────────────
class MetricPoint {
  final DateTime time;
  final double value;
  MetricPoint(this.time, this.value);
}

class DeviceProvider extends ChangeNotifier {
  // ── RAM ──────────────────────────────────────────────
  int ramTotal = 0;
  int ramUsed = 0;
  int ramAvailable = 0;
  int ramThreshold = 0;
  bool ramLowMemory = false;
  double get ramPercent => ramTotal > 0 ? ramUsed / ramTotal : 0;

  // ── CPU ──────────────────────────────────────────────
  double cpuUsage = 0;
  int cpuCores = 0;
  List<double> cpuHistory = List.filled(20, 0);
  List<double> cpuPerCore = [];

  // ── ARMAZENAMENTO ────────────────────────────────────
  int storageTotal = 0;
  int storageUsed = 0;
  int storageFree = 0;
  double get storagePercent =>
      storageTotal > 0 ? storageUsed / storageTotal : 0;

  // ── BATERIA ──────────────────────────────────────────
  int batteryPercent = 0;
  double batteryTempC = 0;
  int batteryVoltageMv = 0;
  String batteryStatus = '';
  String batteryHealth = '';
  String batteryPlugged = '';
  int batteryMinutesRemaining = -1;
  List<int> batteryHistory = List.filled(20, 0);

  // ── REDE ─────────────────────────────────────────────
  int networkRxSpeed = 0; // bytes/s
  int networkTxSpeed = 0; // bytes/s
  int networkTotalRx = 0;
  int networkTotalTx = 0;
  String networkConnectionType = '';
  String networkIpAddress = '';
  List<double> networkRxHistory = List.filled(20, 0);
  List<double> networkTxHistory = List.filled(20, 0);
  List<Map<String, dynamic>> networkUsageByApp = [];

  // ── DISPOSITIVO ──────────────────────────────────────
  Map<String, dynamic> deviceInfo = {};

  // ── HISTÓRICO DE SESSÃO (últimas 2h, 1 ponto a cada 10s) ────────────────────
  final List<MetricPoint> cpuSessionHistory = [];
  final List<MetricPoint> ramSessionHistory = [];
  static const int _maxHistoryPoints = 720; // 2h × 360 amostras por hora

  // ── ESTADO ───────────────────────────────────────────
  bool isLoading = true;
  String? error;
  DateTime? lastUpdate;

  Timer? _timer;
  Timer? _networkTimer;
  Timer? _slowTimer; // 10s para histórico de sessão + rede por app

  int _slowTickCount = 0;

  DeviceProvider() {
    _loadAll();
    // Ciclo principal: 3 segundos
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _loadAll());
    // Rede por app e histórico: 10 segundos
    _slowTimer =
        Timer.periodic(const Duration(seconds: 10), (_) => _loadSlow());
    // Info de dispositivo: carrega 1 vez
    _loadDeviceInfo();
  }

  Future<void> _loadAll() async {
    try {
      await Future.wait([
        _loadRam(),
        _loadCpu(),
        _loadStorage(),
        _loadBattery(),
        _loadNetwork(),
      ]);
      lastUpdate = DateTime.now();
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadSlow() async {
    _slowTickCount++;
    try {
      // Salva ponto no histórico de sessão
      final now = DateTime.now();
      cpuSessionHistory.add(MetricPoint(now, cpuUsage));
      ramSessionHistory.add(MetricPoint(now, ramPercent * 100));
      if (cpuSessionHistory.length > _maxHistoryPoints) {
        cpuSessionHistory.removeAt(0);
      }
      if (ramSessionHistory.length > _maxHistoryPoints) {
        ramSessionHistory.removeAt(0);
      }

      // Carrega uso de rede por app a cada 30s (3 ciclos de 10s)
      if (_slowTickCount % 3 == 0) {
        networkUsageByApp = await DeviceChannel.getNetworkUsageByApp();
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _loadRam() async {
    final data = await DeviceChannel.getRamDetail();
    ramTotal = (data['total'] as num?)?.toInt() ?? 0;
    ramAvailable = (data['available'] as num?)?.toInt() ?? 0;
    ramUsed = (data['used'] as num?)?.toInt() ?? 0;
    ramThreshold = (data['threshold'] as num?)?.toInt() ?? 0;
    ramLowMemory = data['lowMemory'] as bool? ?? false;
  }

  Future<void> _loadCpu() async {
    cpuUsage = await DeviceChannel.getCpuUsage();
    if (cpuCores == 0) cpuCores = await DeviceChannel.getCpuCores();
    cpuHistory = [...cpuHistory.skip(1), cpuUsage];
    // Per-core (leve, roda em paralelo)
    DeviceChannel.getCpuPerCore().then((cores) {
      cpuPerCore = cores;
    });
  }

  Future<void> _loadStorage() async {
    final data = await DeviceChannel.getStorageInfo();
    storageTotal = (data['total'] as num?)?.toInt() ?? 0;
    storageFree = (data['free'] as num?)?.toInt() ?? 0;
    storageUsed = (data['used'] as num?)?.toInt() ?? 0;
  }

  Future<void> _loadBattery() async {
    final data = await DeviceChannel.getBatteryDetail();
    batteryPercent = (data['percent'] as num?)?.toInt() ?? 0;
    batteryTempC = (data['tempC'] as num?)?.toDouble() ?? 0;
    batteryVoltageMv = (data['voltageMv'] as num?)?.toInt() ?? 0;
    batteryStatus = data['status'] as String? ?? '';
    batteryHealth = data['health'] as String? ?? '';
    batteryPlugged = data['plugged'] as String? ?? '';
    batteryMinutesRemaining = (data['minutesRemaining'] as num?)?.toInt() ?? -1;
    batteryHistory = [...batteryHistory.skip(1), batteryPercent];
  }

  Future<void> _loadNetwork() async {
    final data = await DeviceChannel.getNetworkInfo();
    networkRxSpeed = (data['rxSpeed'] as num?)?.toInt() ?? 0;
    networkTxSpeed = (data['txSpeed'] as num?)?.toInt() ?? 0;
    networkTotalRx = (data['totalRxBytes'] as num?)?.toInt() ?? 0;
    networkTotalTx = (data['totalTxBytes'] as num?)?.toInt() ?? 0;
    networkConnectionType = data['connectionType'] as String? ?? '';
    networkIpAddress = data['ipAddress'] as String? ?? '';
    const maxSpeed = 10 * 1024 * 1024; // 10 MB/s para normalizar gráfico
    networkRxHistory = [
      ...networkRxHistory.skip(1),
      (networkRxSpeed / maxSpeed * 100).clamp(0.0, 100.0)
    ];
    networkTxHistory = [
      ...networkTxHistory.skip(1),
      (networkTxSpeed / maxSpeed * 100).clamp(0.0, 100.0)
    ];
  }

  Future<void> _loadDeviceInfo() async {
    try {
      deviceInfo = await DeviceChannel.getDeviceInfo();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> refresh() => _loadAll();

  @override
  void dispose() {
    _timer?.cancel();
    _networkTimer?.cancel();
    _slowTimer?.cancel();
    super.dispose();
  }
}

// ── Utilitários ───────────────────────────────────────────────────────────────

String formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}

String formatSpeed(int bytesPerSec) {
  if (bytesPerSec < 1024) return '$bytesPerSec B/s';
  if (bytesPerSec < 1024 * 1024)
    return '${(bytesPerSec / 1024).toStringAsFixed(1)} KB/s';
  return '${(bytesPerSec / (1024 * 1024)).toStringAsFixed(2)} MB/s';
}

String formatMinutes(int minutes) {
  if (minutes < 0) return '--';
  if (minutes < 60) return '${minutes}min';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m > 0 ? '${h}h ${m}min' : '${h}h';
}
