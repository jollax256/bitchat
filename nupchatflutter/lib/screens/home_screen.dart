import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/chat_service.dart';
import '../models/message.dart';
import '../models/channel.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input.dart';
import '../widgets/channel_header.dart';
import '../widgets/channel_drawer.dart';
import '../core/theme/app_theme.dart';
import 'settings_screen.dart';
import 'peer_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatService>().initialize();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatService>(
      builder: (context, chatService, child) {
        // Auto-scroll on new messages
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

        return Scaffold(
          key: _scaffoldKey,
          appBar: _buildAppBar(context, chatService),
          drawer: ChannelDrawer(
            currentChannel: chatService.currentChannel,
            locationChannels: chatService.getLocationChannels(),
            onChannelSelected: chatService.switchChannel,
            onSettingsPressed: () => _openSettings(context),
            hasLocationPermission: chatService.hasLocationPermission,
            onRequestLocationPermission: chatService.requestLocationPermission,
          ),
          body: Column(
            children: [
              _buildConnectionBar(chatService),
              Expanded(
                child: chatService.currentMessages.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        itemCount: chatService.currentMessages.length,
                        itemBuilder: (context, index) {
                          final message = chatService.currentMessages[index];
                          final isOwn = message.sender == chatService.nickname;

                          // Check for message chaining
                          bool showHeader = true;
                          bool showTail = true;

                          if (index > 0) {
                            final prev = chatService.currentMessages[index - 1];
                            if (prev.sender == message.sender) {
                              showHeader = false;
                            }
                          }
                          if (index < chatService.currentMessages.length - 1) {
                            final next = chatService.currentMessages[index + 1];
                            if (next.sender == message.sender) {
                              showTail = false;
                            }
                          }

                          return MessageBubble(
                            message: message,
                            isOwnMessage: isOwn,
                            showHeader: showHeader,
                            showTail: showTail,
                            onLongPress: () =>
                                _showMessageActions(context, message),
                          );
                        },
                      ),
              ),
              MessageInput(onSend: chatService.sendMessage),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ChatService chatService,
  ) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: ChannelHeader(
        channel: chatService.currentChannel,
        peerCount: chatService.activePeers.length,
        isScanning: chatService.isMeshScanning,
        onPeersPressed: () => _showPeerList(context),
      ),
      actions: [
        IconButton(
          icon: Icon(
            chatService.isMeshScanning
                ? Icons.bluetooth_searching_rounded
                : Icons.bluetooth_rounded,
            color: chatService.isMeshScanning ? AppColors.primaryRed : null,
          ),
          onPressed: () {
            HapticFeedback.selectionClick();
            if (chatService.isMeshScanning) {
              chatService.stopMeshScanning();
            } else {
              chatService.startMeshScanning();
            }
          },
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          height: 1,
        ),
      ),
    );
  }

  Widget _buildConnectionBar(ChatService chatService) {
    if (!chatService.isNostrConnected &&
        chatService.currentChannel.type == ChannelType.location) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 6),
        color: AppColors.warning.withValues(alpha: 0.1),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              'Connecting to relays...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              'assets/images/nuplogo.png',
              width: 64,
              height: 32,
              fit: BoxFit.contain,
              color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).disabledColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Start chatting with nearby peers",
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  void _showPeerList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const PeerListScreen(),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    Navigator.pop(context); // Close drawer
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  void _showMessageActions(BuildContext context, Message message) {
    final chatService = context.read<ChatService>();
    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.reply_rounded,
                  color: AppColors.navyBlue,
                ),
                title: const Text(
                  'Reply',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () => Navigator.pop(context),
              ),
              Divider(
                height: 1,
                indent: 56,
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
              ),
              ListTile(
                leading: const Icon(
                  Icons.copy_rounded,
                  color: AppColors.navyBlue,
                ),
                title: const Text(
                  'Copy Text',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: message.content));
                  Navigator.pop(context);
                },
              ),
              if (message.sender != chatService.nickname) ...[
                Divider(
                  height: 1,
                  indent: 56,
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.block_outlined,
                    color: AppColors.error,
                  ),
                  title: const Text(
                    'Block User',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    chatService.sendMessage('/block ${message.sender}');
                    Navigator.pop(context);
                  },
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
