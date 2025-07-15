import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
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
    );
  }
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  List<Place> allPlaces = [];
  Set<int> bookmarkedPlaceIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() { _isLoading = true; });
    }
    await loadBookmarks();
    await fetchPlaces();
    if (mounted) {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('bookmarked_place_ids') ?? [];
    if (mounted) {
      setState(() {
        bookmarkedPlaceIds = ids.map((e) => int.tryParse(e)).whereType<int>().toSet();
      });
    }
  }

  Future<void> fetchPlaces() async {
    const url = 'https://raw.githubusercontent.com/tengxong/flutter.1/main/travelling.json';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          if (mounted) {
            setState(() {
              allPlaces = data.map((e) => Place.fromJson(e)).toList();
            });
          }
        }
      }
    } catch (e) {
      // Handle error silently or log it
    }
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

  @override
  Widget build(BuildContext context) {
    final bookmarkedPlaces = allPlaces.where((p) => bookmarkedPlaceIds.contains(p.id)).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Save',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : bookmarkedPlaces.isEmpty
              ? Center(
                  child: Text(
                    'No bookmarks yet!',
                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: bookmarkedPlaces.length,
                  itemBuilder: (context, index) {
                    final place = bookmarkedPlaces[index];
                    return _buildPlaceCard(place);
                  },
                ),
    );
  }

  Widget _buildPlaceCard(Place place) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              place.image,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, size: 80),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    place.country,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: Icon(
                bookmarkedPlaceIds.contains(place.id) ? Icons.bookmark : Icons.bookmark_border,
                color: bookmarkedPlaceIds.contains(place.id) ? Colors.yellow : Colors.orange,
              ),
              onPressed: () async {
                await toggleBookmark(place);
                setState(() {});
              },
            ),
          ),
        ],
      ),
    );
  }
} 