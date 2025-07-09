import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:geolocator/geolocator.dart';

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
  List<LatLng> _routePoints = [];

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
        child: GestureDetector(
          onTap: () => _drawRoute(destination!),
          child: const Icon(Icons.location_pin, color: Colors.red, size: 40),
        ),
      ),
    );
  }

  Future<void> _drawRoute(LatLng destination) async {
    setState(() => _isLoading = true);
    try {
      // 1. Get current location
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      LatLng origin = LatLng(position.latitude, position.longitude);

      // 2. Call Google Directions API
      final apiKey = 'AIzaSyBGsxnpdnxwSCeUISpv3nbJK7CvaK6JGXw'; // ใส่ API Key จริงของคุณที่นี่
      final url =
          'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$apiKey';

      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        final points = data['routes'][0]['overview_polyline']['points'];
        _routePoints = _decodePolyline(points);
        setState(() {});
        // ขยับแผนที่ไปยังปลายทาง
        _mapController.move(destination, 13.0);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Route not found')),
        );
      }
    } catch (e) {
      _logger.e('Error drawing route', error: e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error drawing route')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<LatLng> _decodePolyline(String polyline) {
    List<LatLng> points = [];
    int index = 0, len = polyline.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
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
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: Colors.blue,
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
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
  
  Future<void> _searchPlace(String place) async {
    if (place.isEmpty) return;
    final apiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
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
              child: GestureDetector(
                onTap: () => _drawRoute(latLng),
                child: const Icon(Icons.location_pin, color: Colors.blue, size: 40),
              ),
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
} 