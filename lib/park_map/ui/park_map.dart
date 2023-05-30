import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rxdart/rxdart.dart';

import '../../firestore_refs.dart';
import '../park.dart';

/// Tokyo Station location for demo.
const _tokyoStation = LatLng(35.681236, 139.767125);

/// Geo query geoQueryCondition.
class _GeoQueryCondition {
  _GeoQueryCondition({
    required this.radiusInKm,
    required this.cameraPosition,
  });

  final double radiusInKm;
  final CameraPosition cameraPosition;
}

class ParkMap extends StatefulWidget {
  const ParkMap({super.key});

  @override
  ParkMapState createState() => ParkMapState();
}

/// ParkMap page using [GoogleMap].
class ParkMapState extends State<ParkMap> {
  /// [Marker]s on Google Maps.
  Set<Marker> _markers = {};

  /// [BehaviorSubject] of currently geo query radius and camera position.
  final _geoQueryCondition = BehaviorSubject<_GeoQueryCondition>.seeded(
    _GeoQueryCondition(
      radiusInKm: _initialRadiusInKm,
      cameraPosition: _initialCameraPosition,
    ),
  );

  /// [Stream] of geo query result.
  late final Stream<List<DocumentSnapshot<Park>>> _stream =
      _geoQueryCondition.switchMap(
    (geoQueryCondition) => GeoCollectionReference(parksRef).subscribeWithin(
      center: GeoFirePoint(
        GeoPoint(
          _cameraPosition.target.latitude,
          _cameraPosition.target.longitude,
        ),
      ),
      radiusInKm: geoQueryCondition.radiusInKm,
      field: 'geo',
      geopointFrom: (park) => park.geo.geopoint,
      strictMode: true,
    ),
  );

  /// Updates [_markers] by fetched geo [DocumentSnapshot]s.
  void _updateMarkersByDocumentSnapshots(
    List<DocumentSnapshot<Park>> documentSnapshots,
  ) {
    final markers = <Marker>{};
    for (final ds in documentSnapshots) {
      final id = ds.id;
      final park = ds.data();
      if (park == null) {
        continue;
      }
      final name = park.name;
      final geoPoint = park.geo.geopoint;
      markers.add(_createMarker(id: id, name: name, geoPoint: geoPoint));
    }
    debugPrint('📍 markers count: ${markers.length}');
    setState(() {
      _markers = markers;
    });
  }

  /// Creates a [Marker] by fetched geo location.
  Marker _createMarker({
    required String id,
    required String name,
    required GeoPoint geoPoint,
  }) =>
      Marker(
        markerId: MarkerId('(${geoPoint.latitude}, ${geoPoint.longitude})'),
        position: LatLng(geoPoint.latitude, geoPoint.longitude),
        infoWindow: InfoWindow(title: name),
      );

  /// Current detecting radius in kilometers.
  double get _radiusInKm => _geoQueryCondition.value.radiusInKm;

  /// Current camera position on Google Maps.
  CameraPosition get _cameraPosition => _geoQueryCondition.value.cameraPosition;

  /// Initial geo query detection radius in km.
  static const double _initialRadiusInKm = 1;

  /// Google Maps initial camera zoom level.
  static const double _initialZoom = 14;

  /// Google Maps initial target position.
  static final LatLng _initialTarget = LatLng(
    _tokyoStation.latitude,
    _tokyoStation.longitude,
  );

  /// Google Maps initial camera position.
  static final _initialCameraPosition = CameraPosition(
    target: _initialTarget,
    zoom: _initialZoom,
  );

  @override
  void dispose() {
    _geoQueryCondition.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            initialCameraPosition: _initialCameraPosition,
            onMapCreated: (_) =>
                _stream.listen(_updateMarkersByDocumentSnapshots),
            markers: _markers,
            circles: {
              Circle(
                circleId: const CircleId('value'),
                center: LatLng(
                  _cameraPosition.target.latitude,
                  _cameraPosition.target.longitude,
                ),
                // multiple 1000 to convert from kilometers to meters.
                radius: _radiusInKm * 1000,
                fillColor: Colors.black12,
                strokeWidth: 0,
              ),
            },
            onCameraMove: (cameraPosition) {
              debugPrint('📷 lat: ${cameraPosition.target.latitude}, '
                  'lng: ${cameraPosition.target.latitude}');
              _geoQueryCondition.add(
                _GeoQueryCondition(
                  radiusInKm: _radiusInKm,
                  cameraPosition: cameraPosition,
                ),
              );
            },
          ),
          Positioned(
            right: 8,
            top: 8,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                _ActionButton(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  iconData: Icons.exit_to_app,
                ),
                const SizedBox(height: 8),
                _ActionButton(
                  onPressed: () {},
                  iconData: Icons.zoom_in_map,
                ),
                const SizedBox(height: 8),
                _ActionButton(
                  onPressed: () {},
                  iconData: Icons.zoom_out_map,
                ),
                const SizedBox(height: 8),
                _ActionButton(onPressed: () {}, iconData: Icons.near_me),
              ],
            ),
          )
        ],
      ),
    );
  }
}

/// マップの右上の表示する背景色あり角丸の [IconButton] ウィジェット。
class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.onPressed, required this.iconData});

  final VoidCallback onPressed;

  final IconData iconData;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      width: 60,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        color: Theme.of(context).colorScheme.primary,
        onPressed: onPressed,
        icon: Icon(iconData),
      ),
    );
  }
}
