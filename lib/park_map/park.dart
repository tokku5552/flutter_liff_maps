import 'package:cloud_firestore/cloud_firestore.dart';

class Park {
  Park({required this.geo, required this.name});

  factory Park.fromJson(Map<String, dynamic> json) => Park(
        geo: Geo.fromJson(json['geo'] as Map<String, dynamic>),
        name: json['name'] as String,
      );

  factory Park.fromDocumentSnapshot(DocumentSnapshot documentSnapshot) =>
      Park.fromJson(documentSnapshot.data()! as Map<String, dynamic>);

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
