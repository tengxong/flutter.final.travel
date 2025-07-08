import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart'; // สำหรับบันทึกข้อมูลโพสต์
import 'package:firebase_auth/firebase_auth.dart'; // สำหรับเข้าถึงข้อมูลผู้ใช้
import 'package:video_player/video_player.dart'; // สำหรับแสดงตัวอย่างวิดีโอ
import 'dart:io'; // สำหรับ File
import 'package:cloudinary_public/cloudinary_public.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final TextEditingController _captionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedMedia;
  String _mediaType = ''; // 'image' or 'video'
  bool _isLoading = false;
  VideoPlayerController? _videoPlayerController;
  late CloudinaryPublic cloudinary;

  @override
  void initState() {
    super.initState();
    cloudinary = CloudinaryPublic('dbi3y23tm', 'Travelling', cache: false);
  }

  @override
  void dispose() {
    _captionController.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  Future<void> _pickMedia(ImageSource source, {bool isVideo = false}) async {
    try {
      final XFile? media;
      if (isVideo) {
        media = await _picker.pickVideo(source: source);
      } else {
        media = await _picker.pickImage(source: source);
      }

      if (media != null) {
        setState(() {
          _selectedMedia = File(media!.path);
          _mediaType = isVideo ? 'video' : 'image';
        });

        if (isVideo) {
          _videoPlayerController?.dispose(); // Dispose previous controller if any
          _videoPlayerController = VideoPlayerController.file(_selectedMedia!)
            ..initialize().then((_) {
              setState(() {}); // Ensure the first frame is shown
              _videoPlayerController!.play();
            });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick media: $e')),
        );
      }
    }
  }

  Future<void> _uploadMediaAndPost() async {
    if (_selectedMedia == null || _captionController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select media and enter a caption.')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not logged in.')),
          );
        }
        setState(() { _isLoading = false; });
        return;
      }

      // Upload media to Cloudinary
      CloudinaryResourceType resourceType = _mediaType == 'video'
        ? CloudinaryResourceType.Video
        : CloudinaryResourceType.Image;
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(_selectedMedia!.path, resourceType: resourceType),
      );
      final String downloadUrl = response.secureUrl;

      // Save post data to Firestore
      await FirebaseFirestore.instance.collection('posts').add({
        'userId': user.uid,
        'username': user.displayName ?? user.email, // Use display name or email
        'mediaUrl': downloadUrl,
        'mediaType': _mediaType,
        'caption': _captionController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': 0,
        'comments': 0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post uploaded successfully!')),
        );
        Navigator.pop(context); // Go back after successful post
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload post: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showMediaPickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pick Image from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickMedia(ImageSource.gallery, isVideo: false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Image from Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickMedia(ImageSource.camera, isVideo: false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library),
                title: const Text('Pick Video from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickMedia(ImageSource.gallery, isVideo: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam),
                title: const Text('Take Video from Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickMedia(ImageSource.camera, isVideo: true);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Post'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Media Preview Area
            GestureDetector(
              onTap: _showMediaPickerOptions,
              child: Container(
                height: 200,
                color: Colors.grey[200],
                alignment: Alignment.center,
                child: _selectedMedia == null
                    ? Icon(Icons.add_a_photo, size: 60, color: Colors.grey[600])
                    : _mediaType == 'image'
                        ? Image.file(_selectedMedia!, fit: BoxFit.cover)
                        : _videoPlayerController != null && _videoPlayerController!.value.isInitialized
                            ? AspectRatio(
                                aspectRatio: _videoPlayerController!.value.aspectRatio,
                                child: VideoPlayer(_videoPlayerController!),
                              )
                            : const CircularProgressIndicator(),
              ),
            ),
            const SizedBox(height: 16),
            // Caption Input
            TextField(
              controller: _captionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Write a caption...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Post Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _uploadMediaAndPost,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.upload_file),
              label: Text(_isLoading ? 'Uploading...' : 'Post'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 