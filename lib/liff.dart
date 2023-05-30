import 'package:js/js_util.dart' as js_util;

import 'js/flutter_liff.dart' as liff;
import 'js/main_js.dart';

// FIXME: 仮で実行前に LIFF ID を入れる。
const liffId = 'YOUR-LIFF-ID-HERE';

/// LIFF の初期化およびアクセストークンの取得処理でエラーが起きたどうか。
/// 業務水準のアプリでは Riverpod や Provider を使いたいところだが、
/// いったん開発中はグローバルな変数としておく。
bool isLiffInitializationErrored = false;

/// LIFF の初期化を行う。
/// 何らかの例外やエラーが起きても、アプリがクラッシュまたはずっと読み込み中の
/// ままとなるのを避け、ひとまず起動を完了させる目的で、[Exception] も [Error]
/// もすべてあえて握り潰し、それに失敗したことを記録しておく。
Future<void> initializeLiff() async {
  try {
    await js_util.promiseToFuture<void>(
      liff.init(
        liff.Config(
          liffId: liffId,
          // JS に関数を渡すために allowInterop() でラップする。
          successCallback: js_util.allowInterop(() => log('LIFF の初期化に成功しました。')),
          errorCallback:
              js_util.allowInterop((e) => log('LIFF の初期化に失敗しました。$e')),
        ),
      ),
    );
    // ignore: avoid_catches_without_on_clauses
  } catch (e) {
    log(e);
    isLiffInitializationErrored = true;
  }
}
