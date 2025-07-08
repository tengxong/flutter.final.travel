import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import GoogleFonts
import 'dart:convert';
import 'package:http/http.dart' as http;

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

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCountry;
  String? _selectedCategory;

  List<Place> places = [];
  List<Place> filteredPlaces = [];
  bool isLoading = true;
  String? errorMessage;

  Set<String> countries = {'All Countries'};
  Set<String> categories = {'All Categories'};

  @override
  void initState() {
    super.initState();
    fetchPlaces();
  }

  Future<void> fetchPlaces() async {
    const url = 'https://raw.githubusercontent.com/tengxong/flutter.1/main/travelling.json';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          setState(() {
            places = data.map((e) => Place.fromJson(e)).toList();
            filteredPlaces = places;
            
            // Extract unique countries and categories
            for (var place in places) {
              countries.add(place.country);
              if (place.category.isNotEmpty) {
                categories.add(place.category);
              }
            }
            
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
            errorMessage = 'No places found in JSON.';
          });
        }
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to load places (status ${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load places: $e';
      });
    }
  }

  void _filterPlaces() {
    setState(() {
      filteredPlaces = places.where((place) {
        bool matchesSearch = _searchController.text.isEmpty ||
            place.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            place.description.toLowerCase().contains(_searchController.text.toLowerCase());
        
        bool matchesCountry = _selectedCountry == null || 
            _selectedCountry == 'All Countries' || 
            place.country == _selectedCountry;
        
        bool matchesCategory = _selectedCategory == null || 
            _selectedCategory == 'All Categories' || 
            place.category == _selectedCategory;
        
        return matchesSearch && matchesCountry && matchesCategory;
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white, // White background
        elevation: 0, // No shadow
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.grey), // Back arrow
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search',
              hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {}); // To refresh the suffix icon
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            ),
            onChanged: (value) {
              setState(() {}); // To show/hide clear button
              _filterPlaces();
            },
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      value: _selectedCountry ?? 'All Countries',
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCountry = newValue;
                        });
                        _filterPlaces();
                      },
                      items: countries.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: GoogleFonts.poppins(color: Colors.black)),
                        );
                      }).toList(),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      isExpanded: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      value: _selectedCategory ?? 'All Categories',
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCategory = newValue;
                        });
                        _filterPlaces();
                      },
                      items: categories.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: GoogleFonts.poppins(color: Colors.black)),
                        );
                      }).toList(),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      isExpanded: true,
                    ),
                  ),
                ],
              ),
            ),
            // List of search results
            isLoading
                ? const CircularProgressIndicator()
                : errorMessage != null
                    ? Text(errorMessage!, style: GoogleFonts.poppins(color: Colors.red))
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredPlaces.length,
                                                 itemBuilder: (context, index) {
                           final item = filteredPlaces[index];
                           return _buildSearchResultCard(
                             item.name,
                             '${item.country} - ${item.city}',
                             item.image,
                           );
                         },
                      ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultCard(String title, String subtitle, String imagePath) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(26),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                imagePath,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[300],
                  child: const Icon(Icons.error, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.bookmark_border, color: Colors.grey),
              onPressed: () {
                // Handle bookmark
              },
            ),
          ],
        ),
      ),
    );
  }
}