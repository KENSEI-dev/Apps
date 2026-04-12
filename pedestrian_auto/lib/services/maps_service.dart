import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

class MapsService {
  static const String googleMapsApiKey = 'API key';
  static const String googleMapsBaseUrl = 'https://maps.googleapis.com/maps/api';

  static Future<Position?> getCurrentLocation() async {
    try {
      developer.log('📍 Requesting current location...');
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        developer.log('❌ Location services disabled');
        return null;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        developer.log('❌ Location permission denied');
        return null;
      }
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      developer.log('✅ Location: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      developer.log('❌ Error getting location: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> getDirections({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      final String url = '$googleMapsBaseUrl/directions/json?origin=$startLat,$startLng&destination=$endLat,$endLng&key=$googleMapsApiKey';
      developer.log('📍 Fetching Google Maps directions...');
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];
          developer.log('✅ Directions fetched');
          return {
            'distance': leg['distance']['text'],
            'distance_meters': leg['distance']['value'],
            'duration': leg['duration']['text'],
            'duration_seconds': leg['duration']['value'],
            'polyline': route['overview_polyline']['points'],
            'steps': leg['steps'],
          };
        }
      }
      return {};
    } catch (e) {
      developer.log('❌ Directions error: $e');
      return {};
    }
  }

  static List<LatLng> decodePolyline(String encoded) {
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

      poly.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return poly;
  }
}