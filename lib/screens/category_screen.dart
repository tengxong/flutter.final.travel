import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_travel/screens/bookmark_screen.dart';
import 'package:app_travel/screens/notification_screen.dart';
import 'package:app_travel/screens/search_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
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

class _CategoryScreenState extends State<CategoryScreen> {
  String? _selectedCountry;
  final List<String> _countries = ['Country', 'Laos', 'Thailand', 'Vietnam'];
  String? _selectedCategory;
  final List<String> _categories = [
    'Hotel',
    'River',
    'Mountain',
    'Lake',
    'City'
  ];

  List<Place> places = [];
  bool isLoadingPlaces = true;
  String? errorPlaces;
  Set<int> bookmarkedPlaceIds = {};

  @override
  void initState() {
    super.initState();
    _selectedCountry = _countries[0];
    fetchPlaces();
    loadBookmarks();
  }

  Future<void> fetchPlaces() async {
    const url =
        'https://raw.githubusercontent.com/tengxong/flutter.1/main/travelling.json';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          if (mounted) {
            setState(() {
              places = data.map((e) => Place.fromJson(e)).toList();
              isLoadingPlaces = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              isLoadingPlaces = false;
              errorPlaces = 'No places found in JSON.';
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            isLoadingPlaces = false;
            errorPlaces = 'Failed to load places (status ${response.statusCode})';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingPlaces = false;
          errorPlaces = 'Failed to load places: $e';
        });
      }
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

  Future<void> toggleBookmark(Place place) async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        if (bookmarkedPlaceIds.contains(place.id)) {
          bookmarkedPlaceIds.remove(place.id);
        } else {
          bookmarkedPlaceIds.add(place.id);
        }
      });
    }
    await prefs.setStringList('bookmarked_place_ids', bookmarkedPlaceIds.map((e) => e.toString()).toList());
  }

  bool isBookmarked(Place place) {
    return bookmarkedPlaceIds.contains(place.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            DropdownButton<String>(
              value: _selectedCountry,
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: Colors.lightBlueAccent),
              underline: const SizedBox(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCountry = newValue;
                });
              },
              items: _countries.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: GoogleFonts.poppins(
                      color: Colors.lightBlueAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
            Text(
              'Category',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.lightBlueAccent,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.bookmark,
                      color: Color.fromARGB(255, 235, 164, 22)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const BookmarkScreen()),
                    );
                  },
                ),
                IconButton(
                  icon:
                      const Icon(Icons.notifications_none, color: Colors.grey),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const NotificationScreen()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SearchScreen()),
                  ),
                  child: const Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: _selectedCategory == category,
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedCategory = selected ? category : null;
                        });
                      },
                      selectedColor: Colors.deepPurple[100],
                      backgroundColor: Colors.grey[200],
                      labelStyle: GoogleFonts.poppins(
                        color: _selectedCategory == category
                            ? Colors.lightBlueAccent
                            : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
            // Section: Places from JSON
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: isLoadingPlaces
                  ? const Center(child: CircularProgressIndicator())
                  : errorPlaces != null
                      ? Center(
                          child: Text(errorPlaces!,
                              style: TextStyle(color: Colors.orange)))
                      : Column(
                          children: (places.where((place) {
                            if (_selectedCountry != null &&
                                _selectedCountry != 'Country') {
                              if (place.country.toLowerCase() !=
                                  _selectedCountry!.toLowerCase()) {
                                return false;
                              }
                            }
                            if (_selectedCategory != null) {
                              if (place.category.toLowerCase() !=
                                  _selectedCategory!.toLowerCase()) {
                                return false;
                              }
                            }
                            return true;
                          }))
                              .map((place) => Container(
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          child: Image.network(
                                            place.image,
                                            width: double.infinity,
                                            height: 200,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Icon(Icons.error,
                                                        size: 80),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: Icon(
                                                isBookmarked(place)
                                                    ? Icons.bookmark
                                                    : Icons.bookmark_border,
                                                color: isBookmarked(place)
                                                    ? Colors.deepOrange
                                                    : Colors.orange,
                                              ),
                                              onPressed: () =>
                                                  toggleBookmark(place),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.share, color: Colors.blue),
                                              onPressed: () {
                                                Share.share(
                                                    'Check out this place: ${place.name}\n${place.image}');
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
