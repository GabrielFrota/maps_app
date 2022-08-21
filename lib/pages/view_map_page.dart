import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_app/utils.dart';

import '../models/place.dart';
import '../models/user_map.dart';


class ViewMapPage extends StatefulWidget {
  ViewMapPage({Key? key, int? userMapId, String? userMapTitle}) : super(key: key) {
    if (userMapId != null) {
      _userMapFut = UserMapService.findById(userMapId);
    } else if (userMapTitle != null) {
      _userMapFut = UserMapService.insert(UserMap(userMapTitle));
    } else {
      throw ArgumentError();
    }
  }
  late final Future<UserMap> _userMapFut;

  @override
  State<ViewMapPage> createState() => _ViewMapPageState();
}

class _ViewMapPageState extends State<ViewMapPage> {
  late final int _userMapId;
  late final GoogleMapController _controller;
  late final Set<Marker> _markers;
  MarkerId? _lastMark;

  @override
  void initState() {
    super.initState();
    _markers = {};
    widget._userMapFut.then((u) {
      _userMapId = u.id!;
      for (var p in u.places!) {
        _markers.add(_placeToMarker(p));
      }
    });
  }

  Marker _placeToMarker(Place p) {
    final mId = MarkerId(p.title);
    late Marker m;
    m = Marker(markerId: mId, position: LatLng(p.latitude, p.longitude),
        onTap: () => _lastMark = mId,
        infoWindow: InfoWindow(
          title: p.title,
          snippet: p.description,
          onTap: () {
            PlaceService.delete(p.id!);
            setState(() {
              _lastMark = null;
              _markers.remove(m);
            });
          },
        ));
    return m;
  }

  void _onMapCreated (GoogleMapController controller) {
    _controller = controller;
    if (_markers.length == 0)
      return;
    if (_markers.length == 1) {
      final ll = LatLng(_markers.single.position.latitude, _markers.single.position.longitude);
      _controller.moveCamera(CameraUpdate.newLatLngZoom(ll, 5));
      return;
    }

    var minLat = double.maxFinite;
    var maxLat = double.negativeInfinity;
    var minLong = double.maxFinite;
    var maxLong = double.negativeInfinity;
    for (var m in _markers) {
      final lat = m.position.latitude;
      if (lat < minLat) minLat = lat;
      if (lat > maxLat) maxLat = lat;
      final long = m.position.longitude;
      if (long < minLong) minLong = long;
      if (long > maxLong) maxLong = long;
    }
    final b = LatLngBounds(southwest: LatLng(minLat, minLong), northeast: LatLng(maxLat, maxLong));
    _controller.moveCamera(CameraUpdate.newLatLngBounds(b, 40));
  }

  void _onLongPress(LatLng ll) async {
    if (_lastMark != null) {
      final shown = await _controller.isMarkerInfoWindowShown(_lastMark!);
      if (shown) _controller.hideMarkerInfoWindow(_lastMark!);
    }
    showDialog<void>(context: context, builder: (context) {
      final formKey = GlobalKey<FormState>();
      String title = '';
      String snippet = '';
      return AlertDialog(
          title: const Text('Add new marker'),
          insetPadding: const EdgeInsets.symmetric(horizontal: 40.0),
          titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <TextFormField>[
                TextFormField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'title',
                    ),
                    onChanged: (val) => title = val,
                    validator: Utils.emptyCheck
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'snippet',
                  ),
                  onChanged: (val) => snippet = val,
                  validator: Utils.emptyCheck,
                )
              ],
            ),
          ),
          actions: <TextButton>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final p = Place(title, snippet, ll.latitude,
                      ll.longitude, _userMapId);
                  PlaceService.insert(p).then((pp) {
                    setState(() {
                      _markers.add(_placeToMarker(pp));
                    });
                  });
                  Navigator.pop(context);
                  _controller.moveCamera(CameraUpdate
                      .newLatLng(LatLng(ll.latitude, ll.longitude)));
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: widget._userMapFut,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(child: CircularProgressIndicator());
          }
          return GoogleMap(
            initialCameraPosition: const CameraPosition(target: LatLng(0, 0)),
            onMapCreated: _onMapCreated,
            markers: _markers,
            onLongPress: _onLongPress
          );
        }
      )
    );
  }
}