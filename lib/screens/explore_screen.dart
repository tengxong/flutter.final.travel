import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:logger/logger.dart';
import 'package:geolocator/geolocator.dart';

class ExploreScreen extends StatefulWidget {
  final String initialLocation;
  final String initialCountry;
  final LatLng? initialLatLng;

  const ExploreScreen({
    super.key,
    this.initialLocation = '',
    this.initialCountry = 'laos',
    this.initialLatLng,
  });

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _logger = Logger();
  final MapController _mapController = MapController();
  final List<Marker> _markers = [];
  final LatLng _center = LatLng(17.9757, 102.6331); 
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  List<LatLng> _routePoints = [];

  final String _maptilerApiKey = 'sXBuKP6NFqwrfimhH5OZ';
  List<dynamic> _suggestions = [];
  bool _showSuggestions = false;

  bool _followUser = true;
  LatLng? _currentLocation;
  Stream<Position>? _positionStream;
  StreamSubscription<Position>? _positionSubscription;

  String _mapStyle = 'streets';
  final List<Map<String, dynamic>> _mapStyles = [
    {'key': 'streets', 'name': 'Streets', 'icon': Icons.streetview},
    {'key': 'hybrid', 'name': 'Hybrid', 'icon': Icons.satellite},
    {'key': 'basic', 'name': 'Basic', 'icon': Icons.map},
    {'key': 'topo', 'name': 'Topo', 'icon': Icons.terrain},
    {'key': 'toner', 'name': 'Toner', 'icon': Icons.grain},
    {'key': 'outdoor', 'name': 'Outdoor', 'icon': Icons.landscape},
  ];

