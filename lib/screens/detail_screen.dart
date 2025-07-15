import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_travel/screens/explore_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DetailScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String description;
  final String mainImage;
  final List<String> moreImages;
  final String location;
  final double latitude;
  final double longitude;

  const DetailScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.mainImage,
    required this.moreImages,
    required this.location,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  // เพิ่มฟังก์ชันตรวจสอบประเทศ (ลาว ไทย เวียดนาม)
  bool _isInAnyTargetCountry(double lat, double lng) {
    // Laos
    if (lat >= 13 && lat <= 23 && lng >= 100 && lng <= 108) {
      return true;
    }
    // Thailand
    if (lat >= 5 && lat <= 21 && lng >= 97 && lng <= 106) {
      return true;
    }
    // Vietnam
    if (lat >= 8 && lat <= 24 && lng >= 102 && lng <= 110) {
      return true;
    }
    return false;
  }

  Future<void> _handleSeeRoute(String placeName) async {
    double lat = widget.latitude;
    double lng = widget.longitude;

    if (lat == 0.0 && lng == 0.0) {
      // เรียก Geocoding API
      final apiKey = 'sXBuKP6NFqwrfimhH5OZ'; // ใช้ MapTiler API Key เดิม
      final url = 'https://api.maptiler.com/geocoding/${Uri.encodeComponent(placeName)}.json?key=$apiKey&country=LA,TH,VN';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['features'] != null && data['features'].isNotEmpty) {
          final coords = data['features'][0]['geometry']['coordinates'];
          lat = coords[1];
          lng = coords[0];
        }
      }
    }

    if (lat == 0.0 && lng == 0.0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not available')),
      );
      return;
    }

    // ตรวจสอบประเทศก่อนเปิด ExploreScreen (ลาว ไทย เวียดนาม)
    if (!_isInAnyTargetCountry(lat, lng)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ปลายทางอยู่นอกประเทศที่รองรับ (ลาว ไทย เวียดนาม)')),
      );
      return;
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExploreScreen(
          initialLatLng: LatLng(lat, lng),
          initialLocation: placeName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250.0,
            flexibleSpace: FlexibleSpaceBar(
              background: widget.mainImage.startsWith('http')
                  ? Image.network(
                      widget.mainImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, size: 80)),
                    )
                  : Image.asset(
                      widget.mainImage,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.broken_image, size: 80)),
                    ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white), // Back arrow
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.bookmark_border, color: Colors.white), // Bookmark icon
                onPressed: () {
                  // Handle bookmark
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.description,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _handleSeeRoute(widget.title),
                    icon: const Icon(Icons.directions),
                    label: const Text('see the route'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (widget.latitude == 0.0 && widget.longitude == 0.0) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(content: Text('Location not available')),
                        );
                        return;
                      }
                      final url = 'https://www.google.com/maps/search/?api=1&query=${widget.latitude},${widget.longitude}';
                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                      } else {
                        if (!mounted) return;
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(content: Text('Could not open Google Maps')),
                        );
                      }
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('see Maps'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'More picture',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 100, // Height for horizontal image list
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.moreImages.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(right: 10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              widget.moreImages[index],
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  // You can add more sections here based on the design,
                  // e.g., reviews, facilities, etc.
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 