import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore_refs.dart';
import 'app_user.dart';
import 'check_in.dart';

/// 指定した公園 ID に対応する [CheckIn] 一覧を取得する。
Future<List<CheckIn>> fetchCheckInsOfPark(String parkId) async {
  // NOTE: 複合インデックスの作成が必要であることに注意する。
  // また、Flutter Web では、複合クエリのインデックスを自動で作成するための URL
  // リンクがコンソールに表示されることはないので、手動で対応する必要がある。
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
