class BicoMessage {
  final String id;
  final String orderId;
  final String senderId; // "client" | "provider"
  final String senderName;
  final String type; // text
  final String content;
  final DateTime createdAt;

  const BicoMessage({
    required this.id,
    required this.orderId,
    required this.senderId,
    required this.senderName,
    required this.type,
    required this.content,
    required this.createdAt,
  });
}