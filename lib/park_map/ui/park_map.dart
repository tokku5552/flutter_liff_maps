import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rxdart/rxdart.dart';

import '../../firestore_refs.dart';
import '../app_user.dart';
import '../check_in.dart';
import '../firestore.dart';
import '../park.dart';

/// 東京駅の緯度経度。
const _tokyoStation = LatLng(35.681236, 139.767125);

/// 公園の検出条件。
class _GeoQueryCondition {
  _GeoQueryCondition({
    required this.radiusInKm,
    required this.cameraPosition,
  });

  final double radiusInKm;
  final CameraPosition cameraPosition;
}

/// 上部に [GoogleMap]、下部に取得された公園と [CheckIn] 一覧を表示する UI.
class ParkMap extends StatefulWidget {
  const ParkMap({super.key});

  @override
  ParkMapState createState() => ParkMapState();
}

class ParkMapState extends State<ParkMap> {
  /// Google Maps 上に表示される [Marker] 一覧。
  final Set<Marker> _markers = {};

  /// Google Maps 上で取得された [Park] 一覧。
  final List<Park> _parks = [];

  /// 現在の公園の検出条件の [BehaviorSubject].
  final _geoQueryCondition = BehaviorSubject<_GeoQueryCondition>.seeded(
    _GeoQueryCondition(
      radiusInKm: _initialRadiusInKm,
      cameraPosition: _initialCameraPosition,
    ),
  );

  /// 公園の取得結果の [Stream].
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

  /// 得られた公園の [DocumentSnapshot] から、[_markers] を更新する。
  void _updateMarkersByDocumentSnapshots(
    List<DocumentSnapshot<Park>> documentSnapshots,
  ) {
    final markers = <Marker>{};
    final parks = <Park>[];
    for (final ds in documentSnapshots) {
      final id = ds.id;
      final park = ds.data();
      if (park == null) {
        continue;
      }
      final name = park.name;
      final geoPoint = park.geo.geopoint;
      markers.add(_createMarker(id: id, name: name, geoPoint: geoPoint));
      parks.add(park);
    }
    _markers
      ..clear()
      ..addAll(markers);
    _parks
      ..clear()
      ..addAll(parks);
    setState(() {});
  }

  /// 取得された公園から [GoogleMap] 上に表示する [Marker] を生成する。
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

  /// 現在のカメラの中心位置からの検出半径 (km)。
  double get _radiusInKm => _geoQueryCondition.value.radiusInKm;

  /// 現在のカメラの中心位置。
  CameraPosition get _cameraPosition => _geoQueryCondition.value.cameraPosition;

  /// 中心位置からの検出半径の初期値。
  static const double _initialRadiusInKm = 1;

  /// ズームレベルの初期値。
  static const double _initialZoom = 14;

  /// 画面高さに対する [GoogleMap] ウィジェットの高さの割合。
  static const double _mapHeightRatio = 0.7;

  /// [GoogleMap] ウィジェット表示時の初期値。
  static final LatLng _initialTarget = LatLng(
    _tokyoStation.latitude,
    _tokyoStation.longitude,
  );

  /// [GoogleMap] ウィジェット表示時カメライチの初期値。
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
    final size = MediaQuery.sizeOf(context);
    final displayHeight = size.height;
    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: displayHeight * _mapHeightRatio,
            child: GoogleMap(
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
          ),
          SizedBox(
            height: displayHeight * (1 - _mapHeightRatio),
            child: _ParksPageView(_parks),
          ),
        ],
      ),
    );
  }
}

/// マップの株に表示する [PageView] ウィジェット。
class _ParksPageView extends StatefulWidget {
  const _ParksPageView(this.parks);

  final List<Park> parks;

  @override
  State<_ParksPageView> createState() => _ParksPageViewState();
}

class _ParksPageViewState extends State<_ParksPageView> {
  final _pageController = PageController(viewportFraction: _viewportFraction);

  static const _viewportFraction = 0.85;

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _pageController,
      physics: const ClampingScrollPhysics(),
      onPageChanged: (index) {},
      children: [
        for (final park in widget.parks)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    park.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  const SizedBox(height: 16),
                  Expanded(child: _CheckInsListView(parkId: park.parkId)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// [CheckIn] 一覧の UI.
class _CheckInsListView extends StatefulWidget {
  const _CheckInsListView({required this.parkId});

  final String parkId;

  @override
  State<_CheckInsListView> createState() => _CheckInsListViewState();
}

class _CheckInsListViewState extends State<_CheckInsListView> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CheckIn>>(
      future: fetchCheckInsOfPark(widget.parkId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }
        final checkIns = snapshot.data ?? [];
        // TODO: checkIns.isEmpty の場合の UI を変える。
        return ListView.builder(
          itemCount: checkIns.length,
          itemBuilder: (context, index) {
            final checkIn = checkIns[index];
            return _CheckInListTile(checkIn: checkIn);
          },
        );
      },
    );
  }
}

/// [CheckIn] の [ListTile].
class _CheckInListTile extends StatelessWidget {
  const _CheckInListTile({required this.checkIn});

  final CheckIn checkIn;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: fetchAppUser(checkIn.appUserId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }
        final appUser = snapshot.data;
        if (appUser == null) {
          return const SizedBox();
        }
        return ListTile(
          leading: ClipOval(
            child: Image.network(
              // TODO: あとでユーザーにプロフィール画像をもたせて表示する。
              'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQa9CxANJNRt1p0KyW32FjE6xLctwNVP9vbafzzyUAfUA&s',
              height: 48,
              width: 48,
              fit: BoxFit.cover,
            ),
          ),
          title: Text(appUser.name),
          subtitle: Text(checkIn.checkInAt.toString()),
        );
      },
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
