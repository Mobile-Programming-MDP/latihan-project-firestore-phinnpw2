import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapsScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  const GoogleMapsScreen(
      {super.key, required this.latitude, required this.longitude});

  @override
  State<GoogleMapsScreen> createState() => _GoogleMapsScreenState();
}

class _GoogleMapsScreenState extends State<GoogleMapsScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  late CameraPosition _cameraPosition;
  late Set<Marker> _markers;
  late MarkerId _markerId;
  @override
  void initState() {
    super.initState();
    _cameraPosition = CameraPosition(
      target: LatLng(
        widget.latitude,
        widget.longitude,
      ),
      zoom: 15,
    );
    _markers = {};
    _markerId =
        MarkerId(widget.latitude.toString() + widget.longitude.toString());
    _markers.add(Marker(
        markerId: _markerId,
        position: LatLng(widget.latitude, widget.longitude),
        infoWindow: const InfoWindow(
          title: "Your Location",
          snippet: "Your current location is here",
        )));
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Google Map"),
      ),
      body: GoogleMap(
        markers: _markers,
        myLocationButtonEnabled: true,
        myLocationEnabled: true,
        initialCameraPosition: _cameraPosition,
        mapType: MapType.normal,
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
          Future.delayed(const Duration(milliseconds: 500), () {
            controller.showMarkerInfoWindow(_markerId);
          });
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _gotoLocation,
        label: const Text("To Your Locarion"),
        icon: Icon(Icons.directions),
      ),
    );
  }

  Future<void> _gotoLocation() async {
    final GoogleMapController controller = await _controller.future;
    await controller
        .animateCamera(CameraUpdate.newCameraPosition(_cameraPosition));
  }
}
