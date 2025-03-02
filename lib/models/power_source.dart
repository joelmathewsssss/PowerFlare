import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'chat_message.dart';

class PowerSource {
  final String id;
  final String name;
  final String description;
  final String powerType;
  final bool isFree;
  final LatLng position;
  final List<ChatMessage> chatMessages;

  PowerSource({
    required this.id,
    required this.name,
    required this.description,
    required this.powerType,
    required this.isFree,
    required this.position,
    List<ChatMessage>? chatMessages,
  }) : chatMessages = chatMessages ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'powerType': powerType,
        'isFree': isFree,
        'position': {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
        'chatMessages': chatMessages.map((msg) => msg.toJson()).toList(),
      };

  factory PowerSource.fromJson(Map<String, dynamic> json) => PowerSource(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        powerType: json['powerType'] as String,
        isFree: json['isFree'] as bool,
        position: LatLng(
          json['position']['latitude'] as double,
          json['position']['longitude'] as double,
        ),
        chatMessages: (json['chatMessages'] as List?)
                ?.map(
                    (msg) => ChatMessage.fromJson(msg as Map<String, dynamic>))
                .toList() ??
            [],
      );
}
