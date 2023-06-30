import '../firestore_refs.dart';
import 'app_user.dart';
import 'check_in.dart';

/// 指定した公園 ID に対応する [CheckIn] 一覧を取得する。
Future<List<CheckIn>> fetchCheckInsOfPark(String parkId) async {
  final qs = await checkInsRef.where('parkId', isEqualTo: parkId).get();
  return qs.docs.map((qds) => qds.data()).toList();
}

/// 指定したユーザーに対応する [AppUser] を取得する。
Future<AppUser?> fetchAppUser(String appUserId) async {
  final ds = await appUserRef(appUserId: appUserId).get();
  return ds.data();
}
