@JS('navigator.geolocation')
library weblocation;

import 'package:js/js.dart';

/// JavaScript の Geolocation API を使用して現在地を取得する。
///
/// 参照: https://developer.mozilla.org/en-US/docs/Web/API/Geolocation_API
@JS('getCurrentPosition')
external void getCurrentPosition(void Function(dynamic position) allowInterop);
