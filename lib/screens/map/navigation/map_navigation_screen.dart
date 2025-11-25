import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

// --- MODELS & IMPORTS ---
import 'package:dlsud_go/widgets/image_gallery_screen.dart';
import 'package:dlsud_go/screens/panorama/panorama_view_screen.dart';
import 'package:dlsud_go/models/campus_location.dart';

// --- CONSTANTS ---
class NavigationConstants {
  static const double defaultZoom = 16.0;
  static const double navigationZoom = 18.5;
  static const double navigationPitch = 50.0;
  static const double stepCompletionThreshold = 15.0;
  static const Color dlsuGreen = Color(0xFF007B3E); // Official Green
  static const Color accentGreen = Color(0xFF00A855); // Lighter accent
}

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

class MapNavigationScreen extends StatefulWidget {
  const MapNavigationScreen({super.key});

  @override
  State<MapNavigationScreen> createState() => _MapNavigationScreenState();
}

class _MapNavigationScreenState extends State<MapNavigationScreen> {
  MapboxMap? mapboxMap;

  // Data & State
  final List<CampusLocation> _allLocations = CampusLocation.allLocations;
  List<CampusLocation> _filteredLocations = [];
  final TextEditingController _searchController = TextEditingController();

  CampusLocation? _destination;
  geolocator.Position? _currentPosition;
  String _currentLocationLabel = "Locating...";

  // Navigation State
  bool _isCalculatingRoute = false;
  bool _isNavigating = false;
  double? _routeDistance;
  double? _routeDuration;
  List<NavigationStep> _navigationSteps = [];
  int _currentStepIndex = 0;
  double _distanceToNextStep = 0;

  // Distance Tracking State
  double _totalDistanceTraveled = 0.0;
  geolocator.Position? _lastNavPosition;

  StreamSubscription<geolocator.Position>? _positionSubscription;

  // Map Managers
  CircleAnnotationManager? circleAnnotationManager;
  PointAnnotationManager? pointAnnotationManager;
  PolylineAnnotationManager? polylineAnnotationManager;

  @override
  void initState() {
    super.initState();
    _filteredLocations = _allLocations;
    _initializeUserLocation();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _searchController.dispose();
    circleAnnotationManager?.deleteAll();
    pointAnnotationManager?.deleteAll();
    polylineAnnotationManager?.deleteAll();
    super.dispose();
  }

  // --- MAP SETUP ---

  void _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;
    await _enable3DBuildings();

    // Initialize all annotation managers
    circleAnnotationManager = await mapboxMap.annotations.createCircleAnnotationManager();
    pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
    polylineAnnotationManager = await mapboxMap.annotations.createPolylineAnnotationManager();

