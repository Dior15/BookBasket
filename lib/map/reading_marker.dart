import 'dart:convert';

class ReadingMarker {
  final String username; // NEW: Track who owns the marker
  final List<String> bookTitles;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  ReadingMarker({
    this.username = "Unknown User", // Safe default for old existing markers
    required this.bookTitles,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'bookTitles': bookTitles,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ReadingMarker.fromMap(Map<String, dynamic> map) {
    // Backward compatibility: If the old single 'bookTitle' string exists, convert it to a list
    List<String> titles = [];
    if (map['bookTitles'] != null) {
      titles = List<String>.from(map['bookTitles']);
    } else if (map['bookTitle'] != null) {
      titles = [map['bookTitle']];
    }

    return ReadingMarker(
      username: map['username'] ?? 'Unknown User', // Grabs the username injected by Firebase!
      bookTitles: titles,
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  String toJson() => json.encode(toMap());

  factory ReadingMarker.fromJson(String source) => ReadingMarker.fromMap(json.decode(source));
}