  @override
  void initState() {
    super.initState();
    _setInitialMarker();
    _initCurrentLocation();
    _startPositionStream();

    if (widget.initialLatLng != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _drawRoute(widget.initialLatLng!);
      });
    } else if (widget.initialLocation.isNotEmpty) {
      // Auto geocode and draw route
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final latLng = await _geocodePlace(widget.initialLocation, widget.initialCountry);
        if (latLng != null) {
          _drawRoute(latLng);
        } // ถ้า null ไม่ต้องวาดเส้นทางหรือเส้นตรง
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _positionSubscription?.cancel();
    super.dispose();
  }

  void _setInitialMarker() {
    LatLng? destination = widget.initialLatLng;
    if (destination == null) {
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
    }
    // ป้องกัน marker ที่ (0,0)
    if (destination.latitude == 0.0 && destination.longitude == 0.0) {
      if (!mounted) return;
      _logger.e('Prevented marker at (0,0)');
      return;
    }
    _logger.i('Set initial marker at: $destination');
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
    // Move map to destination if provided
    if (widget.initialLatLng != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(destination!, 15.0);
      });
    }
  }

  Future<void> _drawRoute(LatLng destination) async {
    _logger.i('>>> _drawRoute called with destination: $destination');
    if (destination.latitude == 0.0 && destination.longitude == 0.0) {
      if (!mounted) return;
      _logger.e('Destination is (0,0)!');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Destination location is invalid')),
      );
      return;
    }
    // ตรวจสอบว่าปลายทางอยู่ในประเทศที่รองรับหรือไม่ (ลาว ไทย เวียดนาม)
    if (!_isInAnyTargetCountry(destination)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ปลายทางอยู่นอกประเทศที่รองรับ (ลาว ไทย เวียดนาม)')),
      );
      setState(() => _isLoading = false);
      return;
    }
    setState(() {
      _isLoading = true;
      _routePoints = [];
    });
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      LatLng origin = LatLng(position.latitude, position.longitude);
      _logger.i('Origin: $origin');
      _logger.i('Destination: $destination');
      // เช็ค origin หรือ destination ผิด
      if ((origin.latitude == 0.0 && origin.longitude == 0.0) ||
          (destination.latitude == 0.0 && destination.longitude == 0.0)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ตำแหน่งต้นทางหรือปลายทางไม่ถูกต้อง')),
        );
        setState(() => _isLoading = false);
        return;
      }
      // ตรวจสอบ origin ว่าอยู่ในประเทศที่รองรับหรือไม่ (ลาว ไทย เวียดนาม)
      if (!_isInAnyTargetCountry(origin)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ตำแหน่งปัจจุบันอยู่นอกประเทศที่รองรับ (ลาว ไทย เวียดนาม)')),
        );
        setState(() => _isLoading = false);
        return;
      }

      // เช็ค origin/destination ว่าอยู่ในประเทศที่รองรับ
      if (!_isInAnyTargetCountry(origin) || !_isInAnyTargetCountry(destination)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ต้นทางหรือปลายทางอยู่นอกประเทศที่รองรับ (ลาว ไทย เวียดนาม)')),
        );
        setState(() => _isLoading = false);
        return;
      }

      // 1. พยายามใช้ MapTiler Routing ก่อน
      final url =
        'https://api.maptiler.com/routing/route/v2/driving/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}?key=$_maptilerApiKey&overview=full&geometries=polyline6';

      final response = await http.get(Uri.parse(url));
      _logger.i('MapTiler response: ${response.body}');
      bool foundRoute = false;
      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          if (data['routes'] != null && data['routes'].isNotEmpty) {
            final points = data['routes'][0]['geometry'];
            _routePoints = decodePolyline6(points);
            _logger.i('Decoded polyline points (MapTiler): $_routePoints');
            setState(() {});
            _mapController.move(destination, 13.0);
            foundRoute = true;
          }
        } catch (e) {
          _logger.e('Error parsing MapTiler route response', error: e);
        }
      }

      // 2. ถ้าไม่พบเส้นทางใน MapTiler ให้ fallback ไป ORS
      if (!foundRoute) {
        final orsApiKey = 'eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6IjdlMDFjMjkyMzlkMzRiMjY5ZDViOWIxZWFmNjkyYzdmIiwiaCI6Im11cm11cjY0In0=';
        final orsUrl =
          'https://api.openrouteservice.org/v2/directions/driving-car?api_key=$orsApiKey&start=${origin.longitude},${origin.latitude}&end=${destination.longitude},${destination.latitude}&geometry_format=geojson';
        final orsResponse = await http.get(Uri.parse(orsUrl));
        _logger.i('ORS response: ${orsResponse.body}');
        if (orsResponse.statusCode == 200) {
          try {
            final orsData = json.decode(orsResponse.body);
            if (orsData['features'] != null && orsData['features'].isNotEmpty) {
              final coords = orsData['features'][0]['geometry']['coordinates'];
              _routePoints = coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
              _logger.i('Decoded polyline points (ORS): $_routePoints');
              setState(() {});
              _mapController.move(destination, 13.0);
              foundRoute = true;
            }
          } catch (e) {
            _logger.e('Error parsing ORS route response', error: e);
          }
        } else {
          _logger.e('ORS Routing API error: ${orsResponse.body}');
        }
      }

      if (!foundRoute) {
        // ไม่ต้องวาดเส้นตรงระหว่าง origin กับ destination
        setState(() {
          _routePoints = [];
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Route not found')),
        );
        return;
      }
    } catch (e) {
      _logger.e('Error drawing route', error: e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error drawing route')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
      _logger.i('Polyline points: $_routePoints');
    }
  }

  List<LatLng> decodePolyline6(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;
      poly.add(LatLng(lat / 1E6, lng / 1E6));
    }
    return poly;
  }

  Future<void> _initCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
        _logger.i('initCurrentLocation: ${_currentLocation?.latitude},${_currentLocation?.longitude}');
        _mapController.move(_currentLocation!, 16.0);
      }
    } catch (e) {
      _logger.e('Error getting current location', error: e);
    }
  }

  void _startPositionStream() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
    );
    _positionSubscription = _positionStream!.listen((Position position) {
      if (mounted) {
        final LatLng newLocation = LatLng(position.latitude, position.longitude);
        setState(() {
          _currentLocation = newLocation;
        });
        _logger.i('positionStream: ${_currentLocation?.latitude},${_currentLocation?.longitude}');
        if (_followUser) {
          _mapController.move(newLocation, _mapController.camera.zoom);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'location',
          style: GoogleFonts.poppins(
            color: Colors.lightBlueAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation ?? _center,
              initialZoom: 11.0,
              onPositionChanged: (pos, hasGesture) {
                if (_followUser && _currentLocation != null) {
                  _mapController.move(_currentLocation!, _mapController.camera.zoom);
                }
              },
            ),
            children: [
              TileLayer(
                tileSize: 256,
                urlTemplate: _mapStyle == 'streets'
                  ? 'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=$_maptilerApiKey'
                  : _mapStyle == 'hybrid'
                    ? 'https://api.maptiler.com/maps/hybrid/{z}/{x}/{y}.jpg?key=$_maptilerApiKey'
                    : _mapStyle == 'basic'
                      ? 'https://api.maptiler.com/maps/basic/{z}/{x}/{y}.png?key=$_maptilerApiKey'
                      : _mapStyle == 'topo'
                        ? 'https://api.maptiler.com/maps/topo/{z}/{x}/{y}.png?key=$_maptilerApiKey'
                        : _mapStyle == 'toner'
                          ? 'https://api.maptiler.com/maps/toner/{z}/{x}/{y}.png?key=$_maptilerApiKey'
                          : _mapStyle == 'outdoor'
                            ? 'https://api.maptiler.com/maps/outdoor/{z}/{x}/{y}.png?key=$_maptilerApiKey'
                            : 'https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=$_maptilerApiKey',
                userAgentPackageName: 'com.example.app_travel',
              ),
              MarkerLayer(markers: [
                ..._markers,
              ]),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: Colors.blueAccent,
                      strokeWidth: 5.0,
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
              elevation: 4,
              borderRadius: BorderRadius.circular(30),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search for a place...',
                  prefixIcon: Icon(Icons.search, color: Colors.blueAccent),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  filled: true,
                  fillColor: Colors.white.withAlpha((0.95 * 255).toInt()),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    _fetchPlaceSuggestions(value);
                  } else {
                    setState(() => _showSuggestions = false);
                  }
                },
                onTap: () {
                  setState(() {
                    _showSuggestions = _searchController.text.isNotEmpty;
                  });
                },
                onSubmitted: (value) {
                  setState(() {
                    _showSuggestions = false;
                  });
                  _searchPlace(value);
                },
              ),
            ),
          ),
          if (_showSuggestions && _suggestions.isNotEmpty)
            Positioned(
              top: 70,
              left: 16,
              right: 16,
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(10),
                child: ListView(
                  shrinkWrap: true,
                  children: _suggestions.map((feature) => ListTile(
                    title: Text(feature['place_name'] ?? ''),
                    onTap: () async {
                      _searchController.text = feature['place_name'] ?? '';
                      setState(() {
                        _showSuggestions = false;
                      });
                      final coords = feature['geometry']['coordinates'];
                      final latLng = LatLng(coords[1], coords[0]);
                      final placeName = feature['place_name'] ?? '';
                      setState(() {
                        _markers.add(
                          Marker(
                            width: 140,
                            height: 60,
                            point: latLng,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.location_pin, color: Colors.blue, size: 40),
                                Container(
                                  color: Colors.white.withAlpha((0.85 * 255).toInt()),
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  child: Text(
                                    placeName,
                                    style: TextStyle(fontSize: 12, color: Colors.black),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      });
                      _mapController.move(latLng, 15.0);
                    },
                  )).toList(),
                ),
              ),
            ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
          Positioned(
            bottom: 170,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'zoomIn',
                  mini: true,
                  backgroundColor: Colors.white,
                  shape: CircleBorder(),
                  elevation: 6,
                  onPressed: () {
                    _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
                  },
                  child: const Icon(Icons.add, color: Colors.black),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'zoomOut',
                  mini: true,
                  backgroundColor: Colors.white,
                  shape: CircleBorder(),
                  elevation: 6,
                  onPressed: () {
                    _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
                  },
                  child: const Icon(Icons.remove, color: Colors.black),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'toggleFollow',
                  mini: true,
                  backgroundColor: _followUser ? Colors.blue : Colors.grey,
                  shape: CircleBorder(),
                  elevation: 6,
                  onPressed: () {
                    setState(() {
                      _followUser = !_followUser;
                    });
                  },
                  child: Icon(_followUser ? Icons.gps_fixed : Icons.gps_not_fixed, color: Colors.white),
                ),
              ],
            ),
          ),
          Positioned(
            top: 80,
            right: 16,
            child: DropdownButtonHideUnderline(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((0.95 * 255).toInt()),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: DropdownButton<String>(
                  value: _mapStyle,
                  items: _mapStyles.map<DropdownMenuItem<String>>((style) => DropdownMenuItem<String>(
                    value: style['key'] as String,
                    child: Row(
                      children: [
                        Icon(style['icon'] as IconData, size: 20),
                        const SizedBox(width: 8),
                        Text(style['name'] as String),
                      ],
                    ),
                  )).toList(),
                  onChanged: (value) {
                    setState(() {
                      _mapStyle = value!;
                    });
                  },
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchPlaceSuggestions(String input) async {
    final url = 'https://api.maptiler.com/geocoding/${Uri.encodeComponent(input)}.json?key=$_maptilerApiKey&country=LA,TH,VN';
    try {
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);
      setState(() {
        _suggestions = data['features'];
        _showSuggestions = true;
      });
    } catch (e) {
      _logger.e('Error fetching suggestions', error: e);
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
    }
  }

  Future<void> _searchPlace(String place) async {
    if (place.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final url = 'https://api.maptiler.com/geocoding/${Uri.encodeComponent(place)}.json?key=$_maptilerApiKey&country=LA,TH,VN';
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);
      if (data['features'] != null && data['features'].isNotEmpty) {
        final coords = data['features'][0]['geometry']['coordinates'];
        final latLng = LatLng(coords[1], coords[0]);
        final placeName = data['features'][0]['place_name'] ?? '';
        setState(() {
          _markers.add(
            Marker(
              width: 140,
              height: 60,
              point: latLng,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_pin, color: Colors.blue, size: 40),
                  Container(
                    color: Colors.white.withAlpha((0.85 * 255).toInt()),
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      placeName,
                      style: TextStyle(fontSize: 12, color: Colors.black),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        });
        _mapController.move(latLng, 15.0);
        _logger.i('Search result coordinates: $latLng');
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

  Future<LatLng?> _geocodePlace(String place, String country) async {
    final placeQuery = '$place, $country';
    final url = 'https://api.maptiler.com/geocoding/${Uri.encodeComponent(placeQuery)}.json?key=$_maptilerApiKey&country=LA,TH,VN';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['features'] != null && data['features'].isNotEmpty) {
        final coords = data['features'][0]['geometry']['coordinates'];
        final latLng = LatLng(coords[1], coords[0]);
        if (_isInTargetCountries(latLng, country)) {
          return latLng;
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ไม่พบพิกัดที่ถูกต้องในประเทศที่เลือก')),
            );
          }
          return null;
        }
      }
    }
    return null;
  }

  bool _isInTargetCountries(LatLng latLng, String country) {
    final c = country.toLowerCase();
    if (c == 'laos') {
      return latLng.latitude >= 13 && latLng.latitude <= 23 && latLng.longitude >= 100 && latLng.longitude <= 108;
    }
    if (c == 'thailand') {
      return latLng.latitude >= 5 && latLng.latitude <= 21 && latLng.longitude >= 97 && latLng.longitude <= 106;
    }
    if (c == 'vietnam') {
      return latLng.latitude >= 8 && latLng.latitude <= 24 && latLng.longitude >= 102 && latLng.longitude <= 110;
    }
    return false;
  }

  bool _isInAnyTargetCountry(LatLng latLng) {
    // Laos
    if (latLng.latitude >= 13 && latLng.latitude <= 23 && latLng.longitude >= 100 && latLng.longitude <= 108) {
      return true;
    }
    // Thailand
    if (latLng.latitude >= 5 && latLng.latitude <= 21 && latLng.longitude >= 97 && latLng.longitude <= 106) {
      return true;
    }
    // Vietnam
    if (latLng.latitude >= 8 && latLng.latitude <= 24 && latLng.longitude >= 102 && latLng.longitude <= 110) {
      return true;
    }
    return false;
  }
} 
