import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ChatScreen extends StatefulWidget {
  final File imageFile;
  const ChatScreen({super.key, required this.imageFile});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  TextEditingController _textController = TextEditingController();
  List<Map<String, String>> _messages = [];
  GenerativeModel? _model;
  List<Content> _chatHistory = [];
  late FlutterTts flutterTts;

  @override
  void initState() {
    super.initState();
    _initializeModel();
    flutterTts = FlutterTts();
  }

  Future<void> _initializeModel() async {
    final apiKey =
        'AIzaSyBWak5ODA95xHBWYkF3QivZWxj0uWBAZPU'; // Replace with your actual API key

    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(maxOutputTokens: 100),
    );

    _sendImage();
  }

  Future<void> _sendImage() async {
    if (_model == null) return;

    final imageBytes = await widget.imageFile.readAsBytes();
    final prompt = TextPart("Describe the image.");
    final imagePart = DataPart('image/jpeg', imageBytes);

    // Start the chat with an initial description of the image
    _chatHistory = [
      Content.multi([prompt, imagePart])
    ];

    var response = await _model!.generateContent(_chatHistory);

    setState(() {
      _messages.add({
        'type': 'image',
        'message': widget.imageFile.path,
      });
      _messages.add({
        'type': 'response',
        'message': response.text ?? 'No description available.',
      });
    });
     await flutterTts.speak(response.text ?? 'No description available.');
  }

  Future<void> _sendMessage() async {
    if (_textController.text.isEmpty || _model == null) return;

    var userMessage = Content.text(_textController.text);
    _chatHistory.add(userMessage);

    var response = await _model!.generateContent(_chatHistory);

    setState(() {
      _messages.add({
        'type': 'user',
        'message': _textController.text,
      });
      _messages.add({
        'type': 'response',
        'message': response.text ?? 'No response available.',
      });
    });

    _textController.clear();
  }

  Widget _buildMessageBubble(Map<String, String> message) {
    switch (message['type']) {
      case 'user':
        return Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: EdgeInsets.all(10),
            margin: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              message['message']!,
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      case 'response':
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: EdgeInsets.all(10),
            margin: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(message['message']!),
          ),
        );
      case 'image':
        return Align(
          alignment: Alignment.center,
          child: Container(
            padding: EdgeInsets.all(10),
            margin: EdgeInsets.all(10),
            child: Image.file(File(message['message']!)),
          ),
        );
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Chat'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Enter your message',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}