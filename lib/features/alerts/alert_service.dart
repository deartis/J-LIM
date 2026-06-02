import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/device_provider.dart';

class AlertService {
  static final AlertService _instance = AlertService._internal();
  factory AlertService() => _instance;
  AlertService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  Timer? _timer;

  // Configurações padrão
  bool ramAlertEnabled = true;
  bool tempAlertEnabled = true;
  bool storageAlertEnabled = true;
  double ramThresholdPct = 85.0;
  double tempThresholdC = 45.0;
  double storageThresholdPct = 10.0;

  // Cooldown para não repetir notificação muito rápido
  DateTime? _lastRamAlert;
  DateTime? _lastTempAlert;
  DateTime? _lastStorageAlert;
  static const _cooldown = Duration(minutes: 10);

  Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _notifications.initialize(initSettings);

    // Solicitar permissão no Android 13+
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    ramAlertEnabled = prefs.getBool('alert_ram_enabled') ?? true;
    tempAlertEnabled = prefs.getBool('alert_temp_enabled') ?? true;
    storageAlertEnabled = prefs.getBool('alert_storage_enabled') ?? true;
    ramThresholdPct = prefs.getDouble('alert_ram_threshold') ?? 85.0;
    tempThresholdC = prefs.getDouble('alert_temp_threshold') ?? 45.0;
    storageThresholdPct = prefs.getDouble('alert_storage_threshold') ?? 10.0;
  }

  Future<void> savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('alert_ram_enabled', ramAlertEnabled);
    await prefs.setBool('alert_temp_enabled', tempAlertEnabled);
    await prefs.setBool('alert_storage_enabled', storageAlertEnabled);
    await prefs.setDouble('alert_ram_threshold', ramThresholdPct);
    await prefs.setDouble('alert_temp_threshold', tempThresholdC);
    await prefs.setDouble('alert_storage_threshold', storageThresholdPct);
  }

  void startMonitoring(DeviceProvider provider) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      _check(provider);
    });
  }

  void _check(DeviceProvider provider) {
    final now = DateTime.now();

    // RAM
    if (ramAlertEnabled) {
      final ramPct = provider.ramPercent * 100;
      if (ramPct >= ramThresholdPct) {
        if (_lastRamAlert == null || now.difference(_lastRamAlert!) > _cooldown) {
          _notify(
            id: 1,
            title: '🧠 RAM Crítica — ${ramPct.toInt()}%',
            body: 'O uso de memória está em ${ramPct.toInt()}%. Considere fechar alguns apps.',
          );
          _lastRamAlert = now;
        }
      }
    }

    // Temperatura
    if (tempAlertEnabled) {
      if (provider.batteryTempC >= tempThresholdC) {
        if (_lastTempAlert == null || now.difference(_lastTempAlert!) > _cooldown) {
          _notify(
            id: 2,
            title: '🔥 Temperatura Alta — ${provider.batteryTempC.toStringAsFixed(1)}°C',
            body: 'Dispositivo aquecendo. Considere reduzir o uso por alguns minutos.',
          );
          _lastTempAlert = now;
        }
      }
    }

    // Armazenamento
    if (storageAlertEnabled) {
      final freePct = provider.storageTotal > 0
          ? (provider.storageFree / provider.storageTotal * 100)
          : 100.0;
      if (freePct <= storageThresholdPct) {
        if (_lastStorageAlert == null || now.difference(_lastStorageAlert!) > _cooldown) {
          _notify(
            id: 3,
            title: '💾 Armazenamento Crítico — ${freePct.toInt()}% livre',
            body: 'Apenas ${formatBytes(provider.storageFree)} livres. Libere espaço para o sistema funcionar bem.',
          );
          _lastStorageAlert = now;
        }
      }
    }
  }

  Future<void> _notify({required int id, required String title, required String body}) async {
    const androidDetails = AndroidNotificationDetails(
      'jlim_alerts',
      'Alertas J-LIM',
      channelDescription: 'Alertas de RAM, temperatura e armazenamento',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    await _notifications.show(id, title, body, const NotificationDetails(android: androidDetails));
  }

  void dispose() {
    _timer?.cancel();
  }
}
