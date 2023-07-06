import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore_refs.dart';
import 'app_user.dart';
import 'check_in.dart';

/// 指定した公園 ID に対応する [CheckIn] 一覧を取得する。
Future<List<CheckIn>> fetchCheckInsOfPark(String parkId) async {
  final qs = await checkInsRef
      .where('parkId', isEqualTo: parkId)
      .orderBy('checkInAt', descending: true)
      .get();
  return qs.docs.map((qds) => qds.data()).toList();
}

/// 指定したユーザーに対応する [AppUser] を取得する。
Future<AppUser?> fetchAppUser(String appUserId) async {
  final ds = await appUserRef(appUserId: appUserId).get();
  return ds.data();
}

// TODO: 書き込み用の CheckIn 型と CollectionReference を用いて型安全にする？
/// [CheckIn] を作成する。
Future<void> addCheckIn({
  required String appUserId,
  required String parkId,
}) =>
    FirebaseFirestore.instance.collection('checkIns').add(<String, dynamic>{
      'appUserId': appUserId,
      'parkId': parkId,
      'checkInAt': FieldValue.serverTimestamp(),
    });
