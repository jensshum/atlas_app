import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefKey = 'atlas_server_ip';
const _port = 3000;

class DiscoveryService {
  static Future<String?> getCachedIp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKey);
  }

  static Future<void> cacheIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, ip);
  }

  static Future<void> clearCachedIp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }

  /// Check a single IP for the Siri2 server.
  static Future<bool> checkIp(String ip) async {
    try {
      final uri = Uri.parse('http://$ip:$_port/health');
      final response = await http.get(uri).timeout(const Duration(milliseconds: 500));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return body['agent'] == 'siri2';
      }
    } catch (_) {}
    return false;
  }

  /// Request location permission needed for WiFi IP on Android 12+.
  static Future<bool> _ensureLocationPermission() async {
    var status = await Permission.locationWhenInUse.status;
    if (status.isGranted) return true;
    status = await Permission.locationWhenInUse.request();
    return status.isGranted;
  }

  /// Derive the /24 subnet from the device's WiFi IP.
  static Future<String?> _getSubnet() async {
    try {
      await _ensureLocationPermission();
      final info = NetworkInfo();
      final ip = await info.getWifiIP();
      if (ip == null) return null;
      final parts = ip.split('.');
      if (parts.length != 4) return null;
      return '${parts[0]}.${parts[1]}.${parts[2]}';
    } catch (_) {
      return null;
    }
  }

  /// Scan the local /24 subnet for the Siri2 server.
  /// [onProgress] is called with the number of IPs checked so far.
  static Future<String?> scanNetwork({void Function(int checked, int total)? onProgress}) async {
    final subnet = await _getSubnet();
    if (subnet == null) return null;

    const total = 254;
    int checked = 0;
    const batchSize = 30;

    for (int batchStart = 1; batchStart <= total; batchStart += batchSize) {
      final batchEnd = (batchStart + batchSize - 1).clamp(1, total);
      final futures = <Future<String?>>[];

      for (int i = batchStart; i <= batchEnd; i++) {
        final ip = '$subnet.$i';
        futures.add(_checkAndReturn(ip));
      }

      final results = await Future.wait(futures);
      checked += results.length;
      onProgress?.call(checked, total);

      for (final result in results) {
        if (result != null) return result;
      }
    }

    return null;
  }

  static Future<String?> _checkAndReturn(String ip) async {
    final found = await checkIp(ip);
    return found ? ip : null;
  }

  /// Try cached IP first, then scan if not found.
  static Future<String?> discover({void Function(int checked, int total)? onProgress}) async {
    final cached = await getCachedIp();
    if (cached != null) {
      final alive = await checkIp(cached);
      if (alive) return cached;
      await clearCachedIp();
    }
    final found = await scanNetwork(onProgress: onProgress);
    if (found != null) await cacheIp(found);
    return found;
  }
}
