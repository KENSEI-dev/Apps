import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'services/api_service.dart';
import 'services/maps_service.dart';
import 'services/websocket_service.dart';
import 'models/route_model.dart';
import 'dart:developer' as developer;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const CrowdMapScreen(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
    );
  }
}

class CrowdMapScreen extends StatefulWidget {
  const CrowdMapScreen({super.key});

  @override
  State<CrowdMapScreen> createState() => CrowdMapScreenState();
}

class CrowdMapScreenState extends State<CrowdMapScreen> {
  late GoogleMapController mapController;
  List<Map<String, dynamic>> stops = [];
  final LatLng kolkataCenter = const LatLng(22.5726, 88.3639);
  bool isLoading = true;
  bool isRoutingMode = false;

  Map<int, int> crowdLevels = {};
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  String selectedPreference = 'comfort';
  AllRoutes? allRoutes;
  LatLng? startLocation;
  LatLng? endLocation;
  bool loadingRoutes = false;

  @override
void initState() {
  super.initState();
  _loadStops();
  _getCurrentLocation();

  // ✅ Wrap in try-catch so WS failure is non-fatal
  try {
    WebSocketService.connect((data) {
      developer.log('📨 WebSocket Update: $data');
      if (!mounted) return;
      setState(() {
        final int stopId = data['stop_id'] as int;
        final int level = data['crowd_level'] as int;
        crowdLevels[stopId] = level;
      });
      _updateMarkers();
    });
  } catch (e) {
    developer.log('⚠️ WebSocket unavailable, continuing without live updates: $e');
  }
}

