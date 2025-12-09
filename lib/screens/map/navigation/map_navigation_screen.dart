// lib/screens/map/navigation/map_navigation_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:dlsud_go/widgets/image_gallery_screen.dart';
import 'package:dlsud_go/screens/panorama/panorama_view_screen.dart';
import 'package:dlsud_go/models/campus_location.dart';

// --- MODELS & CONSTANTS ---

class NavigationStep {
  final String instruction;
  final double distance;
  final double duration;
  final double latitude;
  final double longitude;
  final String maneuver;

  NavigationStep({
    required this.instruction,
    required this.distance,
    required this.duration,
    required this.latitude,
    required this.longitude,
    required this.maneuver,
  });

  factory NavigationStep.fromJson(Map<String, dynamic> json) {
    final maneuver = json['maneuver'] as Map<String, dynamic>;
    final location = maneuver['location'] as List<dynamic>;
    return NavigationStep(
      instruction: maneuver['instruction'] ?? 'Continue',
      distance: (json['distance'] as num).toDouble(),
      duration: (json['duration'] as num).toDouble(),
      longitude: (location[0] as num).toDouble(),
      latitude: (location[1] as num).toDouble(),
      maneuver: maneuver['type'] ?? 'straight',
    );
  }
}

class NavigationConstants {
  static const double defaultZoom = 16.0;
  static const double navigationZoom = 18.5;
  static const double navigationPitch = 60.0;
  static const double stepCompletionThreshold = 15.0;
  static const double offRouteThreshold = 25.0;
  static const Color routeColor = Color(0xFF007B3E); // DLSU Green
  static const double defaultLat = 14.3250;
  static const double defaultLng = 120.9580;
}

// Global Annotation Managers
CircleAnnotationManager? circleAnnotationManager;
PointAnnotationManager? pointAnnotationManager;
PolylineAnnotationManager? polylineAnnotationManager;

class MapNavigationScreen extends StatefulWidget {
  const MapNavigationScreen({super.key});

  @override
  State<MapNavigationScreen> createState() => _MapNavigationScreenState();
}

class _MapNavigationScreenState extends State<MapNavigationScreen> with TickerProviderStateMixin {
  MapboxMap? mapboxMap;
  final FlutterTts _flutterTts = FlutterTts();

  final List<CampusLocation> _allLocations = CampusLocation.allLocations;
  CampusLocation? _destination;
  geolocator.Position? _currentPosition;
  
  String _currentLocationLabel = "Detecting Location..."; 

  bool _isCalculatingRoute = false;
  bool _isNavigating = false;
  bool _isRerouting = false;

  double? _routeDistance;
  double? _routeDuration;
  List<NavigationStep> _navigationSteps = [];
  List<Position> _currentRouteLine = [];
  int _currentStepIndex = 0;
  double _distanceToNextStep = 0;

  StreamSubscription<geolocator.Position>? _positionSubscription;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  CampusSection _selectedSection = CampusSection.east; // Default to East

  @override
  void initState() {
    super.initState();
    _initializeUserLocation();
    _initTts();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _searchController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  // --- LOCATION LOGIC ---
  Future<void> _initializeUserLocation() async {
    bool serviceEnabled = await geolocator.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _currentLocationLabel = "Location Off");
      return;
    }

    geolocator.LocationPermission permission = await geolocator.Geolocator.checkPermission();
    if (permission == geolocator.LocationPermission.denied) {
      permission = await geolocator.Geolocator.requestPermission();
      if (permission == geolocator.LocationPermission.denied) {
        if (mounted) setState(() => _currentLocationLabel = "No Permission");
        return;
      }
    }

    if (permission == geolocator.LocationPermission.deniedForever) {
      if (mounted) setState(() => _currentLocationLabel = "No Permission");
      return;
    }

