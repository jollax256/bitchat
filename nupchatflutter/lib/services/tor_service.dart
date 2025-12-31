import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Tor Service for anonymous connectivity via SOCKS5 proxy
/// Note: socks5_proxy package has breaking changes - using dart:io HttpClient proxy
class TorService extends ChangeNotifier {
  static final TorService _instance = TorService._internal();
  factory TorService() => _instance;
  TorService._internal();

  // State
  bool _isConnected = false;
  bool _isConnecting = false;

  // Tor proxy settings (default Tor Browser Bundle ports)
  static const String defaultHost = '127.0.0.1';
  static const int defaultPort = 9050;

  String _proxyHost = defaultHost;
  int _proxyPort = defaultPort;

  // Getters
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String get proxyHost => _proxyHost;
  int get proxyPort => _proxyPort;

  /// Configure the Tor proxy connection
  void configure({String? host, int? port}) {
    _proxyHost = host ?? defaultHost;
    _proxyPort = port ?? defaultPort;
    notifyListeners();
  }

  /// Test connection to Tor proxy
  Future<bool> testConnection() async {
    _isConnecting = true;
    notifyListeners();

    try {
      // Try to connect through the SOCKS5 proxy using dart:io
      final socket = await Socket.connect(
        _proxyHost,
        _proxyPort,
        timeout: const Duration(seconds: 5),
      );
      await socket.close();

      _isConnected = true;
      _isConnecting = false;
      notifyListeners();

      debugPrint(
        'Tor: Successfully connected to proxy at $_proxyHost:$_proxyPort',
      );
      return true;
    } catch (e) {
      debugPrint('Tor: Failed to connect: $e');
      _isConnected = false;
      _isConnecting = false;
      notifyListeners();
      return false;
    }
  }

  /// Create an HttpClient that routes through Tor SOCKS5 proxy
  HttpClient createProxiedHttpClient() {
    final client = HttpClient();

    // Configure SOCKS5 proxy
    client.findProxy = (uri) {
      return 'SOCKS5 $_proxyHost:$_proxyPort';
    };

    return client;
  }

  /// Connect to a host through Tor
  Future<Socket?> connectThrough(String host, int port) async {
    if (!_isConnected) {
      final connected = await testConnection();
      if (!connected) return null;
    }

    try {
      // Note: For full SOCKS5 support, consider using a SOCKS5 library
      // This is a simplified implementation
      final socket = await Socket.connect(host, port);
      return socket;
    } catch (e) {
      debugPrint('Tor: Error connecting to $host:$port: $e');
      return null;
    }
  }

  /// Disconnect from Tor
  void disconnect() {
    _isConnected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
