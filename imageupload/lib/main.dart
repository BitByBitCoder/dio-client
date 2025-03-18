import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ImgBB Upload',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ImageUploadScreen(),
    );
  }
}

class ImageUploadScreen extends StatefulWidget {
  const ImageUploadScreen({super.key});

  @override
  State<ImageUploadScreen> createState() => _ImageUploadScreenState();
}

class _ImageUploadScreenState extends State<ImageUploadScreen> {
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  XFile? _image;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _uploadedImageUrl;
  String? _errorMessage;
  bool _useExistingAlbum = true;

  // Your ImgBB API key
  final String _apiKey = '6379b57e1d11a0d7a84f1483b9a93d0f';

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? selectedImage = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (selectedImage != null) {
      setState(() {
        _image = selectedImage;
        _uploadedImageUrl = null;
        _errorMessage = null;
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? capturedImage = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (capturedImage != null) {
      setState(() {
        _image = capturedImage;
        _uploadedImageUrl = null;
        _errorMessage = null;
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null) {
      setState(() {
        _errorMessage = 'Please select an image first';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
      _uploadedImageUrl = null;
      _uploadProgress = 0.0;
    });

    try {
      Map<String, dynamic> formMap = {
        'image': await MultipartFile.fromFile(
          _image!.path,
          filename: _image!.name,
        ),
      };

      if (_titleController.text.isNotEmpty) {
        formMap['name'] = _titleController.text;
      }

      if (_descriptionController.text.isNotEmpty) {
        formMap['description'] = _descriptionController.text;
      }

      if (_useExistingAlbum) {
        formMap['album'] = 'hruaia ralte\'s images';
      }

      FormData formData = FormData.fromMap(formMap);

      
      final response = await _dio.post(
        'https://api.imgbb.com/1/upload',
        data: formData,
        queryParameters: {
          'key': _apiKey,
        },
        onSendProgress: (sent, total) {
          setState(() {
            _uploadProgress = sent / total;
          });
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _uploadedImageUrl = response.data['data']['url'];
          _isUploading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Upload failed: ${response.data['error']['message'] ?? 'Unknown error'}';
          _isUploading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ImgBB Image Upload'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_image != null) ...[
              Container(
                height: 240,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_image!.path),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title input
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 16),

              // Description input
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Album selection
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Album',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      RadioListTile<bool>(
                        title: const Text(
                            'Existing album: hruaia ralte\'s images (Public)'),
                        value: true,
                        groupValue: _useExistingAlbum,
                        onChanged: (value) {
                          setState(() {
                            _useExistingAlbum = value!;
                          });
                        },
                      ),
                      RadioListTile<bool>(
                        title: const Text('Create new album'),
                        value: false,
                        groupValue: _useExistingAlbum,
                        onChanged: (value) {
                          setState(() {
                            _useExistingAlbum = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              if (_isUploading) ...[
                LinearProgressIndicator(
                  value: _uploadProgress,
                  backgroundColor: Colors.grey.shade200,
                ),
                const SizedBox(height: 10),
                Text(
                  'Uploading: ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: _uploadImage,
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Upload to ImgBB'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade800),
                ),
              ),
            ],
            if (_uploadedImageUrl != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Text(
                          'Upload Successful!',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Image URL:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: SelectableText(_uploadedImageUrl!),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            onPressed: () {
                              // Copy URL to clipboard
                            },
                            tooltip: 'Copy URL',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _uploadedImageUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
