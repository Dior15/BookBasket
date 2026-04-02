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

class _MapPageState extends State<MapPage> {
  List<ReadingMarker> _markers = [];
  LatLng? _currentPosition;

  final MapController _mapController = MapController();

  // NEW: A subscription to keep our stream open
  StreamSubscription<List<ReadingMarker>>? _markerSubscription;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _listenToMarkers(); // NEW: Start the stream
  }

  @override
  void dispose() {
    // NEW: Always close the valve when you leave the page!
    _markerSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  // --- NEW: The Live Stream Listener ---
  Future<void> _listenToMarkers() async {
    try {
      final email = await AuthService.getEmail() ?? AuthService.userEmail;
      final db = FirebaseDB.getReference();

      // We subscribe to the stream. Every time the cloud data changes,
      // this block of code will automatically run and update the UI.
      _markerSubscription = db.getUserMarkersStream(email).listen((cloudMarkers) {
        if (mounted) {
          setState(() {
            _markers = cloudMarkers;
          });
        }
      });
    } catch (e) {
      debugPrint("Error listening to marker stream: $e");
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _currentPosition = const LatLng(43.8971, -78.9429));
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      if (mounted) setState(() => _currentPosition = const LatLng(43.8971, -78.9429));
    }
  }

  // --- UPDATED: Delete marker ---
  Future<void> _deleteMarker(int index) async {
    final markerToDelete = _markers[index];

    try {
      final email = await AuthService.getEmail() ?? AuthService.userEmail;
      final db = FirebaseDB.getReference();

      // All we have to do is tell Firebase to delete it.
      await db.deleteUserMarker(email, markerToDelete);

      // NOTE: We don't even need to call setState to remove it from the list!
      // Because we are using a Stream, Firebase will instantly notice the deletion
      // and push the new, updated list back down our _markerSubscription pipe!
    } catch (e) {
      debugPrint("Error deleting cloud marker: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentPosition == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Reading Map",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,

      endDrawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "My Markers",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),
              Expanded(
                child: _markers.isEmpty
                    ? const Center(child: Text("No markers yet."))
                    : ListView.builder(
                  itemCount: _markers.length,
                  itemBuilder: (context, index) {
                    final marker = _markers[index];

                    String displayTitle = marker.bookTitles.isNotEmpty
                        ? marker.bookTitles.first
                        : "Unknown Book";

                    if (marker.bookTitles.length > 1) {
                      displayTitle += " (+${marker.bookTitles.length - 1})";
                    }

                    return ListTile(
                      leading: const Icon(Icons.location_on, color: Colors.redAccent),
                      title: Text(
                        "Marker ${index + 1}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        "Lat: ${marker.latitude.toStringAsFixed(4)}\nLng: ${marker.longitude.toStringAsFixed(4)}",
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _deleteMarker(index),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _mapController.move(
                            LatLng(marker.latitude, marker.longitude),
                            16.0
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _currentPosition!,
          initialZoom: 16.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.bookbasket',
          ),
          MarkerLayer(
            markers: _markers.map((marker) {
              return Marker(
                point: LatLng(marker.latitude, marker.longitude),
                width: 45,
                height: 45,
                child: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Books read here:"),
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
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.redAccent,
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