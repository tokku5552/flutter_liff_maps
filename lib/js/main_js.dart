@JS()
library main;

import 'package:js/js.dart';

/// JavaScript の console.log() をコールする。
@JS('console.log')
external void consoleLog(dynamic str);

/// JavaScript の console.error() をコールする。
@JS('console.error')
external void consoleError(dynamic str);
