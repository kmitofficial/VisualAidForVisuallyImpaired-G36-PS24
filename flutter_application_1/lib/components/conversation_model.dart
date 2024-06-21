class Conversation {
  String imageUrl;
  String imageDescription;
  List<Message> messages;

  Conversation({
    required this.imageUrl,
    required this.imageDescription,
    required this.messages,
  });

  Map<String, dynamic> toMap() {
    return {
      'imageUrl': imageUrl,
      'imageDescription': imageDescription,
      'messages': messages.map((message) => message.toMap()).toList(),
    };
  }

  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      imageUrl: map['imageUrl'] ?? '',
      imageDescription: map['imageDescription'] ?? '',
      messages: List<Message>.from(
        (map['messages'] ?? []).map(
          (messageData) => Message.fromMap(messageData),
        ),
      ),
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