  @override
  void dispose() {
    WebSocketService.disconnect();
    mapController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      developer.log('📍 Getting current location...');
      final position = await MapsService.getCurrentLocation();
      if (position != null) {
        setState(() {
          startLocation = LatLng(position.latitude, position.longitude);
        });
        developer.log('✅ Current location: $startLocation');
      }
    } catch (e) {
      developer.log('❌ Location error: $e');
    }
  }

  Future<void> _loadStops() async {
    try {
      developer.log('🌐 Loading stops from backend...');
      final stopData = await ApiService.getStops();
      developer.log('📍 Loaded ${stopData.length} stops');

      setState(() {
        stops = List<Map<String, dynamic>>.from(stopData);
        isLoading = false;
        for (var stop in stops) {
          int stopId = stop['id'] as int;
          if (!crowdLevels.containsKey(stopId)) {
            crowdLevels[stopId] = 0;
          }
        }
      });
      _updateMarkers();
    } catch (e) {
      developer.log('❌ Error loading stops: $e');
      setState(() => isLoading = false);
    }
  }

  void _updateMarkers() {
    setState(() {
      markers.clear();
      for (var stop in stops) {
        final int id = stop['id'];
        final int crowdLevel = crowdLevels[id] ?? 0;
        BitmapDescriptor markerColor;
        if (crowdLevel == 0) {
          markerColor = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
        } else if (crowdLevel == 1) {
          markerColor = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);
        } else {
          markerColor = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
        }
        markers.add(
          Marker(
            markerId: MarkerId('stop_$id'),
            position: LatLng(stop['latitude'] as double, stop['longitude'] as double),
            infoWindow: InfoWindow(
              title: stop['name'],
              snippet: 'Crowd: ${_getCrowdLabel(crowdLevel)} - Fare: ₹${stop['base_fare']}',
            ),
            icon: markerColor,
            onTap: () => _showStopOptions(stop),
          ),
        );
      }
      if (startLocation != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('start'),
            position: startLocation!,
            infoWindow: const InfoWindow(title: 'START'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
      }
      if (endLocation != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('end'),
            position: endLocation!,
            infoWindow: const InfoWindow(title: 'END'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
      }
    });
  }

  Future<void> _fetchRoute() async {
    if (startLocation == null || endLocation == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Select start and end locations')),
      );
      return;
    }

    setState(() => loadingRoutes = true);

    try {
      developer.log('🗺️ Fetching Google Maps directions...');
      final directions = await MapsService.getDirections(
        startLat: startLocation!.latitude,
        startLng: startLocation!.longitude,
        endLat: endLocation!.latitude,
        endLng: endLocation!.longitude,
      );

      if (directions.isNotEmpty) {
        final polylinePoints = MapsService.decodePolyline(directions['polyline']);
        setState(() {
          polylines.clear();
          polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: polylinePoints,
              color: _getModeColor(),
              width: 5,
            ),
          );
        });
        developer.log('✅ Route: ${directions['distance']} - ${directions['duration']}');
      }

      final routes = await ApiService.getAllRoutes(
        startLat: startLocation!.latitude,
        startLon: startLocation!.longitude,
        endLat: endLocation!.latitude,
        endLon: endLocation!.longitude,
      );

      if (!mounted) return;
      setState(() {
        allRoutes = AllRoutes.fromJson(routes);
        isRoutingMode = true;
        loadingRoutes = false;
      });
    } catch (e) {
      developer.log('❌ Route error: $e');
      setState(() => loadingRoutes = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Route error: $e')),
      );
    }
  }

  Color _getModeColor() {
    switch (selectedPreference) {
      case 'comfort':
        return Colors.blue;
      case 'budget':
        return Colors.orange;
      case 'fastest':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _getCrowdLabel(int level) {
    switch (level) {
      case 0:
        return 'Empty';
      case 1:
        return 'Moderate';
      case 2:
        return 'Full';
      default:
        return 'Unknown';
    }
  }

  String _getCrowdEmoji(int level) {
    switch (level) {
      case 0:
        return '🟢';
      case 1:
        return '🟡';
      case 2:
        return '🔴';
      default:
        return '⚪';
    }
  }

  void _showStopOptions(Map<String, dynamic> stop) {
    final crowdLevel = crowdLevels[stop['id']] ?? 0;
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        color: Colors.black87,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stop['name'],
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crowd: ${_getCrowdLabel(crowdLevel)} ${_getCrowdEmoji(crowdLevel)}',
                    style: TextStyle(color: Colors.grey[300]),
                  ),
                  Text(
                    'Fare: ₹${stop['base_fare']}',
                    style: TextStyle(color: Colors.grey[300]),
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.location_on, color: Colors.blue),
              title: const Text('Set as Start', style: TextStyle(color: Colors.white)),
              onTap: () {
                setState(() {
                  startLocation = LatLng(stop['latitude'] as double, stop['longitude'] as double);
                });
                _updateMarkers();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on, color: Colors.red),
              title: const Text('Set as End', style: TextStyle(color: Colors.white)),
              onTap: () {
                setState(() {
                  endLocation = LatLng(stop['latitude'] as double, stop['longitude'] as double);
                });
                _updateMarkers();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.directions, color: Colors.green),
              title: const Text('Find Route', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _fetchRoute();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                Expanded(
                  flex: 3,
                  child: GoogleMap(
                    onMapCreated: (controller) {
                      mapController = controller;
                    },
                    initialCameraPosition: CameraPosition(target: kolkataCenter, zoom: 12.0),
                    markers: markers,
                    polylines: polylines,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: true,
                    compassEnabled: true,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: isRoutingMode && allRoutes != null ? _buildRoutePanel() : _buildInfoPanel(),
                ),
              ],
            ),
    );
  }

  Widget _buildRoutePanel() {
    final route = selectedPreference == 'comfort'
        ? allRoutes!.comfort
        : selectedPreference == 'budget'
            ? allRoutes!.budget
            : allRoutes!.fastest;

    return Container(
      color: Colors.black87,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Route Details',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildModeButton('comfort', 'Comfort', Colors.blue),
                const SizedBox(width: 8),
                _buildModeButton('budget', 'Budget', Colors.orange),
                const SizedBox(width: 8),
                _buildModeButton('fastest', 'Fastest', Colors.red),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard('₹${route.fare}', 'Fare', Colors.green),
                      _buildStatCard('${route.estimatedTimeMinutes.toStringAsFixed(0)} min', 'Time', Colors.blue),
                      _buildStatCard('${(route.comfortScore * 100).toStringAsFixed(0)}%', 'Comfort', Colors.purple),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: route.stops.length,
                      itemBuilder: (context, index) {
                        final stop = route.stops[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(color: _getModeColor(), borderRadius: BorderRadius.circular(16)),
                                child: Center(
                                  child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(stop.name, style: const TextStyle(color: Colors.white))),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    isRoutingMode = false;
                    startLocation = null;
                    endLocation = null;
                    allRoutes = null;
                  });
                  _updateMarkers();
                },
                style: ElevatedButton.styleFrom(backgroundColor: _getModeColor()),
                child: const Text('Start Journey'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(String mode, String label, Color color) {
    final isSelected = selectedPreference == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => selectedPreference = mode);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: isSelected ? color : Colors.grey[800], borderRadius: BorderRadius.circular(8)),
          child: Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(8)),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPanel() {
    return Container(
      color: Colors.black87,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'UniMerge 1.0\nGoogle Maps',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const Divider(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📍 ${stops.length} Stops Loaded', style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 16),
                    Text('Tap a stop marker to select start/end points!', style: TextStyle(color: Colors.grey[300])),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _reportCrowdDemo,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('📢 Report Crowd'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _reportCrowdDemo() async {
    try {
      developer.log('📤 Reporting crowd...');
      await ApiService.reportCrowd(stopId: 1, crowdLevel: 2, lat: 22.5726, lon: 88.3639);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Crowd reported!')));
    } catch (e) {
      developer.log('❌ Error: $e');
    }
  }
}