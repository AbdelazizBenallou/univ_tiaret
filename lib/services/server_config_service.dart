import 'package:shared_preferences/shared_preferences.dart';
import 'package:univ_tiaret/services/api_service.dart';

class ServerConfigService {
  static const _ipKey = 'server_ip';
  static const _portKey = 'server_port';
  static const _configuredKey = 'server_configured';

  static Future<void> saveConfig(String ip, int port) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ipKey, ip);
    await prefs.setInt(_portKey, port);
    await prefs.setBool(_configuredKey, true);
    ApiService.initialize('http://$ip:$port');
  }

  static Future<void> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final configured = prefs.getBool(_configuredKey) ?? false;
    if (configured) {
      final ip = prefs.getString(_ipKey) ?? '127.0.0.1';
      final port = prefs.getInt(_portKey) ?? 3000;
      ApiService.initialize('http://$ip:$port');
    } else {
      ApiService.initialize('http://localhost:3000');
    }
  }

  static Future<String> getIp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_ipKey) ?? '127.0.0.1';
  }

  static Future<int> getPort() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_portKey) ?? 3000;
  }

  static Future<bool> isConfigured() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_configuredKey) ?? false;
  }
}
