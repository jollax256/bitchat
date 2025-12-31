import 'dart:typed_data';
import 'package:uuid/uuid.dart';

/// Delivery status for private messages
enum DeliveryStatus { sending, sent, delivered, read, failed }

/// Represents a user-visible message in the NupChat system.
/// Handles both broadcast messages and private encrypted messages.
class Message {
  final String id;
  final String sender;
  final String content;
  final DateTime timestamp;
  final bool isRelay;
  final String? originalSender;
  final bool isPrivate;
  final String? recipientNickname;
  final String? senderPeerId;
  final List<String>? mentions;
  DeliveryStatus? deliveryStatus;
  final bool isSystem;

  Message({
    String? id,
    required this.sender,
    required this.content,
    required this.timestamp,
    this.isRelay = false,
    this.originalSender,
    this.isPrivate = false,
    this.recipientNickname,
    this.senderPeerId,
    this.mentions,
    DeliveryStatus? deliveryStatus,
    this.isSystem = false,
  }) : id = id ?? const Uuid().v4(),
       deliveryStatus =
           deliveryStatus ?? (isPrivate ? DeliveryStatus.sending : null);

  /// Create a system message
  factory Message.system(String content) {
    return Message(
      sender: 'system',
      content: content,
      timestamp: DateTime.now(),
      isSystem: true,
    );
  }

  /// Create a copy with updated delivery status
  Message copyWith({DeliveryStatus? deliveryStatus}) {
    return Message(
      id: id,
      sender: sender,
      content: content,
      timestamp: timestamp,
      isRelay: isRelay,
      originalSender: originalSender,
      isPrivate: isPrivate,
      recipientNickname: recipientNickname,
      senderPeerId: senderPeerId,
      mentions: mentions,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      isSystem: isSystem,
    );
  }

  /// Formatted timestamp for display
  String get formattedTimestamp {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
  }

  /// Encode message to binary payload for BLE transmission
  Uint8List? toBinaryPayload() {
    final buffer = BytesBuilder();

    // Flags byte
    int flags = 0;
    if (isRelay) flags |= 0x01;
    if (isPrivate) flags |= 0x02;
    if (originalSender != null) flags |= 0x04;
    if (recipientNickname != null) flags |= 0x08;
    if (senderPeerId != null) flags |= 0x10;
    if (mentions != null && mentions!.isNotEmpty) flags |= 0x20;
    buffer.addByte(flags);

    // Timestamp (milliseconds since epoch, 8 bytes big-endian)
    final timestampMillis = timestamp.millisecondsSinceEpoch;
    for (int i = 7; i >= 0; i--) {
      buffer.addByte((timestampMillis >> (i * 8)) & 0xFF);
    }

    // ID
    final idBytes = id.codeUnits;
    buffer.addByte(idBytes.length.clamp(0, 255));
    buffer.add(idBytes.take(255).toList());

    // Sender
    final senderBytes = sender.codeUnits;
    buffer.addByte(senderBytes.length.clamp(0, 255));
    buffer.add(senderBytes.take(255).toList());

    // Content
    final contentBytes = content.codeUnits;
    final contentLen = contentBytes.length.clamp(0, 65535);
    buffer.addByte((contentLen >> 8) & 0xFF);
    buffer.addByte(contentLen & 0xFF);
    buffer.add(contentBytes.take(contentLen).toList());

    // Optional fields
    if (originalSender != null) {
      final origBytes = originalSender!.codeUnits;
      buffer.addByte(origBytes.length.clamp(0, 255));
      buffer.add(origBytes.take(255).toList());
    }

    if (recipientNickname != null) {
      final recipBytes = recipientNickname!.codeUnits;
      buffer.addByte(recipBytes.length.clamp(0, 255));
      buffer.add(recipBytes.take(255).toList());
    }

    if (senderPeerId != null) {
      final peerBytes = senderPeerId!.codeUnits;
      buffer.addByte(peerBytes.length.clamp(0, 255));
      buffer.add(peerBytes.take(255).toList());
    }

    // Mentions
    if (mentions != null && mentions!.isNotEmpty) {
      buffer.addByte(mentions!.length.clamp(0, 255));
      for (final mention in mentions!.take(255)) {
        final mentionBytes = mention.codeUnits;
        buffer.addByte(mentionBytes.length.clamp(0, 255));
        buffer.add(mentionBytes.take(255).toList());
      }
    }

    return buffer.toBytes();
  }

  /// Decode message from binary payload
  static Message? fromBinaryPayload(Uint8List data) {
    if (data.length < 13) return null;

    int offset = 0;

    // Flags
    final flags = data[offset++];
    final isRelay = (flags & 0x01) != 0;
    final isPrivate = (flags & 0x02) != 0;
    final hasOriginalSender = (flags & 0x04) != 0;
    final hasRecipientNickname = (flags & 0x08) != 0;
    final hasSenderPeerId = (flags & 0x10) != 0;
    final hasMentions = (flags & 0x20) != 0;

    // Timestamp
    if (offset + 8 > data.length) return null;
    int timestampMillis = 0;
    for (int i = 0; i < 8; i++) {
      timestampMillis = (timestampMillis << 8) | data[offset++];
    }
    final timestamp = DateTime.fromMillisecondsSinceEpoch(timestampMillis);

    // ID
    if (offset >= data.length) return null;
    final idLength = data[offset++];
    if (offset + idLength > data.length) return null;
    final id = String.fromCharCodes(data.sublist(offset, offset + idLength));
    offset += idLength;

    // Sender
    if (offset >= data.length) return null;
    final senderLength = data[offset++];
    if (offset + senderLength > data.length) return null;
    final sender = String.fromCharCodes(
      data.sublist(offset, offset + senderLength),
    );
    offset += senderLength;

    // Content
    if (offset + 2 > data.length) return null;
    final contentLength = (data[offset] << 8) | data[offset + 1];
    offset += 2;
    if (offset + contentLength > data.length) return null;
    final content = String.fromCharCodes(
      data.sublist(offset, offset + contentLength),
    );
    offset += contentLength;

    // Optional fields
    String? originalSender;
    if (hasOriginalSender && offset < data.length) {
      final length = data[offset++];
      if (offset + length <= data.length) {
        originalSender = String.fromCharCodes(
          data.sublist(offset, offset + length),
        );
        offset += length;
      }
    }

    String? recipientNickname;
    if (hasRecipientNickname && offset < data.length) {
      final length = data[offset++];
      if (offset + length <= data.length) {
        recipientNickname = String.fromCharCodes(
          data.sublist(offset, offset + length),
        );
        offset += length;
      }
    }

    String? senderPeerId;
    if (hasSenderPeerId && offset < data.length) {
      final length = data[offset++];
      if (offset + length <= data.length) {
        senderPeerId = String.fromCharCodes(
          data.sublist(offset, offset + length),
        );
        offset += length;
      }
    }

    List<String>? mentions;
    if (hasMentions && offset < data.length) {
      final mentionCount = data[offset++];
      mentions = [];
      for (int i = 0; i < mentionCount && offset < data.length; i++) {
        final length = data[offset++];
        if (offset + length <= data.length) {
          mentions.add(
            String.fromCharCodes(data.sublist(offset, offset + length)),
          );
          offset += length;
        }
      }
    }

    return Message(
      id: id,
      sender: sender,
      content: content,
      timestamp: timestamp,
      isRelay: isRelay,
      originalSender: originalSender,
      isPrivate: isPrivate,
      recipientNickname: recipientNickname,
      senderPeerId: senderPeerId,
      mentions: mentions,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
