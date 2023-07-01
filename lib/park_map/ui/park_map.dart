import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:js/js.dart';
import 'package:rxdart/rxdart.dart';

import '../../firestore_refs.dart';
import '../../js/location.dart';
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

  /// 検出半径。
  final double radiusInKm;

  /// 中心位置。
  final CameraPosition cameraPosition;
}

/// 上部に [GoogleMap]、下部に取得された公園と [CheckIn] 一覧を表示する UI.
class ParkMap extends StatefulWidget {
  const ParkMap({super.key});

  @override
  ParkMapState createState() => ParkMapState();
}

class ParkMapState extends State<ParkMap> {
  /// [GoogleMap] ウィジェットの onMapCreated で得られるコントローラインスタンス。
  late final GoogleMapController _googleMapController;

  /// Google Maps 上に表示される [Marker] 一覧。
  final Set<Marker> _markers = {};

  /// Google Maps 上で取得された [Park] 一覧。
  final List<Park> _parks = [];

  /// 初回の公園データ取得が済んだかどうか。
  bool _initialDataLoaded = false;

  /// 現在の公園の検出条件の [BehaviorSubject].
  late final _geoQueryCondition = BehaviorSubject<_GeoQueryCondition>.seeded(
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
    _initialDataLoaded = true;
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
  static const double _mapHeightRatio = 0.6;

  /// 検出半径を調整する [Slider] ウィジェットの高さの割合。
  static const double _sliderHeightRatio = 0.1;

  /// [CheckIn] 一覧を表示する [PageView] ウィジェットの高さの割合。
  double get _pageViewHeightRatio => 1 - (_mapHeightRatio + _sliderHeightRatio);

  /// [GoogleMap] ウィジェット表示時の初期値。
  final LatLng _initialLocation = _tokyoStation;

  /// [GoogleMap] ウィジェット表示時カメラ位置の初期値。
  late final _initialCameraPosition = CameraPosition(
    target: _initialLocation,
    zoom: _initialZoom,
  );

  /// ブラウザが現在地を取得することを許可している場合は、カメラの現在位置と
  /// 公園の検出条件の中心地位を、現在位置に動かす。
  void _maybeMoveToCurrentLocation() {
    getCurrentPosition(
      allowInterop((position) {
        final latLng = LatLng(
          // ignore: avoid_dynamic_calls
          position.coords.latitude as double,
          // ignore: avoid_dynamic_calls
          position.coords.longitude as double,
        );
        _googleMapController.animateCamera(CameraUpdate.newLatLng(latLng));
      }),
    );
  }

  @override
  void initState() {
    super.initState();
  }

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: displayHeight * _mapHeightRatio,
            child: GoogleMap(
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              initialCameraPosition: _initialCameraPosition,
              onMapCreated: (controller) {
                _googleMapController = controller;
                _stream.listen(_updateMarkersByDocumentSnapshots);
              },
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
            height: displayHeight * _sliderHeightRatio,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('現在の検出半径: ${_radiusInKm}km'),
                        const SizedBox(height: 8),
                        Slider(
                          value: _radiusInKm,
                          min: 1,
                          max: 10,
                          divisions: 9,
                          label: _radiusInKm.toStringAsFixed(1),
                          onChanged: (value) => _geoQueryCondition.add(
                            _GeoQueryCondition(
                              radiusInKm: value,
                              cameraPosition: _cameraPosition,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: _maybeMoveToCurrentLocation,
                    icon: const Icon(Icons.near_me),
                  ),
                ],
              ),
            ),
          ),
          if (!_initialDataLoaded)
            const Center(child: CircularProgressIndicator())
          else if (_parks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '周辺に公園が見つかりません。'
                'マップの位置を移動したり、検出半径を広げたりしてください。',
              ),
            )
          else
            SizedBox(
              height: displayHeight * _pageViewHeightRatio,
              child: _ParksPageView(_parks),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => FirebaseAuth.instance.signOut(),
        child: const Icon(Icons.exit_to_app),
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          park.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _checkIn(park),
                        child: const Text('チェックイン'),
                      ),
                    ],
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

  /// チェックインする。
  Future<void> _checkIn(Park park) async {
    final scaffoldMessengerState = ScaffoldMessenger.of(context);
    await addCheckIn(
      appUserId: FirebaseAuth.instance.currentUser!.uid,
      parkId: park.parkId,
    );
    scaffoldMessengerState.showSnackBar(
      SnackBar(
        content: Text('「${park.name}」にチェックインしました。'),
      ),
    );
    setState(() {});
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
        if (checkIns.isEmpty) {
          return const Text('まだチェックインしたユーザーはいません。');
        }
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

  static const double _imageRadius = 24;

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
          leading: (appUser.imageUrl ?? '').isEmpty
              ? const CircleAvatar(
                  radius: _imageRadius,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, size: _imageRadius * 2),
                )
              : ClipOval(
                  child: Image.network(
                    appUser.imageUrl!,
                    height: _imageRadius * 2,
                    width: _imageRadius * 2,
                    fit: BoxFit.cover,
                  ),
                ),
          title: Text(appUser.name),
          subtitle: checkIn.checkInAt != null
              ? Text(DateFormat('yyyy年MM月dd日 HH:mm').format(checkIn.checkInAt!))
              : null,
        );
      },
    );
  }
}
