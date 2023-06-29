import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  AppUser._({required this.appUserId, required this.name, this.imageUrl});

  factory AppUser._fromJson(Map<String, dynamic> json) => AppUser._(
        appUserId: json['appUserId'] as String,
        name: json['name'] as String,
        imageUrl: json['imageUrl'] as String?,
      );

  factory AppUser.fromDocumentSnapshot(DocumentSnapshot documentSnapshot) {
    final data = documentSnapshot.data()! as Map<String, dynamic>;
    return AppUser._fromJson(<String, dynamic>{
      ...data,
      'appUserId': documentSnapshot.id,
    });
  }

  final String appUserId;

  final String name;

  final String? imageUrl;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'appUserId': appUserId,
        'name': name,
        'imageUrl': imageUrl,
      };
}
