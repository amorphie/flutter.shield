import 'dart:io';
import 'package:system_proxy/system_proxy.dart';

abstract class _Constants {
  static const defaultHost = "localhost";
  static const defaultPort = "3100";
}

class ProxiedHttpOverrides extends HttpOverrides {
  final String host;
  final String port;

  ProxiedHttpOverrides({required this.host, required this.port});

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..findProxy = (_) {
        return "PROXY $host:$port; DIRECT";
      }
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        //add your certificate verification logic here
        return true;
      };
  }

  static Future<void> addSystemProxy() async {
    final Map<String, String>? proxy = await SystemProxy.getProxySettings();

    final host = proxy != null ? proxy['host'] ?? _Constants.defaultHost : _Constants.defaultHost;
    final port = proxy != null ? proxy['port'] ?? _Constants.defaultPort : _Constants.defaultPort;

    HttpOverrides.global = ProxiedHttpOverrides(host: host, port: port);
  }
}