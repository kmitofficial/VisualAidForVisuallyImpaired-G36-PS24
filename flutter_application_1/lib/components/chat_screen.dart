import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/components/conversation_model.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatScreen extends StatefulWidget {
  final File imageFile;
  final String? conversationId;
  const ChatScreen({super.key, required this.imageFile, this.conversationId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  TextEditingController _textController = TextEditingController();
  List<Map<String, String>> _messages = [];
  late FlutterTts flutterTts;
  late stt.SpeechToText _speechToText;
  ScrollController _scrollController = ScrollController();
  bool _isListening = false;
  String? _conversationId;
  File? _currentImage;
  bool _imageSent = false;

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();
    _speechToText = stt.SpeechToText();
    _conversationId = widget.conversationId;
    _currentImage = widget.imageFile;
    if (_conversationId != null) {
      _loadExistingConversation();
    } else {
      _sendImage();
    }
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }

  Future<void> _loadExistingConversation() async {
    if (_conversationId == null) return;

    final conversationDoc = await FirebaseFirestore.instance
        .collection('conversations')
        .doc(_conversationId)
        .get();

    if (!conversationDoc.exists) return;

    final conversationData = conversationDoc.data() as Map<String, dynamic>;
    final conversation = Conversation.fromMap(conversationData);

    setState(() {
      _messages = conversation.messages
          .map((message) => {
                'type': message.sender == 'user' ? 'user' : 'response',
                'message': message.text,
              })
          .toList();
      _messages.insert(0, {
        'type': 'image',
        'message': conversation.imageUrl,
      });
      _imageSent = true;
    });

    _scrollToBottom();
  }

  Future<void> _sendImage() async {
    setState(() {
      _messages.add({
        'type': 'image',
        'message': _currentImage!.path,
      });
      _imageSent = true;
    });

    _scrollToBottom();

    final conversation = Conversation(
      imageUrl: _currentImage!.path,
      imageDescription: '',
      messages: [],
      timestamp: DateTime.now(),
    );

    final conversationRef = await FirebaseFirestore.instance
        .collection('conversations')
        .add(conversation.toMap());
    _conversationId = conversationRef.id;
  }

  Future<void> _sendMessage(String message) async {
    if (message.isEmpty) return;

    setState(() {
      _messages.add({
        'type': 'user',
        'message': message,
      });
    });

    _scrollToBottom();

    String response = await _getVQAResponse(message, _currentImage!);

    setState(() {
      _messages.add({
        'type': 'response',
        'message': response,
      });
    });

    if (_conversationId != null) {
      await FirebaseFirestore.instance
          .collection('conversations')
          .doc(_conversationId)
          .update({
        'messages': FieldValue.arrayUnion([
          {
            'sender': 'user',
            'text': message,
          },
          {
            'sender': 'model',
            'text': response,
          },
        ]),
      });
    }

    _scrollToBottom();
    await flutterTts.speak(response);
  }

  Future<String> _getVQAResponse(String question, File image) async {
    var request = http.MultipartRequest('POST', Uri.parse('http://10.0.2.2:5000/vqa'));
    request.fields['question'] = question;
    request.files.add(await http.MultipartFile.fromPath('image', image.path));

    var response = await request.send();
    if (response.statusCode == 200) {
      var responseData = await response.stream.bytesToString();
      var decodedResponse = json.decode(responseData);
      return decodedResponse['answer'];
    } else {
      return 'Error: ${response.statusCode}';
    }
  }

  Future<void> _startListening() async {
    bool available = await _speechToText.initialize();
    if (available) {
      setState(() {
        _isListening = true;
      });
      _speechToText.listen(
        onResult: (result) async {
          if (result.finalResult) {
            String recognizedWords = result.recognizedWords;
            await _sendMessage(recognizedWords);
          }
        },
      );
    }
  }

  Future<void> _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildMessageBubble(Map<String, String> message) {
    switch (message['type']) {
      case 'user':
        return Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              message['message']!,
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        );
      case 'response':
        return Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(message['message']!, style: TextStyle(fontSize: 18)),
          ),
        );
      case 'image':
        return Align(
          alignment: Alignment.center,
          child: Container(
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.all(10),
            child: Image.file(
              File(message['message']!),
              semanticLabel: 'Selected image',
              height: 300,
              width: 300,
            ),
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
        title: Text('Image Chat', style: TextStyle(fontSize: 28)),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Enter your message',
                      border: OutlineInputBorder(),
                    ),
                    style: TextStyle(fontSize: 18),
                    onSubmitted: (value) {
                      if (_imageSent) {
                        _sendMessage(value);
                        _textController.clear();
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(_isListening ? Icons.mic_off : Icons.mic, size: 36),
                  onPressed: _imageSent ? (_isListening ? _stopListening : _startListening) : null,
                  tooltip: _isListening ? 'Stop listening' : 'Start listening',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}