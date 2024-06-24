import 'package:cloud_firestore/cloud_firestore.dart';

class Conversation {
  String? id;
  String imageUrl;
  String imageDescription;
  List<Message> messages;
  DateTime timestamp;

  Conversation({
    this.id,
    required this.imageUrl,
    required this.imageDescription,
    required this.messages,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'imageDescription': imageDescription,
      'messages': messages.map((message) => message.toMap()).toList(),
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      id: map['id'],
      imageUrl: map['imageUrl'] ?? '',
      imageDescription: map['imageDescription'] ?? '',
      messages: List<Message>.from(
        (map['messages'] ?? []).map(
          (messageData) => Message.fromMap(messageData),
        ),
      ),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}

class Message {
  String sender; // 'user' or 'model'
  String text;

  Message({
    required this.sender,
    required this.text,
  });

  Map<String, dynamic> toMap() {
    return {
      'sender': sender,
      'text': text,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      sender: map['sender'] ?? '',
      text: map['text'] ?? '',
    );
  }
}
