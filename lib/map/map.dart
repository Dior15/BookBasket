import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import 'reading_marker.dart';
import '../auth_service.dart';
import '../firebase_database/firebase_db.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  List<ReadingMarker> _markers = [];
  LatLng? _currentPosition;
  String? _currentUserEmail;

  final MapController _mapController = MapController();
  final List<StreamSubscription<List<ReadingMarker>>> _markerSubscriptions = [];
  AnimationController? _cameraAnimationController;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _listenToCommunalMarkers();
  }

  @override
  void dispose() {
    _stopCameraAnimation();
    for (var sub in _markerSubscriptions) {
      sub.cancel();
    }
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.low,
    );
    if (!mounted) return;
    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
    });

    _mapController.move(_currentPosition!, 13.0);
  }

  void _stopCameraAnimation() {
    _cameraAnimationController?.stop();
    _cameraAnimationController?.dispose();
    _cameraAnimationController = null;
  }

  void _animateCameraTransition({
    LatLng? targetCenter,
    double? targetZoom,
    double? targetRotation,
    Duration duration = const Duration(milliseconds: 600),
    Curve curve = Curves.easeInOutCubic,
  }) {
    final camera = _mapController.camera;
    final startCenter = camera.center;
    final endCenter = targetCenter ?? startCenter;

    final startZoom = camera.zoom;
    final endZoom = targetZoom ?? startZoom;

    final startRotation = camera.rotation;
    final endRotation = targetRotation ?? startRotation;

    final shouldAnimate = startCenter.latitude != endCenter.latitude ||
        startCenter.longitude != endCenter.longitude ||
        startZoom != endZoom ||
        startRotation != endRotation;
    if (!shouldAnimate) return;

    _stopCameraAnimation();
    final controller = AnimationController(vsync: this, duration: duration);
    final animation = CurvedAnimation(parent: controller, curve: curve);
    _cameraAnimationController = controller;

    controller.addListener(() {
      final t = animation.value;
      final animatedCenter = LatLng(
        startCenter.latitude + (endCenter.latitude - startCenter.latitude) * t,
        startCenter.longitude + (endCenter.longitude - startCenter.longitude) * t,
      );
      final animatedZoom = startZoom + (endZoom - startZoom) * t;
      final animatedRotation = startRotation + (endRotation - startRotation) * t;

      _mapController.moveAndRotate(animatedCenter, animatedZoom, animatedRotation);
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        if (_cameraAnimationController == controller) {
          controller.dispose();
          _cameraAnimationController = null;
        }
      }
    });

    controller.forward();
  }

  void _resetMapToNorth() {
    _animateCameraTransition(
      targetRotation: 0.0,
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeInOutCubic,
    );
  }

  void _recenterToCurrentLocation() {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current location is unavailable.')),
      );
      return;
    }

    _animateCameraTransition(
      targetCenter: _currentPosition!,
      targetZoom: _mapController.camera.zoom,
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _listenToCommunalMarkers() async {
    try {
      _currentUserEmail = await AuthService.getEmail() ?? AuthService.userEmail;
      if (_currentUserEmail == null) return;

      final db = FirebaseDB.getReference();
      List<String> friends = await db.getFriendEmails(_currentUserEmail!);
      List<String> communalNetwork = [_currentUserEmail!, ...friends];

      for (String user in communalNetwork) {
        var sub = db.getUserMarkersStream(user).listen((userMarkers) {
          if (!mounted) return;
          setState(() {
            _markers.removeWhere((m) => m.username == user);
            _markers.addAll(userMarkers);
          });
        });
        _markerSubscriptions.add(sub);
      }
    } catch (e) {
      debugPrint("Error initializing communal markers: $e");
    }
  }

  // --- NEW: Method to show the list of markers ---
  void _showMarkerList() {
    // 1. Separate the lists
    final myMarkers = _markers.where((m) => m.username == _currentUserEmail).toList();
    final friendMarkers = _markers.where((m) => m.username != _currentUserEmail).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                    ),
                  ),
                ),

                // --- User's Markers ---
                if (myMarkers.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text("Your Reading Spots", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  ...myMarkers.map((m) => _buildMarkerTile(m, true)),
                  const Divider(),
                ],

                // --- Friends' Markers ---
                if (friendMarkers.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text("Friends' Reading Spots", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  ...friendMarkers.map((m) => _buildMarkerTile(m, false)),
                ],

                // --- Empty State ---
                if (myMarkers.isEmpty && friendMarkers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Text("No markers found yet! Start reading to add some.", textAlign: TextAlign.center),
                    ),
                  )
              ],
            );
          },
        );
      },
    );
  }

  // --- NEW: Helper to build the list tiles ---
// --- NEW: Helper to build the list tiles ---
  Widget _buildMarkerTile(ReadingMarker marker, bool isMine) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (isMine ? Colors.redAccent : Colors.deepPurple).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.location_on, color: isMine ? Colors.redAccent : Colors.deepPurple),
      ),
      title: Text(isMine ? "You read here" : "${marker.username} read here", style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(marker.bookTitles.join(", "), maxLines: 2, overflow: TextOverflow.ellipsis),

      // CHANGED: Show a delete button for the user's markers, and the chevron for friends
      trailing: isMine
          ? IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
        onPressed: () async {
          // 1. Close the bottom sheet immediately for a snappy UI
          Navigator.pop(context);

          // 2. Call your existing Firebase logic to delete the marker
          await FirebaseDB.getReference().deleteUserMarker(_currentUserEmail!, marker);

          // 3. Let the user know it was successful (The map stream will auto-remove the marker icon!)
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Reading spot removed.")),
            );
          }
        },
      )
          : const Icon(Icons.chevron_right, color: Colors.grey),

      onTap: () {
        // Close the bottom sheet and pan to the marker
        Navigator.pop(context);
        _animateCameraTransition(
          targetCenter: LatLng(marker.latitude, marker.longitude),
          targetZoom: 15.0,
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeInOutCubic,
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'compass_fab',
            tooltip: 'Reset to North',
            onPressed: _resetMapToNorth,
            child: const Icon(Icons.explore),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.small(
            heroTag: 'recenter_fab',
            tooltip: 'Recenter to My Location',
            onPressed: _recenterToCurrentLocation,
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.small(
            heroTag: 'marker_list_fab',
            tooltip: 'View Marker List',
            onPressed: _showMarkerList,
            child: const Icon(Icons.place),
          ),
        ],
      ),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _currentPosition!,
          initialZoom: 13.0,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'com.example.bookbasket',
          ),
          MarkerLayer(
            markers: _markers.map((marker) {
              bool isMyMarker = marker.username == _currentUserEmail;

              return Marker(
                point: LatLng(marker.latitude, marker.longitude),
                width: 60,
                height: 60,
                child: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(isMyMarker ? "You read here:" : "${marker.username} read here:"),
                        content: SizedBox(
                          width: double.maxFinite,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: marker.bookTitles.length,
                            itemBuilder: (context, idx) {
                              return ListTile(
                                leading: const Icon(Icons.book, color: Colors.blueAccent),
                                title: Text(marker.bookTitles[idx]),
                              );
                            },
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Close"),
                          )
                        ],
                      ),
                    );
                  },
                  child: Icon(
                    Icons.location_on,
                    color: isMyMarker ? Colors.redAccent : Colors.deepPurple,
                    size: 45,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}