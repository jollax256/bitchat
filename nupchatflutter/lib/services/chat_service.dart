import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart';
import '../models/peer.dart';
import '../models/channel.dart';
import '../core/config/transport_config.dart';
import 'ble_mesh_service.dart';
import 'nostr_service.dart';
import 'location_service.dart';

/// Main Chat Service - Coordinates all messaging functionality
class ChatService extends ChangeNotifier {
  final BleMeshService _bleMeshService;
  final NostrService _nostrService;
  final LocationService _locationService;

  // State
  String _nickname = '';
  Channel _currentChannel = Channel.mesh;
  final Map<String, List<Message>> _channelMessages = {};
  final Map<String, List<Message>> _privateChats = {};
  final Set<String> _blockedUsers = {};

  // Prefs keys
  static const String _nicknameKey = 'nupchat_nickname';

  ChatService({
    BleMeshService? bleMeshService,
    NostrService? nostrService,
    LocationService? locationService,
  }) : _bleMeshService = bleMeshService ?? BleMeshService(),
       _nostrService = nostrService ?? NostrService(),
       _locationService = locationService ?? LocationService() {
    _setupCallbacks();
    // Listen to location changes and propagate to UI
    _locationService.addListener(_onLocationChanged);
  }

  void _onLocationChanged() {
    // Propagate location service updates to UI
    notifyListeners();
  }

  // Getters
  String get nickname => _nickname;
  Channel get currentChannel => _currentChannel;
  List<Message> get currentMessages =>
      _channelMessages[_currentChannel.id] ?? [];
  List<Peer> get activePeers {
    if (_currentChannel.type == ChannelType.mesh) {
      return _bleMeshService.discoveredPeers;
    } else {
      return _nostrService.geohashPeers;
    }
  }

  bool get isMeshScanning => _bleMeshService.isScanning;
  bool get isNostrConnected => _nostrService.isConnected;
  String get myPeerId => _bleMeshService.myPeerId;
  bool get hasLocationPermission => _locationService.hasPermission;

  /// Request location permission and refresh channels
  Future<void> requestLocationPermission() async {
    await _locationService.initialize();
    if (_locationService.hasPermission) {
      _locationService.startTracking();
    }
    notifyListeners();
  }

  /// Initialize all services
  Future<void> initialize() async {
    // Load saved preferences
    await _loadPreferences();

    // Initialize sub-services
    await _bleMeshService.initialize();
    await _nostrService.initialize();
    await _nostrService.connect(); // Connect to Nostr relays
    await _locationService.initialize();
    _locationService.startTracking(); // Start live location updates

    // Add welcome message
    _addSystemMessage('Welcome to NupChat! 🔴');
    _addSystemMessage('Type /help for available commands.');

    notifyListeners();
  }

  /// Setup callbacks from sub-services
  void _setupCallbacks() {
    _bleMeshService.onMessageReceived = _handleIncomingMessage;
    _bleMeshService.onPeerDiscovered = _handlePeerDiscovered;

    _nostrService.onMessageReceived = _handleIncomingMessage;
    _nostrService.onPeerDiscovered = _handlePeerDiscovered;
  }

