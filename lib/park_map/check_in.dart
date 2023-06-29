import 'package:cloud_firestore/cloud_firestore.dart';

class CheckIn {
  CheckIn({required this.appUserId, required this.parkId, this.checkInAt});

  factory CheckIn.fromJson(Map<String, dynamic> json) => CheckIn(
        appUserId: json['appUserId'] as String,
        parkId: json['parkId'] as String,
        checkInAt: (json['checkInAt'] as Timestamp?)?.toDate(),
      );

  factory CheckIn.fromDocumentSnapshot(DocumentSnapshot documentSnapshot) =>
      CheckIn.fromJson(documentSnapshot.data()! as Map<String, dynamic>);

  final String appUserId;

  final String parkId;

  final DateTime? checkInAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'lineUserId': appUserId,
        'parkId': parkId,
        'checkInAt': checkInAt,
      };
}