    await mapboxMap.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
        pulsingColor: Colors.blueAccent.value,
        puckBearingEnabled: true,
      ),
    );

    _loadLocationMarkers();

    mapboxMap.gestures.addOnMapTapListener((MapContentGestureContext context) {
      _handleMapTap(context.point);
    });
  }

  // 3D Buildings Logic
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
        fillExtrusionColor: Colors.grey[400]!.value,
        fillExtrusionOpacity: 0.9,
      );

      await style.addLayer(fillExtrusionLayer);
      await style.setStyleLayerProperty("3d-buildings", "fill-extrusion-height", ["get", "height"]);
      await style.setStyleLayerProperty("3d-buildings", "fill-extrusion-base", ["get", "min_height"]);

    } catch (e) {
      debugPrint("3D Building error: $e");
    }
  }

  // --- MARKERS & INTERACTION ---

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
                iconSize: 0.3,
                iconAnchor: IconAnchor.BOTTOM,
              ),
            );
            imageLoaded = true;
          } catch (e) {
            debugPrint('⚠️ Image marker failed for ${location.name}: $e');
          }
        }
      }
      if (!imageLoaded) {
        await circleAnnotationManager!.create(
          CircleAnnotationOptions(
            geometry: Point(coordinates: Position(location.longitude, location.latitude)),
            circleColor: NavigationConstants.dlsuGreen.value,
            circleRadius: 8.0,
            circleStrokeWidth: 2.0,
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

    for (var location in _allLocations) {
      final distance = geolocator.Geolocator.distanceBetween(
        coordinate.coordinates.lat.toDouble(),
        coordinate.coordinates.lng.toDouble(),
        location.latitude,
        location.longitude,
      );

      if (distance < 100 && distance < shortestDistance) {
        shortestDistance = distance;
        closestMatch = location;
      }
    }

    if (closestMatch != null) {
      setState(() => _destination = closestMatch);
      _drawRoute();
    }
  }

  // --- LOCATION & ROUTING ---

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
      _updateLocationLabel(position);

      mapboxMap?.flyTo(
          CameraOptions(
            center: Point(coordinates: Position(position.longitude, position.latitude)),
            zoom: NavigationConstants.defaultZoom,
          ),
          MapAnimationOptions(duration: 1000)
      );
    }
  }

  void _updateLocationLabel(geolocator.Position position) {
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
    String label = (nearest != null && minDistance < 100) ? "Near ${nearest.name}" : "On Campus";
    if (mounted && label != _currentLocationLabel) {
      setState(() => _currentLocationLabel = label);
    }
  }

  Future<void> _drawRoute() async {
    if (_currentPosition == null || _destination == null) return;
    setState(() => _isCalculatingRoute = true);
    await polylineAnnotationManager?.deleteAll();

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
            lineColor: NavigationConstants.dlsuGreen.value,
            lineWidth: 6.0,
            lineJoin: LineJoin.ROUND,
          ));

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
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Route error: $e");
      if (mounted) setState(() => _isCalculatingRoute = false);
    }
  }

  // --- NAVIGATION LOGIC ---

  void _startNavigation() {
    setState(() {
      _isNavigating = true;
      _currentStepIndex = 0;
      _totalDistanceTraveled = 0.0;
      _lastNavPosition = null;
    });

    _positionSubscription?.cancel();
    _positionSubscription = geolocator.Geolocator.getPositionStream(
      locationSettings: const geolocator.LocationSettings(
        accuracy: geolocator.LocationAccuracy.bestForNavigation,
        distanceFilter: 2,
      ),
    ).listen((pos) {
      if (!_isNavigating) return;

      double delta = 0.0;
      if (_lastNavPosition != null) {
        delta = geolocator.Geolocator.distanceBetween(
          _lastNavPosition!.latitude, _lastNavPosition!.longitude,
          pos.latitude, pos.longitude,
        );
      }

      mapboxMap?.flyTo(
        CameraOptions(
          center: Point(coordinates: Position(pos.longitude, pos.latitude)),
          zoom: NavigationConstants.navigationZoom,
          bearing: pos.heading,
          pitch: NavigationConstants.navigationPitch,
        ),
        MapAnimationOptions(duration: 800),
      );

      setState(() {
        if (_lastNavPosition != null && delta > 0.5) {
          _totalDistanceTraveled += delta;
        }
        _lastNavPosition = pos;
        _currentPosition = pos;
        _updateLocationLabel(pos);

        if (_navigationSteps.isNotEmpty && _currentStepIndex < _navigationSteps.length) {
          final step = _navigationSteps[_currentStepIndex];
          final dist = geolocator.Geolocator.distanceBetween(
              pos.latitude, pos.longitude, step.latitude, step.longitude
          );
          _distanceToNextStep = dist;

          if (dist < NavigationConstants.stepCompletionThreshold) {
            _currentStepIndex++;
            if (_currentStepIndex >= _navigationSteps.length) {
              _stopNavigation();
              _showArrivalDialog();
            }
          }
        }
      });
    });
  }

  void _stopNavigation() {
    _positionSubscription?.cancel();
    setState(() => _isNavigating = false);

    if (_currentPosition != null) {
      mapboxMap?.flyTo(
          CameraOptions(
              center: Point(coordinates: Position(_currentPosition!.longitude, _currentPosition!.latitude)),
              zoom: NavigationConstants.defaultZoom,
              pitch: 0,
              bearing: 0
          ),
          MapAnimationOptions(duration: 1000)
      );
    }
  }

  void _showArrivalDialog() {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 10),
              Text("You've Arrived!"),
            ],
          ),
          content: Text("You have reached ${_destination?.name}. \nTotal Distance: ${(_totalDistanceTraveled/1000).toStringAsFixed(2)} km"),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Awesome", style: TextStyle(color: NavigationConstants.dlsuGreen))
            )
          ],
        )
    );
  }

  // --- UI BUILDING BLOCKS ---

  @override
  Widget build(BuildContext context) {
    final showDetailsCard = _destination != null && !_isNavigating;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. MAP
          MapWidget(
            onMapCreated: _onMapCreated,
            styleUri: MapboxStyles.OUTDOORS,
            cameraOptions: CameraOptions(
              center: Point(coordinates: Position(120.9580, 14.3250)),
              zoom: NavigationConstants.defaultZoom,
            ),
          ),

          // 2. LOCATION PILL
          if (!_isNavigating)
            Positioned(
              top: 60,
              left: 20,
              right: 20,
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on, color: NavigationConstants.dlsuGreen, size: 20),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _currentLocationLabel,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // 3. BACK BUTTON (Top Left)
          if (!_isNavigating)
            Positioned(
              top: 60,
              left: 20,
              child: FloatingActionButton.small(
                heroTag: "backBtn",
                backgroundColor: Colors.white,
                child: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
              ),
            ),

          // 4. MAIN CONTROLS (Search & My Location)
          if (!_isNavigating && !showDetailsCard) ...[
            Positioned(
              bottom: 40,
              right: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    heroTag: "myLoc",
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.gps_fixed, color: Colors.grey),
                    onPressed: () => _initializeUserLocation(),
                  ),
                  const SizedBox(height: 16),
                  FloatingActionButton.extended(
                    heroTag: "search",
                    backgroundColor: NavigationConstants.dlsuGreen,
                    icon: const Icon(Icons.search, color: Colors.white),
                    label: const Text("Find Building", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: _openSearchSheet,
                  ),
                ],
              ),
            ),
          ],

          // 5. DESTINATION CARD
          if (showDetailsCard)
            _buildDestinationCard(),

          // 6. NAVIGATION HUD
          if (_isNavigating) _buildModernNavigationHUD(),

          // 7. NAV CONTROLS
          if (_isNavigating) ...[
            Positioned(
              bottom: 40,
              left: 20,
              child: FloatingActionButton(
                heroTag: "recenterBtn",
                backgroundColor: Colors.white,
                foregroundColor: NavigationConstants.dlsuGreen,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onPressed: () {
                  if (_currentPosition != null) {
                    mapboxMap?.flyTo(
                      CameraOptions(
                        center: Point(coordinates: Position(_currentPosition!.longitude, _currentPosition!.latitude)),
                        zoom: NavigationConstants.navigationZoom,
                        bearing: _currentPosition!.heading,
                        pitch: NavigationConstants.navigationPitch,
                      ),
                      MapAnimationOptions(duration: 800),
                    );
                  }
                },
                child: const Icon(Icons.navigation_rounded, size: 28),
              ),
            ),

            Positioned(
              bottom: 40,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.directions_walk, size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      _formatDistance(_totalDistanceTraveled),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // 8. LOADING
          if (_isCalculatingRoute)
            Container(
              color: Colors.black12,
              child: const Center(
                child: Card(
                  elevation: 5,
                  shape: CircleBorder(),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(color: NavigationConstants.dlsuGreen),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildModernNavigationHUD() {
    if (_navigationSteps.isEmpty || _currentStepIndex >= _navigationSteps.length) return const SizedBox.shrink();
    final step = _navigationSteps[_currentStepIndex];
    return Positioned(
      top: 50, left: 16, right: 16,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [NavigationConstants.dlsuGreen, NavigationConstants.accentGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: NavigationConstants.dlsuGreen.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.turn_right, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("${_distanceToNextStep.toStringAsFixed(0)} meters", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(step.instruction, style: const TextStyle(color: Colors.white70, fontSize: 16), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                GestureDetector(onTap: _stopNavigation, child: const Icon(Icons.close, color: Colors.white70))
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationCard() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.55,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -5))],
        ),
        child: Column(
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Image Logic
                  if (_destination!.imagePaths.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ImageGalleryScreen(
                            imagePaths: _destination!.imagePaths,
                            locationName: _destination!.name,
                            initialIndex: 0)));
                      },
                      child: Stack(children: [
                        Container(height: 200, width: double.infinity, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
                            child: ClipRRect(borderRadius: BorderRadius.circular(20),
                                child: Image.asset(_destination!.mainImage, fit: BoxFit.cover, errorBuilder: (c,e,s)=>const Center(child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey))))),
                        if (_destination!.hasGallery) Positioned(bottom: 12, right: 12, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)), child: Row(children: [const Icon(Icons.photo_library, color: Colors.white, size: 16), const SizedBox(width: 6), Text('${_destination!.imagePaths.length}', style: const TextStyle(color: Colors.white, fontSize: 14))]))),
                      ]),
                    ),
                  const SizedBox(height: 20),

                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(child: Text(_destination!.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                    IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => setState(() { _destination = null; polylineAnnotationManager?.deleteAll(); }))
                  ]),
                  const SizedBox(height: 8),
                  Text(_destination!.description, style: TextStyle(color: Colors.grey[600], fontSize: 15)),
                  const SizedBox(height: 20),
                  Row(children: [
                    _statBadge(Icons.timer, "${_routeDuration?.toStringAsFixed(0) ?? '-'} min"),
                    const SizedBox(width: 12),
                    _statBadge(Icons.straighten, "${_routeDistance?.toStringAsFixed(1) ?? '-'} km"),
                  ]),
                  const SizedBox(height: 24),
                  if (_destination!.hasPanorama) ...[
                    SizedBox(width: double.infinity, height: 56, child: OutlinedButton.icon(onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => PanoramaViewScreen(imageUrl: _destination!.panoramaUrl!)));
                    }, icon: const Icon(Icons.threesixty), label: const Text("View 360° Tour"), style: OutlinedButton.styleFrom(foregroundColor: NavigationConstants.dlsuGreen, side: const BorderSide(color: NavigationConstants.dlsuGreen), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: _startNavigation, style: ElevatedButton.styleFrom(backgroundColor: NavigationConstants.dlsuGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: const Text("Start Navigation", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSearchSheet() {
    _searchController.clear();
    setState(() => _filteredLocations = _allLocations);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9, minChildSize: 0.5, maxChildSize: 0.95,
        builder: (_, controller) {
          return Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: NavigationConstants.dlsuGreen),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: "Search building or office...",
                            border: InputBorder.none,
                          ),
                          onChanged: (val) {
                            setState(() {
                              _filteredLocations = _allLocations.where((loc) =>
                              loc.name.toLowerCase().contains(val.toLowerCase()) ||
                                  loc.description.toLowerCase().contains(val.toLowerCase())
                              ).toList();
                            });
                          },
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: StatefulBuilder(
                      builder: (context, setSheetState) {
                        _searchController.addListener(() => setSheetState(() {}));
                        return ListView.builder(
                          controller: controller,
                          itemCount: _filteredLocations.length,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          itemBuilder: (_, i) {
                            final loc = _filteredLocations[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: InkWell(
                                onTap: () {
                                  setState(() => _destination = loc);
                                  _drawRoute();
                                  Navigator.pop(context);
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(border: Border.all(color: Colors.grey[200]!), borderRadius: BorderRadius.circular(16)),
                                  child: Row(
                                    children: [
                                      Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)), child: Icon(loc.icon, color: NavigationConstants.dlsuGreen)),
                                      const SizedBox(width: 16),
                                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(loc.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text(loc.description, style: TextStyle(color: Colors.grey[600], fontSize: 13), maxLines: 1)])),
                                      const Icon(Icons.chevron_right, color: Colors.grey),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
      child: Row(children: [Icon(icon, size: 16, color: Colors.grey[700]), const SizedBox(width: 8), Text(label, style: const TextStyle(fontWeight: FontWeight.w600))]),
    );
  }

  String _formatDistance(double meters) {
    return meters >= 1000 ? "${(meters / 1000).toStringAsFixed(2)} km" : "${meters.toStringAsFixed(0)} m";
  }
}

extension on GesturesSettingsInterface {
  void addOnMapTapListener(Null Function(MapContentGestureContext context) param0) {}
}