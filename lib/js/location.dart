// https://developer.mozilla.org/en-US/docs/Web/API/Geolocation_API

// navigator.geolocation -> entry point into the API...

@JS('navigator.geolocation')
library weblocation;

import 'package:js/js.dart';

// Retrieves the device's current location
@JS('getCurrentPosition')
external void getCurrentPosition(Null Function(dynamic position) allowInterop);

@JS()
@anonymous
class GeolocationPosition {
  external factory GeolocationPosition({GeolocationCoordinates coords});
  external GeolocationCoordinates get coords;
}

@JS()
@anonymous
class GeolocationCoordinates {
  external factory GeolocationCoordinates({
    double latitude,
    double longitude,
  });
  external double get latitude;
  external double get longitude;
}
