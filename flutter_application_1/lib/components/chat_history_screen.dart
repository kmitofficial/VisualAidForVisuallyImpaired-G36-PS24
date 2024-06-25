import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/components/conversation_model.dart';
import 'chat_screen.dart';

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
    final conversationsSnapshot = await FirebaseFirestore.instance
        .collection('conversations')
        .orderBy('timestamp', descending: true)
        .get();

    final conversationsList = conversationsSnapshot.docs.map((doc) {
      final conversationData = doc.data();
      return Conversation.fromMap({...conversationData, 'id': doc.id});
    }).toList();

    setState(() {
      conversations = conversationsList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat History', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: ListView.builder(
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          final conversation = conversations[index];
          return Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ExpansionTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(conversation.imageUrl),
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(
                  conversation.imageDescription,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  'Messages: ${conversation.messages.length}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                children: [
                  ...conversation.messages.map((message) => Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 4.0),
                        child: ListTile(
                          title: Text(
                            message.sender == 'user' ? 'You' : 'AI',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(message.text),
                          tileColor: message.sender == 'user'
                              ? Colors.blue[50]
                              : Colors.grey[100],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      )),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      child: Text('Continue this conversation'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              imageFile: File(conversation.imageUrl),
                              conversationId: conversation.id,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
