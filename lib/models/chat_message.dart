class ChatMessage {
  final String id;
  final String message;
  final DateTime timestamp;
  final String senderName;

  ChatMessage({
    required this.id,
    required this.message,
    required this.timestamp,
    required this.senderName,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        'senderName': senderName,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String,
        message: json['message'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        senderName: json['senderName'] as String,
      );
}
