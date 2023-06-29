import 'package:cloud_firestore/cloud_firestore.dart';

class CheckIn {
  CheckIn._({
    required this.checkInId,
    required this.appUserId,
    required this.parkId,
    this.checkInAt,
  });

  factory CheckIn._fromJson(Map<String, dynamic> json) => CheckIn._(
        checkInId: json['checkInId'] as String,
        appUserId: json['appUserId'] as String,
        parkId: json['parkId'] as String,
        checkInAt: (json['checkInAt'] as Timestamp?)?.toDate(),
      );

  factory CheckIn.fromDocumentSnapshot(DocumentSnapshot documentSnapshot) {
    final data = documentSnapshot.data()! as Map<String, dynamic>;
    return CheckIn._fromJson(<String, dynamic>{
      ...data,
      'checkInId': documentSnapshot.id,
    });
  }

  final String checkInId;

  final String appUserId;

  final String parkId;

  final DateTime? checkInAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'checkInId': checkInId,
        'appUserId': appUserId,
        'parkId': parkId,
        'checkInAt': checkInAt,
      };
}
