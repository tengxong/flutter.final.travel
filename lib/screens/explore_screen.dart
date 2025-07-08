import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';

class ExploreScreen extends StatefulWidget {
  final String initialLocation;

  const ExploreScreen({
    super.key,
    this.initialLocation = '',
  });

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _logger = Logger();
  final MapController _mapController = MapController();
  final List<Marker> _markers = [];
  final LatLng _center = LatLng(13.7563, 100.5018); // Bangkok coordinates
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setInitialMarker();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _setInitialMarker() {
    LatLng? destination;
    switch (widget.initialLocation.toLowerCase()) {
      case 'vang vieng':
        destination = LatLng(18.9333, 102.4500);
        break;
      case 'vientiane':
        destination = LatLng(17.9757, 102.6331);
        break;
      default:
        destination = _center;
    }
    _markers.add(
      Marker(
        width: 40,
        height: 40,
        point: destination,
        child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
      ),
    );
  }

  Future<void> _searchPlace(String place) async {
    if (place.isEmpty) return;
    final apiKey = 'AIzaSyDFmTBhjFnRyWPVBk3t8X0BKVi_IVcu_8E';
    final url = 'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(place)}&key=$apiKey';
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final location = data['results'][0]['geometry']['location'];
        final latLng = LatLng(location['lat'], location['lng']);
        setState(() {
          _markers.add(
            Marker(
              width: 40,
              height: 40,
              point: latLng,
              child: const Icon(Icons.location_pin, color: Colors.blue, size: 40),
            ),
          );
        });
        _mapController.move(latLng, 15.0);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Place not found')),
        );
      }
    } catch (e) {
      _logger.e('Error searching place', error: e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error searching place')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.initialLocation,
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 11.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: ['a', 'b', 'c'],
              ),
              MarkerLayer(markers: _markers),
            ],
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(30),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search for a place...',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
                onSubmitted: (value) {
                  _searchPlace(value);
                },
              ),
            ),
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
} 