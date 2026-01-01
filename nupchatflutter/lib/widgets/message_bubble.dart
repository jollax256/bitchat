import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/message.dart';
import '../core/theme/app_theme.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isOwnMessage;
  final VoidCallback? onLongPress;
  final VoidCallback? onReply;
  final bool showHeader;
  final bool showTail;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isOwnMessage,
    this.onLongPress,
    this.onReply,
    this.showHeader = true,
    this.showTail = true,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) {
      return _SystemMessage(message: message);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor = isOwnMessage
        ? AppColors.primaryRed
        : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7));

    final textColor = isOwnMessage
        ? Colors.white
        : (isDark ? Colors.white : AppColors.textPrimary);

    // Telegram-style border radius: rounded on all corners except the tail corner
    final borderRadius = isOwnMessage
        ? const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4), // Tail corner
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(4), // Tail corner
            bottomRight: Radius.circular(18),
          );

    return GestureDetector(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        onLongPress?.call();
      },
      child: Container(
        margin: EdgeInsets.only(
          top: 2,
          bottom: showTail ? 6 : 2,
          left: isOwnMessage ? 60 : 8,
          right: isOwnMessage ? 8 : 60,
        ),
        alignment: isOwnMessage ? Alignment.centerRight : Alignment.centerLeft,
        child: Row(
          mainAxisAlignment: isOwnMessage
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isOwnMessage && showTail && showHeader) ...[
              _Avatar(name: message.sender),
              const SizedBox(width: 8),
            ] else if (!isOwnMessage) ...[
              const SizedBox(width: 40),
            ],

            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: showTail
                      ? borderRadius
                      : BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isOwnMessage && showHeader)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          message.sender,
                          style: const TextStyle(
                            color: AppColors.primaryRed,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),

                    _buildMessageContent(context, textColor),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, Color textColor) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '${message.content}  ', // Add spacing for the time
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontFamily: 'Inter',
              height: 1.3,
            ),
          ),
          WidgetSpan(
            alignment: PlaceholderAlignment.bottom,
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.formattedTimestamp,
                    style: TextStyle(
                      fontSize: 11,
                      color: textColor.withValues(alpha: 0.6),
                    ),
                  ),
                  if (isOwnMessage) ...[
                    const SizedBox(width: 4),
                    Icon(
                      _getStatusIcon(message.deliveryStatus),
                      size: 14,
                      color: textColor.withValues(alpha: 0.8),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(DeliveryStatus? status) {
    switch (status) {
      case DeliveryStatus.sending:
        return Icons.access_time_rounded;
      case DeliveryStatus.sent:
        return Icons.check_rounded;
      case DeliveryStatus.delivered:
        return Icons.done_all_rounded;
      case DeliveryStatus.read:
        return Icons.done_all_rounded;
      case DeliveryStatus.failed:
        return Icons.error_outline_rounded;
      default:
        return Icons.access_time_rounded;
    }
  }
}

class _Avatar extends StatelessWidget {
  final String name;

  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) {
    // Premium Gradients
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
    );

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: gradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _SystemMessage extends StatelessWidget {
  final Message message;

  const _SystemMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          message.content,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
