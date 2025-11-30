import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart'; // 1. ADDED TTS IMPORT
import 'dart:typed_data';
import 'dart:ui' as ui;

// --- 1. MODELS & IMPORTS ---
import 'package:dlsud_go/widgets/image_gallery_screen.dart';
import 'package:dlsud_go/screens/panorama/panorama_view_screen.dart';
import 'package:dlsud_go/models/campus_location.dart'; 
// (Make sure this file exists and contains the CampusLocation class)

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

// --- 2. CONSTANTS ---

class NavigationConstants {
  static const double defaultZoom = 16.0;
  static const double navigationZoom = 18.5;
  static const double navigationPitch = 60.0;
  static const double stepCompletionThreshold = 15.0; // Distance in meters to complete a step
  static const Color routeColor = Color(0xFF007B3E); // DLSU Green
  static const double defaultLat = 14.3250;
  static const double defaultLng = 120.9580;
}

// --- 3. MAIN SCREEN ---

class MapNavigationScreen extends StatefulWidget {
  const MapNavigationScreen({super.key});

  @override
  State<MapNavigationScreen> createState() => _MapNavigationScreenState();
}

class _MapNavigationScreenState extends State<MapNavigationScreen> {
  MapboxMap? mapboxMap;
  
  // TTS Instance
  final FlutterTts _flutterTts = FlutterTts(); // 2. INSTANTIATE TTS

  final List<CampusLocation> _allLocations = CampusLocation.allLocations;
  CampusLocation? _destination;
  geolocator.Position? _currentPosition;
  String _currentLocationLabel = "Locating...";

  bool _isCalculatingRoute = false;
  bool _isNavigating = false;

  double? _routeDistance;
  double? _routeDuration;
  List<NavigationStep> _navigationSteps = [];
  int _currentStepIndex = 0;
  double _distanceToNextStep = 0;

  StreamSubscription<geolocator.Position>? _positionSubscription;

  // Search State
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Annotation Managers
  CircleAnnotationManager? circleAnnotationManager;
  PointAnnotationManager? pointAnnotationManager;
  PolylineAnnotationManager? polylineAnnotationManager;

  @override
  void initState() {
    super.initState();
    _initializeUserLocation();
    _initTts(); // 3. INITIALIZE TTS
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    circleAnnotationManager?.deleteAll();
    pointAnnotationManager?.deleteAll();
    polylineAnnotationManager?.deleteAll();
    _searchController.dispose();
    _flutterTts.stop(); // 4. STOP TTS ON DISPOSE
    super.dispose();
  }

