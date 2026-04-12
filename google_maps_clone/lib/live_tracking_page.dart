import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_clone/constants.dart';
import 'package:google_maps_clone/components/rider_info.dart';

class LiveTrackingPage extends StatefulWidget {
  const LiveTrackingPage({super.key});

  @override
  State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage> {
  final LatLng sourceLocation = const LatLng(37.33500926, -122.03272188);
  final LatLng destinationLocation = const LatLng(37.33429383, -122.06600055);

  final Completer<GoogleMapController> _controller = Completer();

  List<LatLng> polylineCoordinates = [];
  LatLng? currentLocation;

  BitmapDescriptor sourceIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor destinationIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor currentLocationIcon = BitmapDescriptor.defaultMarker;

  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    setCustomMarkerIcons();
    getCurrentLocation();
    getPolyPoints();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  void setCustomMarkerIcons() {
    BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(48, 48)),
      "assets/Pin_source.png",
    ).then((icon) => setState(() => sourceIcon = icon));

    BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(48, 48)),
      "assets/Pin_destination.png",
    ).then((icon) => setState(() => destinationIcon = icon));

    BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(48, 48)),
      "assets/Pin_current_location.png",
    ).then((icon) => setState(() => currentLocationIcon = icon));
  }

  Future<void> getCurrentLocation() async {
    // Check if location service is enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Use source location as fallback
      setState(() => currentLocation = sourceLocation);
      return;
    }

    // Check permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => currentLocation = sourceLocation);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => currentLocation = sourceLocation);
      return;
    }

    // Get current position with timeout fallback
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (e) {
      debugPrint('Could not get position: $e');
      // Fallback to source location
      setState(() => currentLocation = sourceLocation);
    }

    // Listen to live position updates
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) async {
      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
      });

      final GoogleMapController mapController = await _controller.future;
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: currentLocation!,
            zoom: 15,
          ),
        ),
      );
    });
  }

  void getPolyPoints() async {
    PolylinePoints polylinePoints = PolylinePoints();
    try {
      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: googleApiKey,
        request: PolylineRequest(
          origin: PointLatLng(
            sourceLocation.latitude,
            sourceLocation.longitude,
          ),
          destination: PointLatLng(
            destinationLocation.latitude,
            destinationLocation.longitude,
          ),
          mode: TravelMode.driving,
        ),
      );

      if (result.points.isNotEmpty) {
        setState(() {
          polylineCoordinates = result.points
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();
        });
      } else {
        debugPrint('Polyline error: ${result.errorMessage}');
      }
    } catch (e) {
      debugPrint('Polyline exception: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: currentLocation == null
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  SizedBox(height: 16),
                  Text(
                    "Getting your location...",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: currentLocation!,
                    zoom: 15,
                  ),
                  onMapCreated: (mapController) {
                    if (!_controller.isCompleted) {
                      _controller.complete(mapController);
                    }
                  },
                  polylines: {
                    if (polylineCoordinates.isNotEmpty)
                      Polyline(
                        polylineId: const PolylineId("route"),
                        points: polylineCoordinates,
                        color: primaryColor,
                        width: 5,
                      ),
                  },
                  markers: {
                    Marker(
                      markerId: const MarkerId("source"),
                      position: sourceLocation,
                      icon: sourceIcon,
                    ),
                    Marker(
                      markerId: const MarkerId("destination"),
                      position: destinationLocation,
                      icon: destinationIcon,
                    ),
                    Marker(
                      markerId: const MarkerId("currentLocation"),
                      position: currentLocation!,
                      icon: currentLocationIcon,
                    ),
                  },
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  myLocationButtonEnabled: false,
                ),

                // Rider info at top
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: RiderInfo(),
                ),

                // Badge bottom right
                Positioned(
                  bottom: 32,
                  right: 16,
                  child: Image.asset(
                    "assets/Badge.png",
                    width: 60,
                    height: 60,
                  ),
                ),
              ],
            ),
    );
  }
}