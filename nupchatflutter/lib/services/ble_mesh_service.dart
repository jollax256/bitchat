import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/peer.dart';
import '../models/message.dart';
import '../core/config/transport_config.dart';

/// BLE Mesh Service for peer discovery and message routing
/// Uses flutter_blue_plus for Bluetooth Low Energy operations
class BleMeshService extends ChangeNotifier {
  static final BleMeshService _instance = BleMeshService._internal();
  factory BleMeshService() => _instance;
  BleMeshService._internal();

  // State
  bool _isScanning = false;
  final bool _isAdvertising = false;
  final List<Peer> _discoveredPeers = [];
  final List<BluetoothDevice> _connectedDevices = [];
  StreamSubscription? _scanSubscription;

  // My peer ID (generated on first run)
  String? _myPeerId;

  // Callbacks
  Function(Message)? onMessageReceived;
  Function(Peer)? onPeerDiscovered;
  Function(Peer)? onPeerDisconnected;

  // Service UUID for NupChat mesh - must match iOS BLEService.swift
  // iOS DEBUG/testnet: F47B5E2D-4A9E-4C5A-9B3F-8E1D2C3A4B5A
  // iOS RELEASE/mainnet: F47B5E2D-4A9E-4C5A-9B3F-8E1D2C3A4B5C
  static const String serviceUuid = 'F47B5E2D-4A9E-4C5A-9B3F-8E1D2C3A4B5A';
  static const String characteristicUuid =
      'A1B2C3D4-E5F6-4A5B-8C9D-0E1F2A3B4C5D';

  // Getters
  bool get isScanning => _isScanning;
  bool get isAdvertising => _isAdvertising;
  List<Peer> get discoveredPeers => List.unmodifiable(_discoveredPeers);
  String get myPeerId => _myPeerId ?? 'unknown';

  /// Initialize the BLE mesh service
  Future<void> initialize() async {
    // Generate or retrieve peer ID
    _myPeerId = _generatePeerId();

    // Check if Bluetooth is available
    if (await FlutterBluePlus.isSupported == false) {
      debugPrint('BLE Mesh: Bluetooth not supported on this device');
      return;
    }

    // Listen for adapter state changes
    FlutterBluePlus.adapterState.listen((state) {
      if (state == BluetoothAdapterState.on) {
        debugPrint('BLE Mesh: Bluetooth adapter is on');
      } else {
        debugPrint('BLE Mesh: Bluetooth adapter state: $state');
        stopScanning();
      }
    });
  }

  /// Start scanning for nearby mesh peers
  Future<void> startScanning() async {
    if (_isScanning) return;

    try {
      // Check Bluetooth state
      final state = await FlutterBluePlus.adapterState.first;
      if (state != BluetoothAdapterState.on) {
        debugPrint('BLE Mesh: Bluetooth is not on');
        return;
      }

      _isScanning = true;
      notifyListeners();

      debugPrint('BLE Mesh: Starting scan for peers...');

      // Start scanning
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        withServices: [Guid(serviceUuid)],
      );

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (final result in results) {
          _handleDiscoveredDevice(result);
        }
      });

      // Also listen for when scanning stops
      FlutterBluePlus.isScanning.listen((scanning) {
        if (!scanning && _isScanning) {
          _isScanning = false;
          notifyListeners();
        }
      });
    } catch (e) {
      debugPrint('BLE Mesh: Error starting scan: $e');
      _isScanning = false;
      notifyListeners();
    }
  }

  /// Stop scanning
  Future<void> stopScanning() async {
    if (!_isScanning) return;

    await FlutterBluePlus.stopScan();
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    _isScanning = false;
    notifyListeners();
  }

  /// Handle a discovered BLE device
  void _handleDiscoveredDevice(ScanResult result) {
    final device = result.device;
    final advertisementData = result.advertisementData;

    // Extract peer info from advertisement
    final peerId = device.remoteId.str;
    final nickname = advertisementData.advName.isNotEmpty
        ? advertisementData.advName
        : 'Peer-${peerId.substring(0, 6)}';

    // Check if we already know this peer
    final existingIndex = _discoveredPeers.indexWhere((p) => p.id == peerId);

    final peer = Peer(
      id: peerId,
      nickname: nickname,
      isOnline: true,
      lastSeen: DateTime.now(),
      type: PeerType.mesh,
    );

    if (existingIndex >= 0) {
      _discoveredPeers[existingIndex] = peer;
    } else {
      _discoveredPeers.add(peer);
      onPeerDiscovered?.call(peer);
    }

    notifyListeners();
  }

  /// Connect to a specific peer
  Future<bool> connectToPeer(Peer peer) async {
    try {
      final device = BluetoothDevice.fromId(peer.id);
      await device.connect(
        timeout: Duration(
          seconds: TransportConfig.bleConnectTimeoutSeconds.toInt(),
        ),
      );
      _connectedDevices.add(device);
      debugPrint('BLE Mesh: Connected to ${peer.nickname}');
      return true;
    } catch (e) {
      debugPrint('BLE Mesh: Failed to connect to ${peer.nickname}: $e');
      return false;
    }
  }

  /// Send a message to a peer via BLE
  Future<bool> sendMessage(Message message, {Peer? specificPeer}) async {
    final payload = message.toBinaryPayload();
    if (payload == null) {
      debugPrint('BLE Mesh: Failed to encode message');
      return false;
    }

    // For now, broadcast to all connected devices
    for (final device in _connectedDevices) {
      try {
        final services = await device.discoverServices();
        for (final service in services) {
          if (service.uuid.str.toLowerCase() == serviceUuid.toLowerCase()) {
            for (final characteristic in service.characteristics) {
              if (characteristic.uuid.str.toLowerCase() ==
                  characteristicUuid.toLowerCase()) {
                await characteristic.write(payload);
                debugPrint('BLE Mesh: Sent message to ${device.remoteId.str}');
              }
            }
          }
        }
      } catch (e) {
        debugPrint('BLE Mesh: Error sending to ${device.remoteId.str}: $e');
      }
    }

    return true;
  }

  /// Generate a unique peer ID
  String _generatePeerId() {
    // In production, this would be stored in secure storage
    final now = DateTime.now().millisecondsSinceEpoch;
    return 'nup-${now.toRadixString(36)}';
  }

  /// Clean up peer list (remove stale peers)
  void cleanupPeers() {
    final now = DateTime.now();
    final timeout = Duration(
      seconds: TransportConfig.blePeerInactivityTimeout.toInt(),
    );

    _discoveredPeers.removeWhere((peer) {
      if (peer.lastSeen == null) return false;
      return now.difference(peer.lastSeen!) > timeout;
    });

    notifyListeners();
  }

  /// Dispose resources
  @override
  void dispose() {
    stopScanning();
    for (final device in _connectedDevices) {
      device.disconnect();
    }
    super.dispose();
  }
}
