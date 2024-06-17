import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:vis_aid/components/config.dart';

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
  late stt.SpeechToText _speechToText;
  ScrollController _scrollController = ScrollController();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initializeModel();
    flutterTts = FlutterTts();
    _speechToText = stt.SpeechToText();
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }

  Future<void> _initializeModel() async {
    final apiKey = ApiKey.key;

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

    _scrollToBottom();

    await flutterTts.speak(response.text ?? 'No description available.');
  }

  Future<void> _sendMessage(String message) async {
    if (message.isEmpty || _model == null) return;

    setState(() {
      _messages.add({
        'type': 'user',
        'message': message,
      });
    });

    var userMessage = Content.text(message);
    _chatHistory.add(userMessage);

    var response = await _model!.generateContent(_chatHistory);

    setState(() {
      _messages.add({
        'type': 'response',
        'message': response.text ?? 'No response available.',
      });
    });

    _scrollToBottom();

    await flutterTts.speak(response.text ?? 'No response available.');
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
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
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
                      _sendMessage(value);
                      _textController.clear();
                    },
                  ),
                ),
                IconButton(
                  icon:
                      Icon(_isListening ? Icons.mic_off : Icons.mic, size: 36),
                  onPressed: _isListening ? _stopListening : _startListening,
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