  /// Load saved preferences
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _nickname =
          prefs.getString(_nicknameKey) ??
          'anon${DateTime.now().millisecondsSinceEpoch % 10000}';
    } catch (e) {
      _nickname = 'anon${DateTime.now().millisecondsSinceEpoch % 10000}';
    }
  }

  /// Save nickname
  Future<void> setNickname(String name) async {
    _nickname = name.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_nicknameKey, _nickname);
    } catch (e) {
      debugPrint('ChatService: Error saving nickname: $e');
    }
    notifyListeners();
  }

  /// Switch current channel
  Future<void> switchChannel(Channel channel) async {
    _currentChannel = channel;

    // Subscribe to location channel if needed
    if (channel.type == ChannelType.location && channel.geohash != null) {
      await _nostrService.subscribeToGeohash(channel.geohash!);
    }

    // Start mesh scanning if switching to mesh
    if (channel.type == ChannelType.mesh) {
      await _bleMeshService.startScanning();
    }

    _addSystemMessage('Joined ${channel.name}');
    notifyListeners();
  }

  /// Send a message
  Future<bool> sendMessage(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return false;

    // Check for commands
    if (trimmed.startsWith('/')) {
      return _processCommand(trimmed);
    }

    // Create message
    final message = Message(
      sender: _nickname,
      content: trimmed,
      timestamp: DateTime.now(),
      senderPeerId: myPeerId,
    );

    // Add to local messages
    _addMessage(message);

    // Send via appropriate transport
    if (_currentChannel.type == ChannelType.mesh) {
      await _bleMeshService.sendMessage(message);
    } else if (_currentChannel.geohash != null) {
      await _nostrService.sendToGeohash(trimmed, _currentChannel.geohash!);
    }

    return true;
  }

  /// Send a private message
  Future<bool> sendPrivateMessage(String content, Peer recipient) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return false;

    final message = Message(
      sender: _nickname,
      content: trimmed,
      timestamp: DateTime.now(),
      isPrivate: true,
      recipientNickname: recipient.nickname,
      senderPeerId: myPeerId,
      deliveryStatus: DeliveryStatus.sending,
    );

    // Add to private chat
    _privateChats.putIfAbsent(recipient.id, () => []);
    _privateChats[recipient.id]!.add(message);
    notifyListeners();

    // Send via appropriate transport
    bool sent = false;
    if (recipient.type == PeerType.mesh) {
      sent = await _bleMeshService.sendMessage(
        message,
        specificPeer: recipient,
      );
    } else if (recipient.nostrPubKey != null) {
      sent = await _nostrService.sendEncryptedDM(
        trimmed,
        recipient.nostrPubKey!,
      );
    }

    // Update delivery status
    if (sent) {
      message.deliveryStatus = DeliveryStatus.sent;
    } else {
      message.deliveryStatus = DeliveryStatus.failed;
    }
    notifyListeners();

    return sent;
  }

  /// Process IRC-style commands
  bool _processCommand(String command) {
    final parts = command.split(' ');
    final cmd = parts[0].toLowerCase();
    final args = parts.skip(1).join(' ');

    switch (cmd) {
      case '/help':
        _showHelp();
        return true;

      case '/nick':
        if (args.isNotEmpty) {
          setNickname(args);
          _addSystemMessage('Nickname changed to: $args');
        } else {
          _addSystemMessage('Usage: /nick <nickname>');
        }
        return true;

      case '/who':
        _showWho();
        return true;

      case '/slap':
        if (args.isNotEmpty) {
          final slapMessage = Message(
            sender: _nickname,
            content:
                '* $_nickname slaps $args around a bit with a large trout 🐟',
            timestamp: DateTime.now(),
            senderPeerId: myPeerId,
          );
          _addMessage(slapMessage);
        } else {
          _addSystemMessage('Usage: /slap <nickname>');
        }
        return true;

      case '/msg':
        final msgParts = args.split(' ');
        if (msgParts.length >= 2) {
          final targetNick = msgParts[0];
          final dmContent = msgParts.skip(1).join(' ');
          _addSystemMessage('Private message to $targetNick: $dmContent');
        } else {
          _addSystemMessage('Usage: /msg <nickname> <message>');
        }
        return true;

      case '/block':
        if (args.isNotEmpty) {
          _blockedUsers.add(args.toLowerCase());
          _addSystemMessage('Blocked: $args');
        } else {
          _addSystemMessage('Usage: /block <nickname>');
        }
        return true;

      case '/unblock':
        if (args.isNotEmpty) {
          _blockedUsers.remove(args.toLowerCase());
          _addSystemMessage('Unblocked: $args');
        } else {
          _addSystemMessage('Usage: /unblock <nickname>');
        }
        return true;

      case '/clear':
        _channelMessages[_currentChannel.id]?.clear();
        _addSystemMessage('Chat cleared');
        return true;

      default:
        _addSystemMessage(
          'Unknown command: $cmd. Type /help for available commands.',
        );
        return false;
    }
  }

  /// Show help message
  void _showHelp() {
    final help = '''
📡 NupChat Commands:
/help - Show this help message
/nick <name> - Change your nickname
/who - Show active peers
/slap <nick> - Slap someone with a trout
/msg <nick> <message> - Send private message
/block <nick> - Block a user
/unblock <nick> - Unblock a user
/clear - Clear chat history
''';
    _addSystemMessage(help);
  }

  /// Show who is online
  void _showWho() {
    final peers = activePeers;
    if (peers.isEmpty) {
      _addSystemMessage('No peers online in ${_currentChannel.name}');
    } else {
      final list = peers.map((p) => '• ${p.nickname}').join('\n');
      _addSystemMessage('Online in ${_currentChannel.name}:\n$list');
    }
  }

  /// Add a message to current channel
  void _addMessage(Message message) {
    _channelMessages.putIfAbsent(_currentChannel.id, () => []);
    _channelMessages[_currentChannel.id]!.add(message);

    // Enforce cap
    if (_channelMessages[_currentChannel.id]!.length >
        TransportConfig.meshTimelineCap) {
      _channelMessages[_currentChannel.id]!.removeAt(0);
    }

    notifyListeners();
  }

  /// Add a system message
  void _addSystemMessage(String content) {
    _addMessage(Message.system(content));
  }

  /// Handle incoming message from any transport
  void _handleIncomingMessage(Message message) {
    // Check if sender is blocked
    if (_blockedUsers.contains(message.sender.toLowerCase())) {
      return;
    }

    _addMessage(message);
  }

  /// Handle new peer discovery
  void _handlePeerDiscovered(Peer peer) {
    debugPrint('ChatService: Discovered peer ${peer.nickname}');
    notifyListeners();
  }

  /// Get private chat messages for a peer
  List<Message> getPrivateMessages(String peerId) {
    return _privateChats[peerId] ?? [];
  }

  /// Get available location channels
  List<Channel> getLocationChannels() {
    return _locationService.getLocationChannels();
  }

  /// Start mesh scanning
  Future<void> startMeshScanning() async {
    await _bleMeshService.startScanning();
    notifyListeners();
  }

  /// Stop mesh scanning
  Future<void> stopMeshScanning() async {
    await _bleMeshService.stopScanning();
    notifyListeners();
  }

  @override
  void dispose() {
    _locationService.removeListener(_onLocationChanged);
    _bleMeshService.dispose();
    _nostrService.dispose();
    _locationService.dispose();
    super.dispose();
  }
}
