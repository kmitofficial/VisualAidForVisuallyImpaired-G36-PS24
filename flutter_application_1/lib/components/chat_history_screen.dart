import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/components/conversation_model.dart';

class ChatHistoryScreen extends StatefulWidget {
  @override
  _ChatHistoryScreenState createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  List<Conversation> conversations = [];

  @override
  void initState() {
    super.initState();
    _getConversations();
  }

  Future<void> _getConversations() async {
    final conversationsSnapshot =
        await FirebaseFirestore.instance.collection('conversations').get();
    final conversationsList = conversationsSnapshot.docs.map((doc) {
      final conversationData = doc.data();
      return Conversation(
        imageUrl: conversationData['imageUrl'],
        imageDescription: conversationData['imageDescription'],
        messages: List<Message>.from(
          (conversationData['messages'] as List<dynamic>).map(
            (messageData) => Message(
              sender: messageData['sender'],
              text: messageData['text'],
            ),
          ),
        ),
      );
    }).toList();

    setState(() {
      conversations = conversationsList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat History'),
      ),
      body: ListView.builder(
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          final conversation = conversations[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.file(File(conversation.imageUrl)),
              Text(conversation.imageDescription),
              ...conversation.messages.map(
                (message) => Container(
                  padding: EdgeInsets.all(8.0),
                  color: message.sender == 'user' ? Colors.blue : Colors.grey,
                  child: Text(
                    message.text,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
