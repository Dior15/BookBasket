import 'dart:convert';

class ReadingMarker {
  final List<String> bookTitles; // NOW A LIST!
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  ReadingMarker({
    required this.bookTitles,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
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
      bookTitles: titles,
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  String toJson() => json.encode(toMap());

  factory ReadingMarker.fromJson(String source) =>
      ReadingMarker.fromMap(json.decode(source));
}