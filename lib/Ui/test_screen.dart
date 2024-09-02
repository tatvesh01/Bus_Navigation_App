import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/services.dart';

// this page only for testing purpose
class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _controller;
  List<LatLng> _route = [
    LatLng(37.77483, -122.41942),
    LatLng(37.77493, -122.41842),
    LatLng(37.77503, -122.41742),
    LatLng(37.77513, -122.41642),
    LatLng(37.77523, -122.41542),
    // Add more points to complete the route
  ];

  LatLng _currentPosition = LatLng(37.77483, -122.41942);
  BitmapDescriptor? _carIcon;
  Timer? _timer;
  int _currentIndex = 0;
  double _animationFraction = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCustomMarker();
    _startCarAnimation();
  }

  void _loadCustomMarker() async {
    _carIcon = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(size: Size(48, 48)),
      'assets/car_icon.png',
    );
  }

  void _startCarAnimation() {
    _timer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      setState(() {
        if (_animationFraction < 1.0) {
          _animationFraction += 0.01;
        } else {
          _animationFraction = 0.0;
          _currentIndex++;
        }

        if (_currentIndex < _route.length - 1) {
          LatLng interpolatedPosition = interpolate(
              _route[_currentIndex],
              _route[_currentIndex + 1],
              _animationFraction
          );

          // Snap to the closest point on the polyline
          _currentPosition = findClosestPoint(interpolatedPosition, _route);
        } else {
          _timer?.cancel(); // Stop the animation when the route ends
        }
      });

      _controller?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentPosition,
            zoom: 16.0,
          ),
        ),
      );
    });
  }

  LatLng interpolate(LatLng start, LatLng end, double fraction) {
    double lat = (end.latitude - start.latitude) * fraction + start.latitude;
    double lng = (end.longitude - start.longitude) * fraction + start.longitude;
    return LatLng(lat, lng);
  }

  LatLng findClosestPoint(LatLng carPosition, List<LatLng> polyline) {
    LatLng closestPoint = polyline[0];
    double minDistance = double.infinity;

    for (int i = 0; i < polyline.length - 1; i++) {
      LatLng start = polyline[i];
      LatLng end = polyline[i + 1];
      LatLng projectedPoint = _projectPointOntoSegment(carPosition, start, end);
      double distance = _calculateDistance(carPosition, projectedPoint);

      if (distance < minDistance) {
        minDistance = distance;
        closestPoint = projectedPoint;
      }
    }

    return closestPoint;
  }

  LatLng _projectPointOntoSegment(LatLng point, LatLng segmentStart, LatLng segmentEnd) {
    double dx = segmentEnd.longitude - segmentStart.longitude;
    double dy = segmentEnd.latitude - segmentStart.latitude;

    if (dx == 0 && dy == 0) {
      return segmentStart;
    }

    double t = ((point.longitude - segmentStart.longitude) * dx + (point.latitude - segmentStart.latitude) * dy) /
        (dx * dx + dy * dy);

    t = max(0, min(1, t));

    return LatLng(segmentStart.latitude + t * dy, segmentStart.longitude + t * dx);
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    double lat1 = point1.latitude;
    double lon1 = point1.longitude;
    double lat2 = point2.latitude;
    double lon2 = point2.longitude;

    double p = 0.017453292519943295; // Pi/180
    double a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) *
            (1 - cos((lon2 - lon1) * p)) / 2;

    return 12742 * asin(sqrt(a)); // 2 * R * asin
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Car Animation on Road"),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _route[0],
          zoom: 16.0,
        ),
        markers: {
          Marker(
            markerId: MarkerId("car"),
            position: _currentPosition,
            icon: _carIcon ?? BitmapDescriptor.defaultMarker,
          ),
        },
        polylines: {
          Polyline(
            polylineId: PolylineId("route"),
            points: _route,
            color: Colors.blue,
            width: 5,
          ),
        },
        onMapCreated: (GoogleMapController controller) {
          _controller = controller;
        },
      ),
    );
  }
}