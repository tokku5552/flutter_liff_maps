import 'package:cloud_firestore/cloud_firestore.dart';

import 'park_map/app_user.dart';
import 'park_map/check_in.dart';
import 'park_map/park.dart';

final _db = FirebaseFirestore.instance;

/// [AppUser]s コレクションの参照。
final appUsersRef = _db.collection('appUsers').withConverter(
  fromFirestore: (ds, _) {
    return AppUser.fromDocumentSnapshot(ds);
  },
  toFirestore: (obj, _) {
    final json = obj.toJson();
    return json;
  },
);

/// [AppUser] ドキュメントの参照。
DocumentReference<AppUser> appUserRef({required String appUserId}) =>
    appUsersRef.doc(appUserId);

/// [Park]s コレクションの参照。
final parksRef = _db.collection('parks').withConverter(
  fromFirestore: (ds, _) {
    return Park.fromDocumentSnapshot(ds);
  },
  toFirestore: (obj, _) {
    final json = obj.toJson();
    return json;
  },
);

/// [Park] ドキュメントの参照。
DocumentReference<Park> parkRef({required String parkId}) =>
    parksRef.doc(parkId);

/// [CheckIn]s コレクションの参照。
final checkInsRef = _db.collection('checkIns').withConverter<CheckIn>(
      fromFirestore: (ds, _) {
        return CheckIn.fromDocumentSnapshot(ds);
      },
      toFirestore: (obj, _) => obj.toJson(),
    );

/// [CheckIn] ドキュメントの参照。
DocumentReference<CheckIn> checkInRef({required String checkInId}) =>
    checkInsRef.doc(checkInId);
