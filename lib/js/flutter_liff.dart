@JS()
library flutter_liff;

import 'package:js/js.dart';

@JS('init')
external Object init(Config config);

@JS('getUserId')
external Object getUserId();

@JS('getLiffId')
external String getLiffId();

@JS('getGroupId')
external String getGroupId();

@JS('getAccessToken')
external Object getAccessToken();

@JS()
@anonymous
class Config {
  external factory Config({
    required String liffId,
    Function? successCallback,
    void Function(dynamic error)? errorCallback,
  });
  external String get liffId;
  external Function? get successCallback;
  external void Function(dynamic error)? get errorCallback;
}