    try {
      geolocator.Position position = await geolocator.Geolocator.getCurrentPosition(
        desiredAccuracy: geolocator.LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      _updateLocationState(position);
    } catch (e) {
      // Fallback
      try {
        final lastKnown = await geolocator.Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          _updateLocationState(lastKnown);
        } else {
          if (mounted) setState(() => _currentLocationLabel = "Location Unavailable");
        }
      } catch (e) {
        if (mounted) setState(() => _currentLocationLabel = "GPS Error");
      }
    }
  }

  void _updateLocationState(geolocator.Position position) {
    if (!mounted) return;
    
    setState(() {
      _currentPosition = position;
    });
    _updateNearestLocationLabel(position);

    mapboxMap?.flyTo(
      CameraOptions(
        center: Point(coordinates: Position(position.longitude, position.latitude)),
        zoom: NavigationConstants.defaultZoom,
        pitch: NavigationConstants.navigationPitch,
      ),
      MapAnimationOptions(duration: 1000)
    );
  }

  void _updateNearestLocationLabel(geolocator.Position position) {
    if (_allLocations.isEmpty) return;
    CampusLocation? nearest;
    double minDistance = double.infinity;

    for (var loc in _allLocations) {
      if (loc.latitude == 0.0 && loc.longitude == 0.0) continue;

      double dist = geolocator.Geolocator.distanceBetween(
          position.latitude, position.longitude, loc.latitude, loc.longitude
      );
      if (dist < minDistance) {
        minDistance = dist;
        nearest = loc;
      }
    }

    String label;
    if (nearest != null && minDistance < 500) {
      label = "Near ${nearest.name}";
    } else {
      label = "Current Location";
    }

    if (mounted && label != _currentLocationLabel) {
      setState(() => _currentLocationLabel = label);
    }
  }

  // --- MAP & ROUTING LOGIC ---

  void _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;
    await _enable3DBuildings();

    circleAnnotationManager = await mapboxMap.annotations.createCircleAnnotationManager();
    pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
    polylineAnnotationManager = await mapboxMap.annotations.createPolylineAnnotationManager();

    await mapboxMap.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        pulsingColor: Colors.blueAccent.value,
      ),
    );

    _loadLocationMarkers();

    try {
      mapboxMap.gestures.addOnMapTapListener((MapContentGestureContext context) {
        _handleMapTap(context.point);
      });
    } catch (e) {
      debugPrint("Gesture listener error: $e");
    }
  }

  Future<void> _enable3DBuildings() async {
    if (mapboxMap == null) return;
    try {
      final style = mapboxMap!.style;
      if (await style.styleLayerExists("3d-buildings")) return;

      var fillExtrusionLayer = FillExtrusionLayer(
        id: "3d-buildings",
        sourceId: "composite",
        sourceLayer: "building",
        minZoom: 15.0,
        fillExtrusionColor: Colors.grey[300]!.value,
        fillExtrusionOpacity: 0.9,
      );

      await style.addLayer(fillExtrusionLayer);
      await style.setStyleLayerProperty("3d-buildings", "fill-extrusion-height", ["get", "height"]);
      await style.setStyleLayerProperty("3d-buildings", "fill-extrusion-base", ["get", "min_height"]);
    } catch (e) {
      debugPrint("3D buildings error: $e");
    }
  }

  Future<void> _loadLocationMarkers() async {
    if (pointAnnotationManager == null || circleAnnotationManager == null) return;
    await pointAnnotationManager!.deleteAll();
    await circleAnnotationManager!.deleteAll();

    for (var location in _allLocations) {
      bool imageLoaded = false;
      if (location.imagePaths.isNotEmpty) {
        Uint8List? imageBytes = await _loadImageAsBytes(location.mainImage);
        if (imageBytes != null) {
          try {
            await pointAnnotationManager!.create(
              PointAnnotationOptions(
                geometry: Point(coordinates: Position(location.longitude, location.latitude)),
                image: imageBytes,
                iconSize: 0.25,
                iconAnchor: IconAnchor.BOTTOM,
              ),
            );
            imageLoaded = true;
          } catch (e) { }
        }
      }
      if (!imageLoaded) {
        await circleAnnotationManager!.create(
          CircleAnnotationOptions(
            geometry: Point(coordinates: Position(location.longitude, location.latitude)),
            circleColor: Colors.red.value,
            circleRadius: 12.0,
            circleStrokeWidth: 3.0,
            circleStrokeColor: Colors.white.value,
          ),
        );
      }
    }
  }

  Future<Uint8List?> _loadImageAsBytes(String assetPath) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: 150, targetHeight: 150);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  void _handleMapTap(Point coordinate) {
    CampusLocation? closestMatch;
    double shortestDistance = double.infinity;
    const double hitThreshold = 120.0;

    for (var location in _allLocations) {
      final distance = geolocator.Geolocator.distanceBetween(
        coordinate.coordinates.lat.toDouble(),
        coordinate.coordinates.lng.toDouble(),
        location.latitude,
        location.longitude,
      );

      if (distance < hitThreshold && distance < shortestDistance) {
        shortestDistance = distance;
        closestMatch = location;
      }
    }

    if (closestMatch != null) {
      setState(() {
        _destination = closestMatch;
      });
      _drawRoute();
      _openSearchSheet();
    }
  }

  Future<void> _drawRoute() async {
    if (_currentPosition == null || _destination == null) return;

    if (!_isRerouting) {
      await polylineAnnotationManager?.deleteAll();
      setState(() => _isCalculatingRoute = true);
    }

    final String? accessToken = dotenv.env['MAPBOX_ACCESS_TOKEN'];
    if (accessToken == null) return;

    final String url = 'https://api.mapbox.com/directions/v5/mapbox/walking/'
        '${_currentPosition!.longitude},${_currentPosition!.latitude};'
        '${_destination!.longitude},${_destination!.latitude}'
        '?geometries=geojson&steps=true&overview=full&access_token=$accessToken';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          final List<dynamic> coords = geometry['coordinates'];
          final List<Position> routeCoords = coords.map((c) => Position(c[0], c[1])).toList();

          _currentRouteLine = routeCoords;

          if (!_isRerouting) {
            await polylineAnnotationManager?.create(PolylineAnnotationOptions(
              geometry: LineString(coordinates: routeCoords),
              lineColor: NavigationConstants.routeColor.value,
              lineWidth: 6.0,
              lineJoin: LineJoin.ROUND,
            ));
            _fitMapToRoute(routeCoords);
          } else {
            await polylineAnnotationManager?.deleteAll();
            await polylineAnnotationManager?.create(PolylineAnnotationOptions(
              geometry: LineString(coordinates: routeCoords),
              lineColor: NavigationConstants.routeColor.value,
              lineWidth: 6.0,
              lineJoin: LineJoin.ROUND,
            ));
          }

          List<NavigationStep> steps = [];
          if (route['legs'].isNotEmpty) {
            for (var step in route['legs'][0]['steps']) {
              steps.add(NavigationStep.fromJson(step));
            }
          }

          if (mounted) {
            setState(() {
              _routeDistance = (route['distance'] / 1000);
              _routeDuration = (route['duration'] / 60);
              _navigationSteps = steps;
              _isCalculatingRoute = false;
              _isRerouting = false;
            });
          }
        }
      }
    } catch (e) {
      setState(() {
        _isCalculatingRoute = false;
        _isRerouting = false;
      });
    }
  }

  void _fitMapToRoute(List<Position> coords) async {
    if (mapboxMap == null || coords.isEmpty) return;
    final cameraOptions = await mapboxMap!.cameraForCoordinates(
        coords.map((e) => Point(coordinates: e)).toList(),
        MbxEdgeInsets(top: 150, left: 50, bottom: 350, right: 50),
        NavigationConstants.navigationPitch,
        null
    );
    mapboxMap!.flyTo(cameraOptions, MapAnimationOptions(duration: 1000));
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
  }

  Future<void> _speakInstruction(String text) async {
    if (text.isNotEmpty) await _flutterTts.speak(text);
  }

  IconData _getManeuverIcon(String maneuver, String instruction) {
    if (instruction.contains("destination")) return Icons.flag_circle;
    switch (maneuver) {
      case 'turn':
        if (instruction.toLowerCase().contains('left')) return Icons.turn_left;
        if (instruction.toLowerCase().contains('right')) return Icons.turn_right;
        return Icons.arrow_upward;
      case 'arrive': return Icons.flag_circle;
      case 'uturn': return Icons.u_turn_left;
      default: return Icons.arrow_upward;
    }
  }

  void _startNavigation() {
    if (Navigator.canPop(context)) Navigator.pop(context);
    setState(() {
      _isNavigating = true;
      _currentStepIndex = 0;
    });
    if (_navigationSteps.isNotEmpty) _speakInstruction(_navigationSteps[0].instruction);

    _positionSubscription?.cancel();
    _positionSubscription = geolocator.Geolocator.getPositionStream(
      locationSettings: const geolocator.LocationSettings(accuracy: geolocator.LocationAccuracy.bestForNavigation, distanceFilter: 2),
    ).listen((pos) {
      if (!_isNavigating) return;
      _currentPosition = pos;
      _updateNearestLocationLabel(pos);

      mapboxMap?.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(pos.longitude, pos.latitude)),
          zoom: NavigationConstants.navigationZoom,
          bearing: pos.heading,
          pitch: NavigationConstants.navigationPitch,
        ),
        MapAnimationOptions(duration: 500),
      );

      if (_navigationSteps.isNotEmpty && _currentStepIndex < _navigationSteps.length) {
        final step = _navigationSteps[_currentStepIndex];
        final dist = geolocator.Geolocator.distanceBetween(
            pos.latitude, pos.longitude, step.latitude, step.longitude
        );
        setState(() => _distanceToNextStep = dist);

        if (dist < NavigationConstants.stepCompletionThreshold) {
          setState(() => _currentStepIndex++);
          if (_currentStepIndex < _navigationSteps.length) {
            _speakInstruction(_navigationSteps[_currentStepIndex].instruction);
          } else {
            _stopNavigation();
            _speakInstruction("You have arrived.");
            _showArrivalDialog();
          }
        }
      }
    });
  }

  void _stopNavigation() {
    _positionSubscription?.cancel();
    _flutterTts.stop();
    setState(() => _isNavigating = false);
    mapboxMap?.flyTo(
        CameraOptions(zoom: NavigationConstants.defaultZoom, pitch: NavigationConstants.navigationPitch, bearing: 0),
        MapAnimationOptions(duration: 1000)
    );
  }

  void _showArrivalDialog() {
    showDialog(context: context, builder: (_) => AlertDialog(title: const Text("Arrived!"), content: Text("You have reached ${_destination?.name}"), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))]));
  }

  // --- UI COMPONENTS ---

  void _openSearchSheet() {
    _searchQuery = '';
    _searchController.clear();
    setState(() {});

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Center(child: Container(margin: const EdgeInsets.symmetric(vertical: 12), width: 40, height: 4, color: Colors.grey[400])),
                    Expanded(
                        child: _destination == null
                            ? _buildPlacesList(scrollController, setSheetState)
                            : _buildDestinationDetails(scrollController, setSheetState)
                    ),
                  ],
                ),
              );
            }
          );
        },
      ),
    );
  }

  Widget _buildPlacesList(ScrollController controller, StateSetter setSheetState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Filter Logic
    final filtered = _searchQuery.isEmpty 
      ? _allLocations 
      : _allLocations.where((l) => l.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    // 4. UPDATED: Filter by Selected Section
    final sectionLocations = filtered.where((l) => l.section == _selectedSection).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return Column(
      children: [
        // --- Search Bar ---
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: TextField(
            controller: _searchController,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            onChanged: (value) => setSheetState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: "Search places...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: isDark ? Colors.grey[800] : Colors.grey[200],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            ),
          ),
        ),

        // --- 5. NEW: Section Toggle Buttons ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              _buildSectionToggleButton("East Campus", CampusSection.east, setSheetState),
              const SizedBox(width: 12),
              _buildSectionToggleButton("West Campus", CampusSection.west, setSheetState),
            ],
          ),
        ),
        
        const SizedBox(height: 12),

        // --- List Content ---
        Expanded(
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.only(bottom: 20),
            children: [
              if (sectionLocations.isNotEmpty)
                ...sectionLocations.map((loc) => _buildLocationTile(loc, isDark, setSheetState))
              else
                Padding(
                  padding: const EdgeInsets.only(top: 40), 
                  child: Center(
                    child: Text(
                      "No locations in ${_selectedSection == CampusSection.east ? 'East' : 'West'}", 
                      style: TextStyle(color: Colors.grey[600])
                    )
                  )
                ),
            ],
          ),
        ),
      ],
    );
  }

  // --- 6. NEW: Toggle Button Widget ---
  Widget _buildSectionToggleButton(String title, CampusSection section, StateSetter setSheetState) {
    final isSelected = _selectedSection == section;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setSheetState(() => _selectedSection = section);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF007B3E) : Colors.transparent, // Active Green
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF007B3E) : Colors.grey[400]!,
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationTile(CampusLocation loc, bool isDark, StateSetter setSheetState) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFF007B3E).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(loc.icon, color: const Color(0xFF007B3E), size: 20),
      ),
      title: Text(loc.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Theme.of(context).colorScheme.onSurface)),
      subtitle: Text(loc.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() => _destination = loc);
        _drawRoute();
        setSheetState(() {});
        _searchQuery = '';
        _searchController.clear();
      },
    );
  }

  Widget _buildDestinationDetails(ScrollController controller, StateSetter setSheetState) {
    return Stack(
      children: [
        ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 40),
            
            // Image with gallery link
            GestureDetector(
              onTap: () {
                if (_destination!.imagePaths.isNotEmpty) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ImageGalleryScreen(imagePaths: _destination!.imagePaths, locationName: _destination!.name, initialIndex: 0)));
                }
              },
              child: Stack(
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(16),
                      image: _destination!.imagePaths.isNotEmpty 
                        ? DecorationImage(image: AssetImage(_destination!.mainImage), fit: BoxFit.cover) 
                        : null
                    ),
                    child: _destination!.imagePaths.isEmpty ? const Center(child: Icon(Icons.image_not_supported)) : null,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            Text(_destination!.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_destination!.description),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, 
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _startNavigation, 
                icon: const Icon(Icons.directions), 
                label: const Text("Start Navigation"),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF007B3E), foregroundColor: Colors.white),
              )
            ),
            if (_destination!.hasPanorama) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () {
                       Navigator.push(context, MaterialPageRoute(builder: (_) => PanoramaViewScreen(imageUrl: _destination!.panoramaUrl!)));
                    },
                    icon: const Icon(Icons.threesixty),
                    label: const Text("View 360° Tour"),
                    style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF007B3E)),
                  ),
                )
            ]
          ],
        ),
        Positioned(top: 16, right: 16, child: IconButton(icon: const Icon(Icons.close), onPressed: () { setState(() { _destination = null; }); polylineAnnotationManager?.deleteAll(); Navigator.pop(context); })),
        Positioned(top: 16, left: 16, child: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () { setState(() { _destination = null; }); polylineAnnotationManager?.deleteAll(); setSheetState(() {}); })),
      ],
    );
  }

  // --- UI BUILD ---
  @override
  Widget build(BuildContext context) {
    final String mapStyle = dotenv.env['MAPBOX_STYLE_URI'] ?? MapboxStyles.OUTDOORS;
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. MAP
          MapWidget(
            onMapCreated: _onMapCreated,
            styleUri: mapStyle,
            cameraOptions: CameraOptions(center: Point(coordinates: Position(NavigationConstants.defaultLng, NavigationConstants.defaultLat)), zoom: NavigationConstants.defaultZoom),
          ),

          // 2. BACK BUTTON (Top Left)
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  // Check if we can pop, otherwise it might be a tab switch (if you implement that later)
                  if (Navigator.canPop(context)) {
                    Navigator.of(context).pop();
                  } else {
                    // Fallback for when used in tabs, maybe nothing or open dashboard? 
                    // For now, if pushed, this works.
                  }
                },
              ),
            ),
          ),

          // 3. CURRENT LOCATION PILL (Top Center)
          Positioned(
            top: 50, left: 70, right: 70,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)]),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.my_location, color: Colors.blue, size: 16),
                    const SizedBox(width: 8),
                    Flexible(child: Text(_currentLocationLabel, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87), overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
            ),
          ),

          // 4. BOTTOM BUTTONS (Search & My Location)
          if (!_isNavigating)
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FloatingActionButton(
                    heroTag: "searchBtn", 
                    backgroundColor: Colors.white, 
                    onPressed: _openSearchSheet, 
                    child: const Icon(Icons.search, color: Colors.black87)
                  ),
                  FloatingActionButton(
                    heroTag: "myLocBtn",
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.gps_fixed, color: Colors.green),
                    onPressed: () {
                      if (_currentPosition != null) {
                        mapboxMap?.flyTo(CameraOptions(center: Point(coordinates: Position(_currentPosition!.longitude, _currentPosition!.latitude)), zoom: 17), MapAnimationOptions(duration: 1000));
                      } else {
                        _initializeUserLocation(); // Retry on click
                      }
                    },
                  )
                ],
              ),
            ),

          if (_isNavigating) _buildNavigationHUD(),
          if (_isCalculatingRoute) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildNavigationHUD() {
    if (_navigationSteps.isEmpty || _currentStepIndex >= _navigationSteps.length) return const SizedBox.shrink();
    
    final step = _navigationSteps[_currentStepIndex];
    final IconData directionIcon = _getManeuverIcon(step.maneuver, step.instruction);

    return Positioned(
      top: 0, left: 0, right: 0,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[800], 
            borderRadius: BorderRadius.circular(16), 
            boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black26)],
          ),
          child: Row(
            children: [
              Icon(directionIcon, color: Colors.white, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${_distanceToNextStep.toStringAsFixed(0)} m", 
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
                    ),
                    Text(
                      step.instruction, 
                      style: const TextStyle(color: Colors.white70, fontSize: 16), 
                      maxLines: 2, 
                      overflow: TextOverflow.ellipsis
                    ),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: _stopNavigation)
            ],
          ),
        ),
      ),
    );
  }
}

extension on GesturesSettingsInterface {
  void addOnMapTapListener(Null Function(MapContentGestureContext context) param0) {}
}