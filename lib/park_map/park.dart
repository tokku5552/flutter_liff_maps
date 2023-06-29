import 'package:cloud_firestore/cloud_firestore.dart';

class Park {
  Park({required this.parkId, required this.geo, required this.name});

  factory Park._fromJson(Map<String, dynamic> json) => Park(
        parkId: json['parkId'] as String,
        geo: Geo.fromJson(json['geo'] as Map<String, dynamic>),
        name: json['name'] as String,
      );

  factory Park.fromDocumentSnapshot(DocumentSnapshot documentSnapshot) {
    final data = documentSnapshot.data()! as Map<String, dynamic>;
    return Park._fromJson({
      ...data,
      'parkId': documentSnapshot.id,
    });
  }

  final String parkId;

  final Geo geo;

  final String name;

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'geo': geo.toJson(), 'name': name};
}

class Geo {
  Geo({required this.geohash, required this.geopoint});

  factory Geo.fromJson(Map<String, dynamic> json) => Geo(
        geohash: json['geohash'] as String,
        geopoint: json['geopoint'] as GeoPoint,
      );

  final String geohash;

  final GeoPoint geopoint;

  Map<String, dynamic> toJson() =>
      <String, dynamic>{'geohash': geohash, 'geopoint': geopoint};
}
