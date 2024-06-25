import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'login.dart';
import 'chat_screen.dart';

class ImagePickerScreen extends StatefulWidget {
  const ImagePickerScreen({super.key});

  @override
  State<ImagePickerScreen> createState() => _ImagePickerScreenState();
}

class _ImagePickerScreenState extends State<ImagePickerScreen> {
  File? galleryFile;
  final picker = ImagePicker();
  final String _description = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 247, 247),
      appBar: AppBar(
        title: const Text(
          'Gallery and Camera Access',
          style: TextStyle(fontSize: 24),
        ),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            onPressed: () async {
              await GoogleSignIn().signOut();
              FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
            icon: Icon(Icons.power_settings_new),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  _description,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black, fontSize: 18),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.photo_library, size: 50),
              onPressed: () {
                _pickImageAndDescribe(ImageSource.gallery);
              },
              tooltip: 'Pick an image from the gallery',
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 500.0,
              width: 300.0,
              child: galleryFile == null
                  ? const Center(
                      child: Text(
                        'Sorry, nothing selected!',
                        style: TextStyle(color: Colors.black, fontSize: 20),
                      ),
                    )
                  : Center(
                      child: Image.file(
                        galleryFile!,
                        semanticLabel: 'Selected image from gallery or camera',
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                _pickImageAndDescribe(ImageSource.camera);
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(300, 80),
                backgroundColor: Colors.blue,
              ),
              child: const Icon(Icons.photo_camera, size: 50),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageAndDescribe(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      final galleryFile = File(pickedFile.path);
      setState(() {
        this.galleryFile = galleryFile;
      });
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(imageFile: galleryFile),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing is selected')),
      );
    }
  }
}
