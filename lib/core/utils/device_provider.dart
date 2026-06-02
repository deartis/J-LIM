import 'dart:async';
import 'package:flutter/foundation.dart';
import '../utils/device_channel.dart';

class DeviceProvider extends ChangeNotifier {
  // ── RAM ──────────────────────────────────────────────
  int ramTotal = 0;
  int ramUsed = 0;
  int ramAvailable = 0;
  double get ramPercent => ramTotal > 0 ? ramUsed / ramTotal : 0;

  // ── CPU ──────────────────────────────────────────────
  double cpuUsage = 0;
  int cpuCores = 0;
  List<double> cpuHistory = List.filled(20, 0);

  // ── ARMAZENAMENTO ────────────────────────────────────
  int storageTotal = 0;
  int storageUsed = 0;
  int storageFree = 0;
  double get storagePercent => storageTotal > 0 ? storageUsed / storageTotal : 0;

  // ── BATERIA ──────────────────────────────────────────
  int batteryPercent = 0;
  double batteryTempC = 0;
  int batteryVoltageMv = 0;
  String batteryStatus = '';
  String batteryHealth = '';
  String batteryPlugged = '';
  List<int> batteryHistory = List.filled(20, 0);

  // ── ESTADO ───────────────────────────────────────────
  bool isLoading = true;
  String? error;
  DateTime? lastUpdate;

  Timer? _timer;

  DeviceProvider() {
    _loadAll();
    // Atualiza a cada 3 segundos
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _loadAll());
  }

  Future<void> _loadAll() async {
    try {
      await Future.wait([
        _loadRam(),
        _loadCpu(),
        _loadStorage(),
        _loadBattery(),
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

  Future<void> _loadRam() async {
    final data = await DeviceChannel.getRamInfo();
    ramTotal = data['total'] ?? 0;
    ramAvailable = data['available'] ?? 0;
    ramUsed = data['used'] ?? 0;
  }

  Future<void> _loadCpu() async {
    cpuUsage = await DeviceChannel.getCpuUsage();
    if (cpuCores == 0) cpuCores = await DeviceChannel.getCpuCores();
    cpuHistory = [...cpuHistory.skip(1), cpuUsage];
  }

  Future<void> _loadStorage() async {
    final data = await DeviceChannel.getStorageInfo();
    storageTotal = data['total'] ?? 0;
    storageFree = data['free'] ?? 0;
    storageUsed = data['used'] ?? 0;
  }

  Future<void> _loadBattery() async {
    final data = await DeviceChannel.getBatteryDetail();
    batteryPercent = data['percent'] ?? 0;
    batteryTempC = (data['tempC'] ?? 0).toDouble();
    batteryVoltageMv = data['voltageMv'] ?? 0;
    batteryStatus = data['status'] ?? '';
    batteryHealth = data['health'] ?? '';
    batteryPlugged = data['plugged'] ?? '';
    batteryHistory = [...batteryHistory.skip(1), batteryPercent];
  }

  Future<void> refresh() => _loadAll();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// Formatter de bytes legível
String formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  if (bytes < 1024 * 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
}
