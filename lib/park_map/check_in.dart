import 'package:cloud_firestore/cloud_firestore.dart';

class CheckIn {
  CheckIn({required this.userId, required this.parkId, this.checkInAt});

  factory CheckIn.fromJson(Map<String, dynamic> json) => CheckIn(
        userId: json['userId'] as String,
        parkId: json['parkId'] as String,
        checkInAt: (json['checkInAt'] as Timestamp?)?.toDate(),
      );

  factory CheckIn.fromDocumentSnapshot(DocumentSnapshot documentSnapshot) =>
      CheckIn.fromJson(documentSnapshot.data()! as Map<String, dynamic>);

  final String userId;

  final String parkId;

  final DateTime? checkInAt;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'lineUserId': userId,
        'parkId': parkId,
        'checkInAt': checkInAt,
      };
}
