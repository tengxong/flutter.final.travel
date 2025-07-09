import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import GoogleFonts
import 'package:app_travel/screens/search_screen.dart'; // Import SearchScreen
import 'package:app_travel/screens/notification_screen.dart'; // Import NotificationScreen
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_travel/screens/detail_screen.dart'; // Import DetailScreen

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class Place {
  final int id;
  final String name;
  final String country;
  final String description;
  final String image;
  final String street;
  final String city;
  final String phone;
  final String category;
  final double latitude;
  final double longitude;

  Place({
    required this.id,
    required this.name,
    required this.country,
    required this.description,
    required this.image,
    required this.street,
    required this.city,
    required this.phone,
    required this.category,
    required this.latitude,
    required this.longitude,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'],
      name: json['name'],
      country: json['country'],
      description: json['description'],
      image: json['image'],
      street: json['address']['street'],
      city: json['address']['city'],
      phone: json['phone'],
      category: json['category'] ?? '',
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
    );
  }
}

class _HomePageState extends State<HomePage> {
  // Cache GoogleFonts styles
  late final TextStyle _titleStyle = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );
  late final TextStyle _subtitleStyle = GoogleFonts.poppins(
    fontSize: 14,
    color: Colors.blueAccent,
  );

  List<Place> githubImages = [];
  bool isLoadingImages = true;
  String? errorMessage;

  List<Place> places = [];
  bool isLoadingPlaces = true;
  String? errorPlaces;

  List<Place> history = [];
  String? currentUserEmail;

  Set<int> bookmarkedPlaceIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precacheAllImages(context);
    });
    fetchGithubImages();
    fetchPlaces();
    _loadCurrentUserEmailAndHistory();
    loadBookmarks();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email != currentUserEmail) {
      currentUserEmail = user?.email;
      if (currentUserEmail != null) {
        loadHistory(currentUserEmail!);
      } else {
        setState(() { history = []; });
      }
    }
  }

  void _precacheAllImages(BuildContext context) {
    // Images in Show post section
    precacheImage(const AssetImage('assets/images/Loas-Guide.png'), context);
    precacheImage(const AssetImage('assets/images/Vang-Vieng-Laos-.jpg'), context);
    precacheImage(const AssetImage('assets/images/Patuxay-vientiane-laos.jpg'), context);

    // Images in Popular Destination section
    precacheImage(const AssetImage('assets/images/laos-rice-field1.jpg'), context);
    precacheImage(const AssetImage('assets/images/Lao-Tourism-.jpg'), context);

    // Images in Explore section (already covered by Popular Destination)
  }

  Future<void> fetchGithubImages() async {
    const url = 'https://raw.githubusercontent.com/tengxong/flutter.1/main/travelling.json';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // If the JSON is a map with 'images', use it for images section
        if (data is Map && data.containsKey('images')) {
          setState(() {
            githubImages = List<Place>.from(data['images'].map((e) => Place.fromJson(e)));
            isLoadingImages = false;
          });
        } else {
          setState(() {
            isLoadingImages = false;
            errorMessage = 'No images found in JSON.';
          });
        }
      } else {
        setState(() {
          isLoadingImages = false;
          errorMessage = 'Failed to load images (status ${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        isLoadingImages = false;
        errorMessage = 'Failed to load images: $e';
      });
    }
  }

  Future<void> fetchPlaces() async {
    const url = 'https://raw.githubusercontent.com/tengxong/flutter.1/main/travelling.json';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // If the JSON is a list of places
        if (data is List) {
          setState(() {
            places = data.map((e) => Place.fromJson(e)).toList();
            isLoadingPlaces = false;
          });
        } else {
          setState(() {
            isLoadingPlaces = false;
            errorPlaces = 'No places found in JSON.';
          });
        }
      } else {
        setState(() {
          isLoadingPlaces = false;
          errorPlaces = 'Failed to load places (status ${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        isLoadingPlaces = false;
        errorPlaces = 'Failed to load places: $e';
      });
    }
  }

  Future<void> _loadCurrentUserEmailAndHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      currentUserEmail = user?.email;
    });
    if (currentUserEmail != null) {
      await loadHistory(currentUserEmail!);
    }
  }

  Future<void> loadHistory(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'history_$email';
    final historyJson = prefs.getString(key);
    if (historyJson != null) {
      final List<dynamic> decoded = json.decode(historyJson);
      setState(() {
        history = decoded.map((e) => Place.fromJson(e)).toList();
      });
    } else {
      setState(() {
        history = [];
      });
    }
  }

  Future<void> saveHistory(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'history_$email';
    final historyJson = json.encode(history.map((e) => {
      'id': e.id,
      'name': e.name,
      'country': e.country,
      'description': e.description,
      'image': e.image,
      'address': {
        'street': e.street,
        'city': e.city,
      },
      'phone': e.phone,
      'category': e.category,
    }).toList());
    await prefs.setString(key, historyJson);
  }

  Future<void> loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('bookmarked_place_ids') ?? [];
    setState(() {
      bookmarkedPlaceIds = ids.map((e) => int.tryParse(e)).whereType<int>().toSet();
    });
  }

  Future<void> toggleBookmark(Place place) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (bookmarkedPlaceIds.contains(place.id)) {
        bookmarkedPlaceIds.remove(place.id);
      } else {
        bookmarkedPlaceIds.add(place.id);
      }
    });
    await prefs.setStringList('bookmarked_place_ids', bookmarkedPlaceIds.map((e) => e.toString()).toList());
  }

  bool isBookmarked(Place place) {
    return bookmarkedPlaceIds.contains(place.id);
  }

  void _showPlaceDetail(Place place) async {
    setState(() {
      history.removeWhere((p) => p.id == place.id);
      history.insert(0, place);
    });
    if (currentUserEmail != null) {
      await saveHistory(currentUserEmail!);
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailScreen(
          title: place.name,
          subtitle: place.country,
          description: place.description,
          mainImage: place.image,
          moreImages: const [],
          location: '${place.street}, ${place.city}',
          latitude: place.latitude,
          longitude: place.longitude,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('APP Travelling', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color.fromARGB(255, 71, 164, 211))),
        actions: [
          SizedBox(
            child: InkWell(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchScreen()),
                );
                if (result != null && result is Place) {
                  setState(() {
                    history.removeWhere((p) => p.id == result.id);
                    history.insert(0, result);
                  });
                  if (currentUserEmail != null) {
                    await saveHistory(currentUserEmail!);
                  }
                }
              },
              child: const Icon(Icons.search),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.grey),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ประวัติการเข้าชม
            if (history.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('History', style: _titleStyle),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          final h = history[index];
                          return GestureDetector(
                            onTap: () => _showPlaceDetail(h),
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              child: Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(h.image, width: 100, height: 100, fit: BoxFit.cover),
                                  ),
                                  Text(h.name, style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('Traveling', style: _titleStyle),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: isLoadingPlaces
                  ? const Center(child: CircularProgressIndicator())
                  : errorPlaces != null
                      ? Center(child: Text(errorPlaces!, style: TextStyle(color: Colors.red)))
                      : Column(
                          children: places.map((place) => GestureDetector(
                            onTap: () => _showPlaceDetail(place),
                            child: Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      place.image,
                                      width: 180,
                                      height: 180,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, size: 120),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(place.name, style: _titleStyle),
                                          Text(place.country, style: _subtitleStyle),
                                          const SizedBox(height: 4),
                                          Text(place.description, maxLines: 6, overflow: TextOverflow.ellipsis),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )).toList(),
                        ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}