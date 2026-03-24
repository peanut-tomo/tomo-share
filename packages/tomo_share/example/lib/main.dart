import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tomo_share/tomo_share.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ImagePicker _picker = ImagePicker();
  String _status = 'Tap a button to share to Telegram.';
  File? _selectedImage;

  Future<void> _shareTextToTelegram() async {
    try {
      await TomoShare.instance.shareTelegram(text: 'Hello from TomoShare');
      if (!mounted) return;
      setState(() {
        _status = 'Text share to Telegram triggered.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _status = error.toString());
    }
  }

  Future<void> _pickAndShareImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) {
        setState(() => _status = 'No image selected.');
        return;
      }

      setState(() {
        _selectedImage = File(image.path);
        _status = 'Image selected. Sharing to Telegram...';
      });

      await TomoShare.instance.shareTelegram(
        text: 'Check out this image!',
        imageFile: image.path,
      );

      if (!mounted) return;
      setState(() {
        _status = 'Image shared to Telegram successfully.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _status = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ImagePreview(image: _selectedImage),
                const SizedBox(height: 24),
                _ShareButton(
                  label: 'Share Text to Telegram',
                  icon: Icons.text_fields,
                  onPressed: _shareTextToTelegram,
                ),
                const SizedBox(height: 12),
                _ShareButton(
                  label: 'Pick Image & Share to TG',
                  icon: Icons.photo_library,
                  onPressed: _pickAndShareImage,
                ),
                const SizedBox(height: 16),
                Text(_status, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.image});

  final File? image;

  @override
  Widget build(BuildContext context) {
    if (image == null) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        image!,
        width: 200,
        height: 200,
        fit: BoxFit.cover,
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
