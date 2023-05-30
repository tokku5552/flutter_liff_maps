import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  AppUser({required this.userId, required this.name});

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        userId: json['userId'] as String,
        name: json['name'] as String,
      );

  factory AppUser.fromDocumentSnapshot(DocumentSnapshot documentSnapshot) =>
      AppUser.fromJson(documentSnapshot.data()! as Map<String, dynamic>);

  final String userId;

  final String name;

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'userId': userId, 'name': name};
}
