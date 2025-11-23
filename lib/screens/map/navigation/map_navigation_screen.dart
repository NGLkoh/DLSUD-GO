import 'dart:async';
import 'dart:convert';
import 'package:dlsud_go/models/campus_location.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

// Constants
class NavigationConstants {
  static const double defaultZoom = 16.0;
  static const double navigationZoom = 18.0;
  static const double navigationPitch = 60.0;
  static const double stepCompletionThreshold = 10.0; // meters
  static const double deviationThreshold = 50.0; // meters
  static const double nearLocationThreshold = 100.0; // meters
  static const int searchDebounceMs = 300;
  static const int cameraUpdateDebounceMs = 200;
  static const int positionDistanceFilter = 3; // meters
  static const int apiTimeoutSeconds = 10;
  static const Color routeColor = Colors.blue;
  static const double defaultLat = 14.3295;
  static const double defaultLng = 120.9385;
}

// Navigation Step Model
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
  PointAnnotationManager? pointAnnotationManager;
  PolylineAnnotationManager? polylineAnnotationManager;

  final List<CampusLocation> _allLocations = CampusLocation.allLocations;
  CampusLocation? _destination;
  geolocator.Position? _currentPosition;
  String _currentLocationName = "DLSU-D Campus";

  bool _isPinningMode = false;
  bool _isCalculatingRoute = false;
  bool _isNavigating = false;
  bool _isGettingLocation = true;

  double? _routeDistance;
  double? _routeDuration;

  // Turn-by-turn navigation
  List<NavigationStep> _navigationSteps = [];
  List<Position> _routeCoordinates = [];
  int _currentStepIndex = 0;
  StreamSubscription<geolocator.Position>? _positionSubscription;
  double _distanceToNextStep = 0;
  Timer? _cameraUpdateTimer;
  Timer? _deviationCheckTimer;

  bool get _isMapReady => mapboxMap != null;

  @override
  void initState() {
    super.initState();
    _currentPosition = geolocator.Position(
      longitude: NavigationConstants.defaultLng,
      latitude: NavigationConstants.defaultLat,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
    _initializeUserLocation();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _cameraUpdateTimer?.cancel();
    _deviationCheckTimer?.cancel();
    pointAnnotationManager?.deleteAll();
    polylineAnnotationManager?.deleteAll();
    super.dispose();
  }

  Future<void> _initializeUserLocation() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) {
      if (mounted) {
        setState(() => _isGettingLocation = false);
        _showError(
          'Location permission required',
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () => geolocator.Geolocator.openLocationSettings(),
          ),
        );
      }
      return;
    }

    try {
      final position = await geolocator.Geolocator.getCurrentPosition(
        locationSettings: const geolocator.LocationSettings(
          accuracy: geolocator.LocationAccuracy.high,
          timeLimit: Duration(seconds: NavigationConstants.apiTimeoutSeconds),
        ),
      );
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isGettingLocation = false;
        });
        mapboxMap?.flyTo(
          CameraOptions(
            center: Point(coordinates: Position(position.longitude, position.latitude)),
            zoom: NavigationConstants.defaultZoom,
          ),
          MapAnimationOptions(duration: 1000),
        );
        _updateLocationName(position);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGettingLocation = false);
        _showError('Failed to get location: ${e.toString()}');
      }
    }
  }

  Future<void> _updateLocationName(geolocator.Position position) async {
    CampusLocation? nearestCampus = _findNearestCampusLocation(position);
    if (nearestCampus != null) {
      setState(() => _currentLocationName = nearestCampus.name);
      return;
    }

    final String? accessToken = await _getApiToken();
    if (accessToken == null) {
      setState(() => _currentLocationName = "Current Location");
      return;
    }

    try {
      final url = 'https://api.mapbox.com/geocoding/v5/mapbox.places/'
          '${position.longitude},${position.latitude}.json'
          '?access_token=$accessToken&limit=1';

      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: NavigationConstants.apiTimeoutSeconds),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['features'] != null && data['features'].isNotEmpty) {
          final placeName = data['features'][0]['text'] ?? "Current Location";
          if (mounted) setState(() => _currentLocationName = placeName);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _currentLocationName = "Current Location");
    }
  }

  CampusLocation? _findNearestCampusLocation(geolocator.Position position) {
    double minDistance = double.infinity;
    CampusLocation? nearest;

    for (var location in _allLocations) {
      double distance = geolocator.Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        location.latitude,
        location.longitude,
      );
      if (distance < minDistance && distance < NavigationConstants.nearLocationThreshold) {
        minDistance = distance;
        nearest = location;
      }
    }
    return nearest;
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;
    pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
    polylineAnnotationManager = await mapboxMap.annotations.createPolylineAnnotationManager();
    mapboxMap.location.updateSettings(
      LocationComponentSettings(enabled: true, pulsingEnabled: true),
    );
    _updateRouteAndMarkers();
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled = await geolocator.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showError('Location services are disabled');
      return false;
    }

    geolocator.LocationPermission permission = await geolocator.Geolocator.checkPermission();
    if (permission == geolocator.LocationPermission.denied) {
      permission = await geolocator.Geolocator.requestPermission();
      if (permission == geolocator.LocationPermission.denied) {
        _showError('Location permission denied');
        return false;
      }
    }
    if (permission == geolocator.LocationPermission.deniedForever) {
      _showError(
        'Location permission permanently denied',
        action: SnackBarAction(
          label: 'Settings',
          onPressed: () => geolocator.Geolocator.openAppSettings(),
        ),
      );
      return false;
    }
    return true;
  }

  void _updateRouteAndMarkers() {
    _updateDestinationMarker();
    if (_destination != null) {
      _drawRoute();
    } else {
      polylineAnnotationManager?.deleteAll();
      setState(() {
        _routeDistance = null;
        _routeDuration = null;
        _navigationSteps = [];
        _routeCoordinates = [];
      });
    }
  }

  void _updateDestinationMarker() {
    pointAnnotationManager?.deleteAll();
    if (_destination != null) {
      pointAnnotationManager?.create(PointAnnotationOptions(
        geometry: Point(
          coordinates: Position(_destination!.longitude, _destination!.latitude),
        ),
        iconColor: Colors.red.value,
        iconSize: 1.5,
      ));
    }
  }

  Future<void> _drawRoute() async {
    polylineAnnotationManager?.deleteAll();
    setState(() {
      _isCalculatingRoute = true;
      _routeDistance = null;
      _routeDuration = null;
      _navigationSteps = [];
      _routeCoordinates = [];
    });

    if (_currentPosition == null || _destination == null) {
      setState(() => _isCalculatingRoute = false);
      return;
    }

    final String? accessToken = await _getApiToken();
    if (accessToken == null) {
      setState(() => _isCalculatingRoute = false);
      _showError('Mapbox API token not configured');
      return;
    }

    final String url =
        'https://api.mapbox.com/directions/v5/mapbox/walking/'
        '${_currentPosition!.longitude},${_currentPosition!.latitude};'
        '${_destination!.longitude},${_destination!.latitude}'
        '?geometries=geojson&steps=true&voice_instructions=true&banner_instructions=true'
        '&access_token=$accessToken';

    try {
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: NavigationConstants.apiTimeoutSeconds),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final List<dynamic> coordinates = route['geometry']['coordinates'];
          final List<Position> routeCoordinates =
          coordinates.map((c) => Position(c[0], c[1])).toList();

          polylineAnnotationManager?.create(PolylineAnnotationOptions(
            geometry: LineString(coordinates: routeCoordinates),
            lineColor: NavigationConstants.routeColor.value,
            lineWidth: 6,
            lineOpacity: 0.9,
          ));

          // Parse navigation steps
          List<NavigationStep> steps = [];
          if (route['legs'] != null && route['legs'].isNotEmpty) {
            for (var step in route['legs'][0]['steps']) {
              steps.add(NavigationStep.fromJson(step));
            }
          }

          _fitMapToRoute(routeCoordinates);

          if (mounted) {
            setState(() {
              _routeDistance = route['distance'] / 1000;
              _routeDuration = route['duration'] / 60;
              _navigationSteps = steps;
              _routeCoordinates = routeCoordinates;
              _isCalculatingRoute = false;
            });
          }
        } else {
          throw Exception('No routes found');
        }
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } on TimeoutException {
      if (mounted) {
        setState(() => _isCalculatingRoute = false);
        _showError('Request timed out. Please check your connection.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCalculatingRoute = false);
        _showError(
          'Error calculating route: ${e.toString()}',
          action: SnackBarAction(label: 'Retry', onPressed: _drawRoute),
        );
      }
    }
  }

  void _fitMapToRoute(List<Position> routeCoordinates) async {
    if (mapboxMap == null || routeCoordinates.length < 2) return;

    final cameraOptions = await mapboxMap!.cameraForCoordinates(
      routeCoordinates.map((c) => Point(coordinates: c)).toList(),
      MbxEdgeInsets(top: 150.0, left: 50.0, bottom: 300.0, right: 50.0),
      null,
      null,
    );
    mapboxMap!.flyTo(cameraOptions, MapAnimationOptions(duration: 1500));
  }

  void _startNavigation() {
    if (_destination == null || _currentPosition == null) return;

    _positionSubscription?.cancel();
    _cameraUpdateTimer?.cancel();
    _deviationCheckTimer?.cancel();

    setState(() {
      _isNavigating = true;
      _currentStepIndex = 0;
    });
    HapticFeedback.mediumImpact();

    // Calculate initial bearing
    double bearing = 0;
    if (_navigationSteps.isNotEmpty) {
      bearing = geolocator.Geolocator.bearingBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _navigationSteps[0].latitude,
        _navigationSteps[0].longitude,
      );
      _distanceToNextStep = geolocator.Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _navigationSteps[0].latitude,
        _navigationSteps[0].longitude,
      );
    } else {
      bearing = geolocator.Geolocator.bearingBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _destination!.latitude,
        _destination!.longitude,
      );
    }

    // Center camera on user facing the route direction
    mapboxMap?.flyTo(
      CameraOptions(
        center: Point(
          coordinates: Position(_currentPosition!.longitude, _currentPosition!.latitude),
        ),
        zoom: NavigationConstants.navigationZoom,
        pitch: NavigationConstants.navigationPitch,
        bearing: bearing,
      ),
      MapAnimationOptions(duration: 1000),
    );

    // Start listening to position updates
    _positionSubscription = geolocator.Geolocator.getPositionStream(
      locationSettings: const geolocator.LocationSettings(
        accuracy: geolocator.LocationAccuracy.high,
        distanceFilter: NavigationConstants.positionDistanceFilter,
      ),
    ).listen(
      _onPositionUpdate,
      onError: (error) {
        _showError('Location tracking error: ${error.toString()}');
        _stopNavigation();
      },
    );

    // Start deviation checking
    _deviationCheckTimer = Timer.periodic(
      const Duration(seconds: 5),
          (_) => _checkForDeviation(),
    );
  }

  void _onPositionUpdate(geolocator.Position position) {
    if (!_isNavigating) return;

    setState(() => _currentPosition = position);

    // If no steps or completed all steps
    if (_navigationSteps.isEmpty || _currentStepIndex >= _navigationSteps.length) {
      _updateCameraDebounced(position, position.heading);
      return;
    }

    final currentStep = _navigationSteps[_currentStepIndex];

    // Calculate distance to current step
    final distance = geolocator.Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      currentStep.latitude,
      currentStep.longitude,
    );

    setState(() => _distanceToNextStep = distance);

    // Calculate bearing to next step for camera
    double bearing = geolocator.Geolocator.bearingBetween(
      position.latitude,
      position.longitude,
      currentStep.latitude,
      currentStep.longitude,
    );

    // Update camera with debouncing
    _updateCameraDebounced(position, bearing);

    // Check if reached current step
    if (distance < NavigationConstants.stepCompletionThreshold) {
      HapticFeedback.lightImpact();
      setState(() => _currentStepIndex++);

      if (_currentStepIndex >= _navigationSteps.length) {
        _onArrived();
      }
    }
  }

  void _updateCameraDebounced(geolocator.Position position, double bearing) {
    _cameraUpdateTimer?.cancel();
    _cameraUpdateTimer = Timer(
      const Duration(milliseconds: NavigationConstants.cameraUpdateDebounceMs),
          () {
        mapboxMap?.flyTo(
          CameraOptions(
            center: Point(coordinates: Position(position.longitude, position.latitude)),
            zoom: NavigationConstants.navigationZoom,
            pitch: NavigationConstants.navigationPitch,
            bearing: bearing,
          ),
          MapAnimationOptions(duration: 500),
        );
      },
    );
  }

  void _checkForDeviation() {
    if (!_isNavigating || _routeCoordinates.isEmpty || _currentPosition == null) {
      return;
    }

    double minDistance = double.infinity;
    for (var coord in _routeCoordinates) {
      final dist = geolocator.Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        coord.lat.toDouble(),
        coord.lng.toDouble(),
      );
      if (dist < minDistance) minDistance = dist;
    }

    // If more than threshold from route, recalculate
    if (minDistance > NavigationConstants.deviationThreshold) {
      _recalculateRoute();
    }
  }

  void _recalculateRoute() async {
    if (!_isNavigating) return;

    HapticFeedback.lightImpact();
    _showError('Recalculating route...', duration: 2);

    await _drawRoute();

    // Reset step index if route changed
    if (_navigationSteps.isNotEmpty && mounted) {
      setState(() => _currentStepIndex = 0);
    }
  }

  void _onArrived() {
    HapticFeedback.heavyImpact();
    _stopNavigation();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Arrived!'),
          ],
        ),
        content: Text('You have arrived at ${_destination?.name ?? "your destination"}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _stopNavigation() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _cameraUpdateTimer?.cancel();
    _cameraUpdateTimer = null;
    _deviationCheckTimer?.cancel();
    _deviationCheckTimer = null;

    if (mounted) {
      setState(() {
        _isNavigating = false;
        _currentStepIndex = 0;
      });

      if (_currentPosition != null) {
        mapboxMap?.flyTo(
          CameraOptions(
            center: Point(
              coordinates: Position(_currentPosition!.longitude, _currentPosition!.latitude),
            ),
            zoom: NavigationConstants.defaultZoom,
            pitch: 0,
            bearing: 0,
          ),
          MapAnimationOptions(duration: 1000),
        );
      }
    }
  }

  void _confirmPinDrop() async {
    if (mapboxMap == null) return;
    final center = await mapboxMap!.getCameraState();

    final newDestination = CampusLocation(
      id: DateTime.now().toIso8601String(),
      name: 'Pinned Location',
      description: 'Custom selected point',
      latitude: center.center.coordinates.lat.toDouble(),
      longitude: center.center.coordinates.lng.toDouble(),
      icon: Icons.push_pin,
    );

    setState(() {
      _destination = newDestination;
      _isPinningMode = false;
    });
    _updateRouteAndMarkers();
    HapticFeedback.mediumImpact();
  }

  IconData _getManeuverIcon(String maneuver) {
    switch (maneuver.toLowerCase()) {
      case 'turn-right':
      case 'right':
        return Icons.turn_right;
      case 'turn-left':
      case 'left':
        return Icons.turn_left;
      case 'straight':
      case 'continue':
        return Icons.straight;
      case 'arrive':
        return Icons.flag;
      case 'depart':
        return Icons.navigation;
      default:
        return Icons.arrow_upward;
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  Future<String?> _getApiToken() async {
    final token = dotenv.env['MAPBOX_ACCESS_TOKEN'];
    if (token == null || token.isEmpty) {
      return null;
    }
    return token;
  }

  void _showError(String message, {SnackBarAction? action, int duration = 4}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: action,
        duration: Duration(seconds: duration),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_isNavigating) {
              _stopNavigation();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(_isNavigating ? 'Navigating' : 'DLSU-D Campus'),
        actions: [
          if (_isGettingLocation)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
          if (_isNavigating)
            TextButton(
              onPressed: _stopNavigation,
              child: const Text(
                'Stop',
                style: TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          MapWidget(
            onMapCreated: _onMapCreated,
            cameraOptions: CameraOptions(
              center: Point(
                coordinates: Position(
                  _currentPosition!.longitude,
                  _currentPosition!.latitude,
                ),
              ),
              zoom: NavigationConstants.defaultZoom,
            ),
          ),
          if (_isNavigating &&
              _navigationSteps.isNotEmpty &&
              _currentStepIndex < _navigationSteps.length)
            _buildNavigationDirectionCard(),
          if (!_isPinningMode && !_isNavigating) _buildRoutePlannerOverlay(),
          if (_isPinningMode) _buildPinningModeUI(),
          if (_routeDuration != null && _routeDistance != null && !_isPinningMode)
            _buildRouteInfoCard(),
          if (_isCalculatingRoute) _buildLoadingOverlay(),
        ],
      ),
      floatingActionButton: _isMapReady && !_isPinningMode
          ? FloatingActionButton(
        onPressed: () {
          double bearing = 0;
          if (_isNavigating &&
              _currentStepIndex < _navigationSteps.length &&
              _currentPosition != null) {
            bearing = geolocator.Geolocator.bearingBetween(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              _navigationSteps[_currentStepIndex].latitude,
              _navigationSteps[_currentStepIndex].longitude,
            );
          }
          mapboxMap?.flyTo(
            CameraOptions(
              center: Point(
                coordinates: Position(
                  _currentPosition!.longitude,
                  _currentPosition!.latitude,
                ),
              ),
              zoom: _isNavigating
                  ? NavigationConstants.navigationZoom
                  : NavigationConstants.defaultZoom,
              pitch: _isNavigating ? NavigationConstants.navigationPitch : 0,
              bearing: bearing,
            ),
            MapAnimationOptions(duration: 1000),
          );
        },
        child: const Icon(Icons.my_location),
      )
          : null,
    );
  }

  Widget _buildLoadingOverlay() {
    return const Positioned.fill(
      child: ColoredBox(
        color: Colors.black26,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Calculating route...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationDirectionCard() {
    final step = _navigationSteps[_currentStepIndex];
    final nextStep = _currentStepIndex + 1 < _navigationSteps.length
        ? _navigationSteps[_currentStepIndex + 1]
        : null;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Card(
          margin: const EdgeInsets.all(12),
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getManeuverIcon(step.maneuver),
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDistance(_distanceToNextStep),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            step.instruction,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (nextStep != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Text(
                        'Then ',
                        style: TextStyle(color: Colors.grey),
                      ),
                      Icon(
                        _getManeuverIcon(nextStep.maneuver),
                        size: 20,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          nextStep.instruction,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinningModeUI() {
    return Stack(
      children: [
        const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.place, size: 40, color: Colors.red),
              SizedBox(height: 8),
              Text(
                'Drag the map to position the pin',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 32,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => setState(() => _isPinningMode = false),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                ),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _confirmPinDrop,
                child: const Text('Confirm Destination'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoutePlannerOverlay() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0, left: 4.0),
                      child: Text(
                        'Your Location',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    _buildLocationDisplay(),
                    const Divider(height: 1),
                    const Padding(
                      padding: EdgeInsets.only(top: 8.0, left: 4.0),
                      child: Text(
                        'Destination',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildLocationSelector(
                            location: _destination,
                            onTap: () {
                              if (_isMapReady) _showLocationSelection();
                            },
                          ),
                        ),
                        if (_destination != null)
                          IconButton(
                            onPressed: () {
                              setState(() {
                                _destination = null;
                                _routeDistance = null;
                                _routeDuration = null;
                                _navigationSteps = [];
                                _routeCoordinates = [];
                              });
                              polylineAnnotationManager?.deleteAll();
                              pointAnnotationManager?.deleteAll();
                            },
                            icon: const Icon(Icons.clear),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          const Icon(Icons.my_location, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _currentLocationName,
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteInfoCard() {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoColumn(
                    Icons.directions_walk,
                    '${_routeDuration?.toStringAsFixed(0)} min',
                    'Duration',
                  ),
                  _buildInfoColumn(
                    Icons.map,
                    '${_routeDistance?.toStringAsFixed(2)} km',
                    'Distance',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (!_isNavigating)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _navigationSteps.isNotEmpty ? _startNavigation : null,
                    icon: const Icon(Icons.navigation),
                    label: const Text('Start Navigation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _stopNavigation,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop Navigation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.green, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSelector({
    CampusLocation? location,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(
              Icons.place,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                location?.name ?? "Select destination",
                style: TextStyle(
                  color: _isMapReady ? Colors.black : Colors.grey,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        builder: (BuildContext context, ScrollController scrollController) {
          return LocationSearchSheet(
            proximity: _currentPosition,
            allCampusLocations: _allLocations,
            onLocationSelected: (location) {
              final wasNavigating = _isNavigating;
              if (wasNavigating) {
                _positionSubscription?.cancel();
              }

              setState(() {
                _destination = location;
                _isNavigating = false;
                _currentStepIndex = 0;
                _navigationSteps = [];
                _routeCoordinates = [];
              });

              Navigator.pop(context);

              // Update route and wait for completion before restarting navigation
              _updateRouteAndMarkers();

              if (wasNavigating) {
                // Delay to allow route calculation to complete
                Future.delayed(const Duration(milliseconds: 2000), () {
                  if (_navigationSteps.isNotEmpty && mounted) {
                    _startNavigation();
                  }
                });
              }
            },
            onSelectOnMap: () {
              Navigator.pop(context);
              setState(() => _isPinningMode = true);
            },
          );
        },
      ),
    );
  }
}

class LocationSearchSheet extends StatefulWidget {
  final Function(CampusLocation) onLocationSelected;
  final VoidCallback onSelectOnMap;
  final geolocator.Position? proximity;
  final List<CampusLocation> allCampusLocations;

  const LocationSearchSheet({
    super.key,
    required this.onLocationSelected,
    required this.onSelectOnMap,
    this.proximity,
    required this.allCampusLocations,
  });

  @override
  State<LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<LocationSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchResults = widget.allCampusLocations;
    _searchController.addListener(() => _onSearchChanged(_searchController.text));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Immediate search for local results
    if (query.isEmpty) {
      setState(() => _searchResults = widget.allCampusLocations);
      return;
    }

    final localResults = widget.allCampusLocations
        .where((loc) => loc.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    setState(() => _searchResults = localResults);

    // Debounced API search
    _debounce = Timer(
      const Duration(milliseconds: NavigationConstants.searchDebounceMs),
          () => _performAPISearch(query),
    );
  }

  Future<void> _performAPISearch(String query) async {
    if (query.length < 3) return;

    setState(() => _isLoading = true);

    List<dynamic> combinedResults = List.from(_searchResults);

    final String? accessToken = dotenv.env['MAPBOX_ACCESS_TOKEN'];
    if (accessToken != null && accessToken.isNotEmpty) {
      final proximityStr = widget.proximity != null
          ? '&proximity=${widget.proximity!.longitude},${widget.proximity!.latitude}'
          : '';

      final url = 'https://api.mapbox.com/geocoding/v5/mapbox.places/$query.json'
          '?access_token=$accessToken$proximityStr';

      try {
        final response = await http.get(Uri.parse(url)).timeout(
          const Duration(seconds: NavigationConstants.apiTimeoutSeconds),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final features = data['features'] as List;
          combinedResults.addAll(
            features.map((f) => f as Map<String, dynamic>).toList(),
          );
        }
      } on TimeoutException {
        // Silently handle timeout, show local results only
      } catch (e) {
        // Silently handle other errors
      }
    }

    if (mounted) {
      setState(() {
        _searchResults = combinedResults;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'Select Destination',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.push_pin, color: Colors.blue),
            title: const Text('Select a point on the map'),
            onTap: widget.onSelectOnMap,
            tileColor: Colors.blue.withOpacity(0.05),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search locations...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isLoading
                  ? const Padding(
                padding: EdgeInsets.all(12.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _searchResults.isEmpty
                ? const Center(
              child: Text(
                'No locations found',
                style: TextStyle(color: Colors.grey),
              ),
            )
                : ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final result = _searchResults[index];
                if (result is CampusLocation) {
                  return ListTile(
                    leading: Icon(result.icon, color: Colors.green),
                    title: Text(result.name),
                    subtitle: Text(result.description),
                    onTap: () => widget.onLocationSelected(result),
                  );
                } else if (result is Map<String, dynamic>) {
                  final coords = result['center'] as List<dynamic>?;
                  return ListTile(
                    leading: const Icon(Icons.place, color: Colors.grey),
                    title: Text(result['text'] ?? ''),
                    subtitle: Text(result['place_name'] ?? ''),
                    onTap: () {
                      if (coords != null && coords.length >= 2) {
                        widget.onLocationSelected(
                          CampusLocation(
                            id: result['id'] ?? DateTime.now().toIso8601String(),
                            name: result['text'] ?? '',
                            description: result['place_name'] ?? '',
                            latitude: coords[1].toDouble(),
                            longitude: coords[0].toDouble(),
                            icon: Icons.place,
                          ),
                        );
                      }
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}