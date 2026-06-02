import 'dart:io' show Platform;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class DeviceChannel {
  static const MethodChannel _channel =
      MethodChannel('com.jlim/device');

  static bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  // ── RAM ──────────────────────────────────────────────
  static Future<Map<String, int>> getRamInfo() async {
    if (!_isAndroid) return {'total': 0, 'available': 0, 'used': 0};
    final result = await _channel.invokeMapMethod<String, int>('getRamInfo');
    return result ?? {'total': 0, 'available': 0, 'used': 0};
  }

  // ── CPU ──────────────────────────────────────────────
  static Future<double> getCpuUsage() async {
    if (!_isAndroid) return 0.0;
    final result = await _channel.invokeMethod<double>('getCpuUsage');
    return result ?? 0.0;
  }

  static Future<int> getCpuCores() async {
    if (!_isAndroid) return 1;
    final result = await _channel.invokeMethod<int>('getCpuCores');
    return result ?? 1;
  }

  // ── ARMAZENAMENTO ────────────────────────────────────
  static Future<Map<String, int>> getStorageInfo() async {
    if (!_isAndroid) return {'total': 0, 'free': 0, 'used': 0};
    final result =
        await _channel.invokeMapMethod<String, int>('getStorageInfo');
    return result ?? {'total': 0, 'free': 0, 'used': 0};
  }

  static Future<List<Map<String, dynamic>>> getAppStorageList() async {
    if (!_isAndroid) return [];
    final result =
        await _channel.invokeListMethod<Map>('getAppStorageList');
    return result?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
  }

  // ── BATERIA ──────────────────────────────────────────
  static Future<Map<String, dynamic>> getBatteryDetail() async {
    if (!_isAndroid) return {};
    final result =
        await _channel.invokeMapMethod<String, dynamic>('getBatteryDetail');
    return result ?? {};
  }

  // ── APPS INSTALADOS ──────────────────────────────────
  static Future<List<Map<String, dynamic>>> getInstalledApps() async {
    if (!_isAndroid) return [];
    final result =
        await _channel.invokeListMethod<Map>('getInstalledApps');
    return result?.map((e) => Map<String, dynamic>.from(e)).toList() ?? [];
  }

  static Future<void> openAppSettings(String packageName) async {
    if (!_isAndroid) return;
    await _channel
        .invokeMethod('openAppSettings', {'package': packageName});
  }

  static Future<void> uninstallApp(String packageName) async {
    if (!_isAndroid) return;
    await _channel.invokeMethod('uninstallApp', {'package': packageName});
  }

  // ── LIMPEZA ──────────────────────────────────────────
  static Future<void> openStorageSettings() async {
    if (!_isAndroid) return;
    await _channel.invokeMethod('openStorageSettings');
  }
}