  // --- TTS CONFIGURATION ---
  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5); // Adjust speed (0.0 to 1.0)
    await _flutterTts.setVolume(1.0);
  }

  Future<void> _speakInstruction(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  // --- MAP LOGIC ---

  void _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;

    await _enable3DBuildings();

    // Create annotation managers
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

    mapboxMap.gestures.addOnMapTapListener((MapContentGestureContext context) {
      _handleMapTap(context.point);
    });
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
      debugPrint("Failed to enable 3D buildings: $e");
    }
  }

  Future<void> _loadLocationMarkers() async {
    if (pointAnnotationManager == null || circleAnnotationManager == null) return;

    await pointAnnotationManager!.deleteAll();
    await circleAnnotationManager!.deleteAll();

    for (var location in _allLocations) {
      bool imageLoaded = false;

      // Try to load image marker
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
          } catch (e) {
            debugPrint('⚠️ Image marker failed for ${location.name}: $e');
          }
        }
      }

      // Fallback to circle
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
      final ui.Codec codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: 150,
        targetHeight: 150,
      );
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

  void _updateNearestLocationLabel(geolocator.Position position) {
    if (_allLocations.isEmpty) return;
    CampusLocation? nearest;
    double minDistance = double.infinity;

    for (var loc in _allLocations) {
      double dist = geolocator.Geolocator.distanceBetween(
          position.latitude, position.longitude, loc.latitude, loc.longitude
      );
      if (dist < minDistance) {
        minDistance = dist;
        nearest = loc;
      }
    }

    String label;
    if (nearest != null && minDistance < 100) {
      label = "Near ${nearest.name}";
    } else {
      label = "Current Location";
    }

    if (mounted && label != _currentLocationLabel) {
      setState(() => _currentLocationLabel = label);
    }
  }

  Future<void> _initializeUserLocation() async {
    bool serviceEnabled = await geolocator.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    geolocator.LocationPermission permission = await geolocator.Geolocator.checkPermission();
    if (permission == geolocator.LocationPermission.denied) {
      permission = await geolocator.Geolocator.requestPermission();
      if (permission == geolocator.LocationPermission.denied) return;
    }

    final position = await geolocator.Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() => _currentPosition = position);
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
  }

  // --- ROUTING ---

  Future<void> _drawRoute() async {
    if (_currentPosition == null || _destination == null) return;

    await polylineAnnotationManager?.deleteAll();
    setState(() => _isCalculatingRoute = true);

    final String? accessToken = dotenv.env['MAPBOX_ACCESS_TOKEN'];
    if (accessToken == null) return;

    final String url =
        'https://api.mapbox.com/directions/v5/mapbox/walking/'
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

          await polylineAnnotationManager?.create(PolylineAnnotationOptions(
            geometry: LineString(coordinates: routeCoords),
            lineColor: NavigationConstants.routeColor.value,
            lineWidth: 6.0,
            lineJoin: LineJoin.ROUND,
          ));

          List<NavigationStep> steps = [];
          if (route['legs'].isNotEmpty) {
            for (var step in route['legs'][0]['steps']) {
              steps.add(NavigationStep.fromJson(step));
            }
          }

          _fitMapToRoute(routeCoords);

          if (mounted) {
            setState(() {
              _routeDistance = (route['distance'] / 1000);
              _routeDuration = (route['duration'] / 60);
              _navigationSteps = steps;
              _isCalculatingRoute = false;
            });
          }
        }
      }
    } catch (e) {
      setState(() => _isCalculatingRoute = false);
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

  // --- NAVIGATION EXECUTION (UPDATED WITH VOICE) ---

  void _startNavigation() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    setState(() {
      _isNavigating = true;
      _currentStepIndex = 0;
    });

    // Speak the first instruction immediately
    if (_navigationSteps.isNotEmpty) {
      _speakInstruction(_navigationSteps[0].instruction); // 5. SPEAK FIRST INSTRUCTION
    }

    _positionSubscription?.cancel();
    _positionSubscription = geolocator.Geolocator.getPositionStream(
      locationSettings: const geolocator.LocationSettings(
        accuracy: geolocator.LocationAccuracy.bestForNavigation,
        distanceFilter: 2,
      ),
    ).listen((pos) {
      if (!_isNavigating) return;
      _currentPosition = pos;
      _updateNearestLocationLabel(pos);

      // Camera follows user
      mapboxMap?.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(pos.longitude, pos.latitude)),
          zoom: NavigationConstants.navigationZoom,
          bearing: pos.heading,
          pitch: NavigationConstants.navigationPitch,
        ),
        MapAnimationOptions(duration: 500),
      );

      // Step Completion Logic
      if (_navigationSteps.isNotEmpty && _currentStepIndex < _navigationSteps.length) {
        final step = _navigationSteps[_currentStepIndex];
        final dist = geolocator.Geolocator.distanceBetween(
            pos.latitude, pos.longitude, step.latitude, step.longitude
        );
        setState(() => _distanceToNextStep = dist);

        if (dist < NavigationConstants.stepCompletionThreshold) {
          setState(() {
            _currentStepIndex++;
            // 6. SPEAK NEXT INSTRUCTION ON STEP COMPLETION
            if (_currentStepIndex < _navigationSteps.length) {
              _speakInstruction(_navigationSteps[_currentStepIndex].instruction);
            }
          });
          
          if (_currentStepIndex >= _navigationSteps.length) {
            _stopNavigation();
            _speakInstruction("You have arrived at your destination."); // Arrival announcement
            _showArrivalDialog();
          }
        }
      }
    });
  }

  void _stopNavigation() {
    _positionSubscription?.cancel();
    _flutterTts.stop(); // Stop speaking
    setState(() => _isNavigating = false);
    mapboxMap?.flyTo(
        CameraOptions(
            zoom: NavigationConstants.defaultZoom,
            pitch: NavigationConstants.navigationPitch,
            bearing: 0
        ),
        MapAnimationOptions(duration: 1000)
    );
  }

  void _showArrivalDialog() {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Arrived!"),
          content: Text("You have reached ${_destination?.name}"),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
        )
    );
  }

  // --- UI BUILD ---

  @override
  Widget build(BuildContext context) {
    // 7. PREFER CUSTOM STYLE FROM .ENV
    final String mapStyle = dotenv.env['MAPBOX_STYLE_URI'] ?? MapboxStyles.OUTDOORS;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          
          MapWidget(
            onMapCreated: _onMapCreated,
            styleUri: mapStyle, // Updated to use dynamic style
            cameraOptions: CameraOptions(
              center: Point(coordinates: Position(NavigationConstants.defaultLng, NavigationConstants.defaultLat)),
              zoom: NavigationConstants.defaultZoom,
              pitch: NavigationConstants.navigationPitch,
            ),
          ),


          // 3. TOP CENTER "YOUR LOCATION" PILL
          Positioned(
            top: 50,
            left: 70,
            right: 70,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0,2))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.my_location, color: Colors.blue, size: 16),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _currentLocationLabel,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.black87
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. BOTTOM LEFT SEARCH BUTTON
          if (!_isNavigating)
            Positioned(
              bottom: 30,
              left: 20,
              child: FloatingActionButton(
                heroTag: "searchBtn",
                backgroundColor: Colors.white,
                onPressed: _openSearchSheet,
                child: const Icon(Icons.search, color: Colors.black87),
              ),
            ),

          // 5. NAVIGATION HUD
          if (_isNavigating) _buildNavigationHUD(),

          // 6. LOADING
          if (_isCalculatingRoute) const Center(child: CircularProgressIndicator()),
        ],
      ),

      // 7. MY LOCATION FAB
      floatingActionButton: (!_isNavigating) ? FloatingActionButton(
        heroTag: "myLocBtn",
        backgroundColor: Colors.white,
        child: const Icon(Icons.gps_fixed, color: Colors.green),
        onPressed: () {
          if (_currentPosition != null) {
            mapboxMap?.flyTo(
                CameraOptions(
                  center: Point(coordinates: Position(_currentPosition!.longitude, _currentPosition!.latitude)),
                  zoom: 17,
                  pitch: NavigationConstants.navigationPitch,
                ),
                MapAnimationOptions(duration: 1000)
            );
          }
        },
      ) : null,
    );
  }

  // --- SLIDE-IN SHEET LOGIC ---

  void _openSearchSheet() {
    _searchQuery = '';
    _searchController.clear();
    setState(() {}); 

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setSheetState) {
                final isDark = Theme.of(context).brightness == Brightness.dark;

                return Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 12, bottom: 8),
                          width: 40,
                          height: 4,
                          color: isDark ? Colors.grey[700] : Colors.grey[300],
                        ),
                      ),
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

  List<CampusLocation> get _filteredLocations {
    if (_searchQuery.isEmpty) {
      return _allLocations;
    }
    final query = _searchQuery.toLowerCase();
    return _allLocations.where((location) {
      return location.name.toLowerCase().contains(query) ||
          location.description.toLowerCase().contains(query);
    }).toList();
  }

  Widget _buildPlacesList(ScrollController controller, StateSetter setSheetState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onChanged: (value) {
              setSheetState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: "Search DLSU-D...",
              hintStyle: TextStyle(
                color: isDark ? Colors.grey[500] : Colors.grey[600],
                fontSize: 16,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
              filled: true,
              fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
              ),
            ),
          ),
        ),

        Expanded(
          child: ListView.separated(
            controller: controller,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filteredLocations.length,
            separatorBuilder: (ctx, i) => Divider(
              height: 1,
              color: isDark ? Colors.grey[800] : Colors.grey[300],
            ),
            itemBuilder: (ctx, i) {
              final loc = _filteredLocations[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    loc.icon,
                    color: const Color(0xFF4CAF50),
                    size: 24,
                  ),
                ),
                title: Text(
                  loc.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  loc.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                onTap: () {
                  setState(() => _destination = loc);
                  _drawRoute();
                  setSheetState(() {});
                  _searchQuery = '';
                  _searchController.clear();
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDestinationDetails(ScrollController controller, StateSetter setSheetState) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          children: [
            const SizedBox(height: 40),

            // 1. IMAGE with Gallery Button
            GestureDetector(
              onTap: () {
                if (_destination!.imagePaths.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ImageGalleryScreen(
                        imagePaths: _destination!.imagePaths,
                        locationName: _destination!.name,
                        initialIndex: 0,
                      ),
                    ),
                  );
                }
              },
              child: Stack(
                children: [
                  // Placeholder for image logic if you want to display the image here
                  // Currently empty in original code, consider adding an Image.asset/network here
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(16),
                      image: _destination!.imagePaths.isNotEmpty
                        ? DecorationImage(
                            image: AssetImage(_destination!.mainImage), 
                            fit: BoxFit.cover
                          )
                        : null
                    ),
                    child: _destination!.imagePaths.isEmpty 
                      ? const Center(child: Icon(Icons.image_not_supported)) 
                      : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. INFO
            Text(
              _destination!.name,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _destination!.description,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),

            // 3. CHIPS
            Row(
              children: [
                _infoPill(Icons.timer, "${_routeDuration?.toStringAsFixed(0) ?? '-'} min"),
                const SizedBox(width: 16),
                _infoPill(Icons.straighten, "${_routeDistance?.toStringAsFixed(1) ?? '-'} km"),
              ],
            ),
            const SizedBox(height: 24),

            // 4. 360° PANORAMA BUTTON
            if (_destination!.hasPanorama)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PanoramaViewScreen(
                          imageUrl: _destination!.panoramaUrl!,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.threesixty, size: 24),
                  label: const Text(
                    "View 360° Tour",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4CAF50),
                    side: const BorderSide(color: Color(0xFF4CAF50), width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

            if (_destination!.hasPanorama) const SizedBox(height: 16),

            // 5. START NAVIGATION BUTTON
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _startNavigation,
                icon: const Icon(Icons.directions_walk, size: 24),
                label: const Text(
                  "Start Navigation",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),

        // 6. CLOSE BUTTON
        Positioned(
          right: 16,
          top: 16,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.close,
                size: 24,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: () {
                setState(() {
                  _destination = null;
                  _routeDistance = null;
                });
                polylineAnnotationManager?.deleteAll();
                Navigator.pop(context);
              },
            ),
          ),
        ),

        // 7. BACK BUTTON
        Positioned(
          left: 16,
          top: 16,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back,
                size: 24,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: () {
                setState(() {
                  _destination = null;
                  _routeDistance = null;
                });
                polylineAnnotationManager?.deleteAll();
                setSheetState(() {});
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoPill(IconData icon, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isDark ? Colors.grey[400] : Colors.grey[700],
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationHUD() {
    if (_navigationSteps.isEmpty || _currentStepIndex >= _navigationSteps.length) return const SizedBox.shrink();
    final step = _navigationSteps[_currentStepIndex];
    return Positioned(
      top: 0, left: 0, right: 0,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.green[800], borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black26)]),
          child: Row(
            children: [
              const Icon(Icons.directions_walk, color: Colors.white, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${_distanceToNextStep.toStringAsFixed(0)} m", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    Text(step.instruction, style: const TextStyle(color: Colors.white70, fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis),
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