import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dart_nostr/dart_nostr.dart';
import '../models/message.dart';
import '../models/peer.dart';
import '../core/config/transport_config.dart';

/// Nostr Service for global messaging via relays
/// Uses dart_nostr for Nostr protocol operations
class NostrService extends ChangeNotifier {
  static final NostrService _instance = NostrService._internal();
  factory NostrService() => _instance;
  NostrService._internal();

  // State
  bool _isConnected = false;
  final List<String> _connectedRelays = [];
  final Map<String, List<Message>> _geohashMessages = {};
  final List<Peer> _geohashPeers = [];

  // Current identity
  NostrKeyPairs? _keyPairs;

  // Callbacks
  Function(Message)? onMessageReceived;
  Function(Peer)? onPeerDiscovered;

  // Default relays
  static const List<String> defaultRelays = [
    'wss://relay.damus.io',
    'wss://relay.nostr.band',
    'wss://nos.lol',
    'wss://relay.snort.social',
    'wss://nostr.wine',
  ];

  // Getters
  bool get isConnected => _isConnected;
  List<String> get connectedRelays => List.unmodifiable(_connectedRelays);
  String? get publicKey => _keyPairs?.public;
  String? get npub {
    if (_keyPairs == null) return null;
    try {
      return Nostr.instance.keysService.encodePublicKeyToNpub(
        _keyPairs!.public,
      );
    } catch (e) {
      return null;
    }
  }

  /// Initialize the Nostr service with a new or existing keypair
  Future<void> initialize({String? privateKey}) async {
    try {
      if (privateKey != null) {
        _keyPairs = Nostr.instance.keysService
            .generateKeyPairFromExistingPrivateKey(privateKey);
      } else {
        _keyPairs = Nostr.instance.keysService.generateKeyPair();
      }
      debugPrint('Nostr: Initialized with public key: ${_keyPairs?.public}');
    } catch (e) {
      debugPrint('Nostr: Error initializing: $e');
    }
  }

  /// Connect to Nostr relays
  Future<void> connect({List<String>? relays}) async {
    final relaysToUse =
        relays ??
        defaultRelays.take(TransportConfig.nostrGeoRelayCount).toList();

    try {
      await Nostr.instance.relaysService.init(
        relaysUrl: relaysToUse,
        onRelayListening: (relay, url, channel) {
          debugPrint('Nostr: Connected to relay $url');
          if (!_connectedRelays.contains(url)) {
            _connectedRelays.add(url);
          }
          _isConnected = _connectedRelays.isNotEmpty;
          notifyListeners();
        },
        onRelayConnectionError: (relay, error, channel) {
          debugPrint('Nostr: Error connecting to relay: $error');
        },
        onRelayConnectionDone: (relay, channel) {
          debugPrint('Nostr: Disconnected from relay');
          _connectedRelays.remove(relay);
          _isConnected = _connectedRelays.isNotEmpty;
          notifyListeners();
        },
      );

      _isConnected = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Nostr: Error connecting to relays: $e');
      _isConnected = false;
      notifyListeners();
    }
  }

  /// Subscribe to a geohash location channel
  Future<void> subscribeToGeohash(String geohash) async {
    if (_keyPairs == null) {
      debugPrint('Nostr: Cannot subscribe without initialized keypair');
      return;
    }

    try {
      final filter = NostrFilter(
        kinds: const [1],
        t: [geohash.toLowerCase()],
        limit: TransportConfig.nostrGeohashInitialLimit,
        since: DateTime.now().subtract(
          Duration(
            seconds: TransportConfig.nostrGeohashInitialLookbackSeconds.toInt(),
          ),
        ),
      );

      final request = NostrRequest(filters: [filter]);

      final subscription = Nostr.instance.relaysService.startEventsSubscription(
        request: request,
        onEose: (eose) {
          debugPrint('Nostr: End of stored events for geohash $geohash');
        },
      );

      subscription.stream.listen((NostrEvent event) {
        _handleNostrEvent(event, geohash);
      });

      debugPrint('Nostr: Subscribed to geohash $geohash');
    } catch (e) {
      debugPrint('Nostr: Error subscribing to geohash: $e');
    }
  }

