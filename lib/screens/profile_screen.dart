import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'package:logger/logger.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import '../screens/login_screen.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _twitterController = TextEditingController();
  final _facebookController = TextEditingController();
  User? _user; // To store the current user
  final _logger = Logger();
  bool _isUploading = false;
  late CloudinaryPublic cloudinary;

  @override
  void initState() {
    super.initState();
    try {
      cloudinary = CloudinaryPublic('dbi3y23tm', 'Travelling', cache: false);
      _logger.i('Cloudinary initialized successfully');
    } catch (e) {
      _logger.e('Error initializing Cloudinary', error: e);
    }
    _loadUserData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _twitterController.dispose();
    _facebookController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (mounted) {
        setState(() {
          _user = user;
        });
      }
      
      if (user != null) {
        int retryCount = 0;
        const maxRetries = 3;
        
        while (retryCount < maxRetries) {
          try {
            final userData = await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
            
            if (userData.exists) {
              if (mounted) {
                setState(() {
                  _usernameController.text = userData.data()?['username'] ?? user.displayName ?? '';
                  _phoneController.text = (userData.data()?['phone'] ?? '').toString();
                  _twitterController.text = userData.data()?['twitter'] ?? '';
                  _facebookController.text = userData.data()?['facebook'] ?? '';
                });
                // Update Firebase Auth displayName to match Firestore username
                if (userData.data()?['username'] != null && user.displayName != userData.data()?['username']) {
                  await user.updateDisplayName(userData.data()?['username']);
                }
              }
            } else {
              if (mounted) {
                setState(() {
                  _usernameController.text = user.displayName ?? '';
                });
              }
            }
            break;
          } catch (e) {
            retryCount++;
            if (e.toString().contains('NOT_FOUND') || e.toString().contains('database does not exist')) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Please create Firestore Database in Firebase Console'),
                    duration: const Duration(seconds: 5),
                    action: SnackBarAction(
                      label: 'How to fix',
                      onPressed: () {},
                    ),
                  ),
                );
              }
              break;
            }
            
            if (retryCount == maxRetries) {
              if (mounted) {
                setState(() {
                  _usernameController.text = user.displayName ?? '';
                  _phoneController.text = '';
                  _twitterController.text = '';
                  _facebookController.text = '';
                });
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Unable to load additional data. Please try again.'),
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            } else {
              await Future.delayed(Duration(seconds: pow(2, retryCount).toInt()));
            }
          }
        }
      }
    } catch (e) {
      _logger.e('Error loading user data', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error loading data. Please try again.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    if (_user == null) return;

    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        if (mounted) {
          setState(() {
            _isUploading = true;
          });
        }

        try {
          final file = File(image.path);
          if (!await file.exists()) {
            throw Exception('File not found');
          }
          final fileSize = await file.length();
          if (fileSize > 5 * 1024 * 1024) {
            throw Exception('File too large (max 5MB)');
          }

          // Upload to Cloudinary
          _logger.i('Starting Cloudinary upload for file: ${image.path}');
          CloudinaryResponse response = await cloudinary.uploadFile(
            CloudinaryFile.fromFile(
              image.path, 
              resourceType: CloudinaryResourceType.Image,
            ),
          );
          final downloadUrl = response.secureUrl;
          _logger.i('Cloudinary upload successful: $downloadUrl');

          // Update user profile
          await _user!.updatePhotoURL(downloadUrl);

          // Update Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_user!.uid)
              .update({
                'photoURL': downloadUrl,
                'lastUpdated': FieldValue.serverTimestamp(),
              });

          if (mounted) {
            setState(() {
              _isUploading = false;
            });
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile picture updated successfully'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        } catch (uploadError) {
          _logger.e('Error during upload process', error: uploadError);
          if (mounted) {
            setState(() {
              _isUploading = false;
            });
          }
          
          String errorMessage = 'Error uploading image';
          if (uploadError.toString().contains('Cloudinary')) {
            errorMessage = 'Cloudinary upload failed: ${uploadError.toString()}';
          } else if (uploadError.toString().contains('network')) {
            errorMessage = 'Network error. Please check your internet connection.';
          } else if (uploadError.toString().contains('permission')) {
            errorMessage = 'Permission denied. Please check app permissions.';
          }
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                duration: const Duration(seconds: 6),
                backgroundColor: Colors.red,
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () => _pickAndUploadImage(),
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      _logger.e('Error picking or uploading image', error: e);
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
      String errorMessage = 'Error picking or uploading image';
      if (e.toString().contains('permission')) {
        errorMessage = 'No permission to access gallery';
      } else if (e.toString().contains('cancel')) {
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateUsername(String newUsername) async {
    if (_user != null) {
      try {
        // Update Firebase Auth displayName
        await _user!.updateDisplayName(newUsername);
        
        // Update Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .update({'username': newUsername});
            
        setState(() {
          _usernameController.text = newUsername;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Username updated successfully'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        _logger.e('Error updating username', error: e);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error updating username'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _updateSocialLink(String type, String value) async {
    if (_user != null) {
      try {
        // Update Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .update({type: value});
            
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$type updated successfully'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        _logger.e('Error updating $type', error: e);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating $type'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  void _showEditDialog(String title, TextEditingController controller, String fieldType) {
    final textController = TextEditingController(text: controller.text);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $title'),
        content: TextField(
          controller: textController,
          decoration: InputDecoration(
            hintText: 'Enter $title link',
            prefixIcon: Icon(Icons.link),
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final value = textController.text.trim();
              if (value.isNotEmpty) {
                controller.text = value;
                _updateSocialLink(fieldType, value);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 250, 250, 250),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.lightBlue),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/home', // ใช้ route name ของหน้าหลัก
              (route) => false, // ลบทุก route ที่อยู่ด้านบนออกจาก stack
            );
          },
        ),
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(
            color: Colors.lightBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              // Handle settings action
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 43, 101, 160),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    // backgroundColor: Colors.white,
                    child: Stack(
                      children: [
                        GestureDetector(
                          onTap: _isUploading ? null : _pickAndUploadImage,
                          child: ClipOval(
                            child: (_user?.photoURL != null && _user!.photoURL!.isNotEmpty)
                                ? Image.network(
                                    _user!.photoURL!,
                                    fit: BoxFit.cover,
                                    width: 96,
                                    height: 96,
                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 50, color: Colors.grey),
                                  )
                                : const Icon(Icons.person, size: 50, color: Colors.grey),
                          ),
                        ),
                        if (_isUploading)
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(red: 0, green: 0, blue: 0, alpha: 128),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                    children: [
                      Expanded(
                        child: Text(
                          _usernameController.text.isNotEmpty ? _usernameController.text : (_user?.displayName ?? ''),
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            color: Colors.white,
                                  fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                        onPressed: () {
                                final textController = TextEditingController(text: _usernameController.text);
                          showDialog(
                            context: context,
                                  builder: (context) {
                                    return AlertDialog(
                              title: const Text('Edit Username'),
                              content: TextField(
                                        controller: textController,
                                decoration: const InputDecoration(
                                  hintText: 'Enter username',
                                ),
                                onSubmitted: (value) {
                                  if (value.isNotEmpty) {
                                    _updateUsername(value);
                                    Navigator.pop(context);
                                  }
                                },
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                            final value = textController.text;
                                    if (value.isNotEmpty) {
                                      _updateUsername(value);
                                      Navigator.pop(context);
                                    }
                                  },
                                  child: const Text('Save'),
                                ),
                              ],
                                    );
                                  },
                          );
                        },
                      ),
                    ],
                  ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildInfoCard(Icons.email, 'Email', _user?.email ?? 'N/A'),
                  _buildInfoCard(Icons.phone, 'Mobile', _phoneController.text.isNotEmpty ? _phoneController.text : 'N/A'),
                  _buildSocialCard(FontAwesomeIcons.twitter, 'Twitter', _twitterController.text.isNotEmpty ? _twitterController.text : 'Add Twitter link', () {
                    if (_twitterController.text.isNotEmpty) {
                      _launchURL(_twitterController.text);
                    } else {
                      _showEditDialog('Twitter', _twitterController, 'twitter');
                    }
                  }),
                  _buildSocialCard(FontAwesomeIcons.facebook, 'Facebook', _facebookController.text.isNotEmpty ? _facebookController.text : 'Add Facebook link', () {
                    if (_facebookController.text.isNotEmpty) {
                      _launchURL(_facebookController.text);
                    } else {
                      _showEditDialog('Facebook', _facebookController, 'facebook');
                    }
                  }),
                  const SizedBox(height: 20),
                  _buildLogoutCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, color: Colors.deepPurple),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialCard(IconData icon, String title, String subtitle, VoidCallback onTap) {
    final hasLink = subtitle != 'Add Twitter link' && subtitle != 'Add Facebook link';
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue),
            const SizedBox(width: 15),
            Expanded(
              child: InkWell(
                onTap: onTap,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: hasLink ? Colors.blue : Colors.grey[600],
                        decoration: hasLink ? TextDecoration.underline : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            if (hasLink)
              IconButton(
                icon: Icon(Icons.edit, color: Colors.grey, size: 20),
                onPressed: () {
                  if (title == 'Twitter') {
                    _showEditDialog('Twitter', _twitterController, 'twitter');
                  } else if (title == 'Facebook') {
                    _showEditDialog('Facebook', _facebookController, 'facebook');
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutCard() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: _logout,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              const SizedBox(width: 15),
              Text(
                'Logout',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      _logger.e('Could not launch $uri');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot open link: $url'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      _logger.e('Error during logout', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error during logout'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
} 