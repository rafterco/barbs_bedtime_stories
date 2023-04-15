import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class FirebaseImage extends StatefulWidget {
  final String storagePath;

  FirebaseImage({
    required this.storagePath,
  }) : super(key: Key(storagePath));

  @override
  State<FirebaseImage> createState() => _FirebaseImageState();
}

class _FirebaseImageState extends State<FirebaseImage> {
  File? _file;

  @override
  void initState() {
    init();
    super.initState();
  }

  Future<void> init() async {
    final imageFile = await getImageFile();
    if (mounted) {
      setState(() {
        _file = imageFile;
      });
    }
  }

  Future<File?> getImageFile() async {
    final storagePath = widget.storagePath;
    final tempDir = await getTemporaryDirectory();
    final fileName = widget.storagePath.split('/').last;
    final file = File('${tempDir.path}/$fileName');

    // If the file do not exists try to download
    if (!file.existsSync()) {
      try {
        file.create(recursive: true);
        await FirebaseStorage.instance.ref(storagePath).writeToFile(file);
      } catch (e) {
        // If there is an error delete the created file
        await file.delete(recursive: true);
        return null;
      }
    }
    return file;
  }

  @override
  Widget build(BuildContext context) {
    if (_file == null) {
      return const Icon(Icons.error);
    }
    return Image.file(
      _file!,
      width: 100,
      height: 100,
    );
  }
}