  /// Handle incoming Nostr event
  void _handleNostrEvent(NostrEvent event, String geohash) {
    try {
      // Extract event data using reflection-safe access
      final eventId = _getEventId(event);
      final eventPubkey = _getEventPubkey(event);
      final eventContent = _getEventContent(event);
      final eventTimestamp = _getEventCreatedAt(event);

      final message = Message(
        id: eventId,
        sender: _shortPubKey(eventPubkey),
        content: eventContent,
        timestamp: eventTimestamp,
        senderPeerId: eventPubkey,
      );

      _geohashMessages.putIfAbsent(geohash, () => []);
      if (!_geohashMessages[geohash]!.any((m) => m.id == message.id)) {
        _geohashMessages[geohash]!.add(message);
        onMessageReceived?.call(message);
      }

      final peer = Peer(
        id: eventPubkey,
        nickname: _shortPubKey(eventPubkey),
        isOnline: true,
        lastSeen: DateTime.now(),
        type: PeerType.nostr,
        nostrPubKey: eventPubkey,
      );

      if (!_geohashPeers.any((p) => p.id == peer.id)) {
        _geohashPeers.add(peer);
        onPeerDiscovered?.call(peer);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Nostr: Error handling event: $e');
    }
  }

  // Helper methods to safely access NostrEvent properties
  String _getEventId(NostrEvent event) {
    try {
      // dart_nostr may use different property access
      return (event as dynamic).id?.toString() ?? '';
    } catch (e) {
      return '';
    }
  }

  String _getEventPubkey(NostrEvent event) {
    try {
      return (event as dynamic).pubkey?.toString() ?? '';
    } catch (e) {
      return '';
    }
  }

  String _getEventContent(NostrEvent event) {
    try {
      return (event as dynamic).content?.toString() ?? '';
    } catch (e) {
      return '';
    }
  }

  DateTime _getEventCreatedAt(NostrEvent event) {
    try {
      final createdAt = (event as dynamic).createdAt;
      if (createdAt is DateTime) return createdAt;
      if (createdAt is int) {
        return DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
      }
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  /// Send a message to a geohash channel
  Future<bool> sendToGeohash(String content, String geohash) async {
    if (_keyPairs == null) {
      debugPrint('Nostr: Cannot send without initialized keypair');
      return false;
    }

    try {
      final event = NostrEvent.fromPartialData(
        kind: 1,
        content: content,
        keyPairs: _keyPairs!,
        tags: [
          ['t', geohash.toLowerCase()],
        ],
      );

      Nostr.instance.relaysService.sendEventToRelays(
        event,
        onOk: (ok) {
          debugPrint('Nostr: Message sent successfully');
        },
      );

      return true;
    } catch (e) {
      debugPrint('Nostr: Error sending message: $e');
      return false;
    }
  }

  /// Send encrypted DM (simplified - in production use proper NIP-04/NIP-44)
  Future<bool> sendEncryptedDM(String content, String recipientPubKey) async {
    if (_keyPairs == null) {
      debugPrint('Nostr: Cannot send DM without initialized keypair');
      return false;
    }

    try {
      final event = NostrEvent.fromPartialData(
        kind: 4,
        content: content,
        keyPairs: _keyPairs!,
        tags: [
          ['p', recipientPubKey],
        ],
      );

      Nostr.instance.relaysService.sendEventToRelays(event);
      debugPrint('Nostr: DM sent to $recipientPubKey');

      return true;
    } catch (e) {
      debugPrint('Nostr: Error sending DM: $e');
      return false;
    }
  }

  String _shortPubKey(String pubKey) {
    if (pubKey.length <= 8) return pubKey;
    return '${pubKey.substring(0, 4)}...${pubKey.substring(pubKey.length - 4)}';
  }

  List<Message> getGeohashMessages(String geohash) {
    return _geohashMessages[geohash] ?? [];
  }

  List<Peer> get geohashPeers => List.unmodifiable(_geohashPeers);

  Future<void> disconnect() async {
    _connectedRelays.clear();
    _isConnected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
