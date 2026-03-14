import 'dart:async'; // NEW: Required for the Timer
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

import 'reading_marker.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  List<ReadingMarker> _markers = [];
  LatLng? _currentPosition;

  final MapController _mapController = MapController();

  // NEW: Timer and tracking variables for live-updating
  Timer? _pollingTimer;
  String _lastDataHash = "";

  @override
  void initState() {
    super.initState();
    _loadMarkers();
    _getCurrentLocation();

    // NEW: Check for new background markers every 2 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _loadMarkers();
    });
  }

  @override
  void dispose() {
    // NEW: Always cancel timers when leaving the page to prevent memory leaks!
    _pollingTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadMarkers() async {
    final prefs = await SharedPreferences.getInstance();
    final markerStrings = prefs.getStringList('reading_markers') ?? [];

    // NEW: Create a simple string out of the saved data to see if it changed
    final currentHash = markerStrings.join();

    // NEW: Only trigger a UI rebuild if a background task actually added a new marker
    if (currentHash != _lastDataHash && mounted) {
      setState(() {
        _lastDataHash = currentHash;
        _markers = markerStrings
            .map((m) => ReadingMarker.fromJson(m))
            .toList();
      });
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

  Future<void> _deleteMarker(int index) async {
    setState(() {
      _markers.removeAt(index);
    });

    final prefs = await SharedPreferences.getInstance();
    final updatedMarkerStrings = _markers.map((m) => m.toJson()).toList();
    await prefs.setStringList('reading_markers', updatedMarkerStrings);

    // Update the hash so the polling timer doesn't instantly undo our delete
    _lastDataHash = updatedMarkerStrings.join();
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
                    ? const Center(child: Text("No markers yet. Read some books!"))
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