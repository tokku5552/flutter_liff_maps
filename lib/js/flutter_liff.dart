@JS()
library flutter_liff;

import 'package:js/js.dart';

/// LIFF アプリを初期化する。
@JS('initializeLiff')
external Object initializeLiff(Config config);

/// LINE のアクセストークンを取得する。
@JS('getAccessToken')
external Object getAccessToken();

/// LIFF アプリの初期化時に指定すべき設定値。
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
