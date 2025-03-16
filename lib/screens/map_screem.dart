import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_directions_api/google_directions_api.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  LatLng? _currentPosition;
  final String _googleApiKey = 'AIzaSyCx6zCRlfgXp3ur-AjiJCJUHdrlahf--as';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('Location permission denied by user');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        print('Location permission denied forever');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: _currentPosition!,
            infoWindow: const InfoWindow(title: 'Your Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          ),
        );
        _loadMarkers(); // Load random markers after getting position
      });

      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition!, 15),
      );
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _loadMarkers() {
    if (_currentPosition == null) return;

    setState(() {
      _markers.clear(); // to clear existing markers except current location
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentPosition!,
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );

      // Generate 7 random points near the current location
      final randomPoints = _generateRandomPoints(_currentPosition!, 7, 500); // 500 meters radius
      _markers.addAll(
        randomPoints.asMap().entries.map((entry) {
          int index = entry.key;
          LatLng point = entry.value;
          return Marker(
            markerId: MarkerId('random_$index'),
            position: point,
            infoWindow: InfoWindow(
              title: 'Nearby Point ${index + 1}',
              snippet: 'Lat: ${point.latitude.toStringAsFixed(4)}, Lng: ${point.longitude.toStringAsFixed(4)}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            onTap: () {
              _showMarkerOptions(point);
            },
          );
        }).toSet(),
      );
    });
  }

  List<LatLng> _generateRandomPoints(LatLng center, int count, double maxDistanceMeters) {
    final random = Random();
    final List<LatLng> points = [];

    // Earth's radius in meters
    const double earthRadius = 6371000;

    for (int i = 0; i < count; i++) {
      // Random distance (up to maxDistanceMeters) and angle
      final distance = random.nextDouble() * maxDistanceMeters;
      final angle = random.nextDouble() * 2 * pi;

      // Convert distance to radians (distance / earth's radius)
      final distanceInRadians = distance / earthRadius;

      // Current position in radians
      final latRad = center.latitude * pi / 180;
      final lngRad = center.longitude * pi / 180;

      // Calculate new latitude
      final newLatRad = asin(
        sin(latRad) * cos(distanceInRadians) +
            cos(latRad) * sin(distanceInRadians) * cos(angle),
      );
      final newLngRad = lngRad +
          atan2(
            sin(angle) * sin(distanceInRadians) * cos(latRad),
            cos(distanceInRadians) - sin(latRad) * sin(newLatRad),
          );

      // Convert back to degrees
      final newLat = newLatRad * 180 / pi;
      final newLng = newLngRad * 180 / pi;

      points.add(LatLng(newLat, newLng));
    }

    return points;
  }

  Future<void> _launchDirections(LatLng destination) async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current location not available')),
      );
      return;
    }

    final startLat = _currentPosition!.latitude;
    final startLng = _currentPosition!.longitude;
    final endLat = destination.latitude;
    final endLng = destination.longitude;

    final googleMapsUrl = Uri.parse(
      'google.maps://?saddr=$startLat,$startLng&daddr=$endLat,$endLng&directionsmode=driving',
    );
    final fallbackUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=$startLat,$startLng&destination=$endLat,$endLng&travelmode=driving',
    );

    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        if (await canLaunchUrl(fallbackUrl)) {
          await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch Google Maps';
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error launching directions: $e')),
      );
    }
  }

  void _showMarkerOptions(LatLng destination) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Options'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _drawRoute(_currentPosition!, destination);
            },
            child: const Text('Show Route on Map'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _launchDirections(destination);
            },
            child: const Text('Open in Google Maps'),
          ),
        ],
      ),
    );
  }

  Future<void> _drawRoute(LatLng origin, LatLng destination) async {
    DirectionsService.init(_googleApiKey);
    final directionsService = DirectionsService();
    try {
      final request = DirectionsRequest(
        origin: '${origin.latitude},${origin.longitude}',
        destination: '${destination.latitude},${destination.longitude}',
        travelMode: TravelMode.driving,
      );
      await directionsService.route(request, (DirectionsResult result, DirectionsStatus? status) {
        if (status == DirectionsStatus.ok) {
          final route = result.routes![0];
          final points = _decodePolyline(route.overviewPolyline!.points ?? "");
          setState(() {
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('navigation_route'),
                points: points,
                color: Colors.blue,
                width: 5,
              ),
            );
          });
          _controller.future.then((GoogleMapController controller) {
            controller.animateCamera(
              CameraUpdate.newLatLngBounds(
                _createLatLngBounds(origin, destination, points),
                50.0,
              ),
            );
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $status - ${result.errorMessage}')),
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error drawing route: $e')),
      );
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
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

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  LatLngBounds _createLatLngBounds(LatLng origin, LatLng destination, List<LatLng> points) {
    double minLat = origin.latitude, maxLat = origin.latitude;
    double minLng = origin.longitude, maxLng = origin.longitude;

    for (LatLng point in points) {
      minLat = min(minLat, point.latitude);
      maxLat = max(maxLat, point.latitude);
      minLng = min(minLng, point.longitude);
      maxLng = max(maxLng, point.longitude);
    }
    minLat = min(minLat, destination.latitude);
    maxLat = max(maxLat, destination.latitude);
    minLng = min(minLng, destination.longitude);
    maxLng = max(maxLng, destination.longitude);

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _currentPosition!,
          zoom: 15,
        ),
        markers: _markers,
        polylines: _polylines,
        myLocationEnabled: true,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
      ),
    );
  }
}