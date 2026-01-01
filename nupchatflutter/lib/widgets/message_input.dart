import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/app_theme.dart';

class MessageInput extends StatefulWidget {
  final Function(String) onSend;
  final bool isEnabled;

  const MessageInput({super.key, required this.onSend, this.isEnabled = true});

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;
  late AnimationController _sendButtonController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _sendButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sendButtonController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    _sendButtonController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
      if (hasText) {
        _sendButtonController.forward();
      } else {
        _sendButtonController.reverse();
      }
    }
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      HapticFeedback.lightImpact();
      widget.onSend(text);
      _controller.clear();
      // Keep focus if desired, or maybe not
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.ebonyClay : AppColors.white;

    return Container(
      padding: EdgeInsets.fromLTRB(
        8,
        8,
        8,
        MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Attach Button
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              onPressed: () {},
              color: isDark
                  ? Colors.white.withValues(alpha: 0.5)
                  : AppColors.textSecondary.withValues(alpha: 0.5),
              splashRadius: 24,
            ),

            // Input Field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1C1C1E)
                      : const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 5,
                  minLines: 1,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Message',
                    hintStyle: TextStyle(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.3)
                          : Colors.black.withValues(alpha: 0.3),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    isDense: true,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.emoji_emotions_outlined),
                      onPressed: () {},
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.5)
                          : AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Send Button (Mic or Send)
            // Telegram swaps Mic/Send. We just show Send if text, otherwise maybe Mic (placeholder for now)
            SizedBox(
              width: 44,
              height: 44,
              child: Stack(
                children: [
                  // Mic Button (When no text) - Optional, keep simple for now
                  if (!_hasText)
                    Center(
                      child: IconButton(
                        icon: const Icon(Icons.mic_none_rounded),
                        onPressed: () {}, // Mic action
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.5)
                            : AppColors.textSecondary.withValues(alpha: 0.5),
                        splashRadius: 24,
                      ),
                    ),

                  // Send Button (Scaled in)
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryRed,
                        shape: BoxShape.circle,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: widget.isEnabled ? _handleSend : null,
                          child: const Icon(
                            Icons.arrow_upward_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
