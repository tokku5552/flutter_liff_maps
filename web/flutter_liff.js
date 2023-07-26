/**
 * このファイルでは、LIFF の初期化処理およびアクセストークンの取得処理を提供する。
 * Flutter Web の js/flutter_liff.dart から呼ばれる。
 *
 * @file
 */

/**
 * LIFF の初期化を行う。
 *
 * @param {Object} config 設定オブジェクト
 * @param {string} config.liffId LIFF ID
 * @param {function} config.successCallback LIFF 初期化成功時のコールバック関数
 * @param {function} config.errorCallback LIFF 初期化失敗時のコールバック関数
 *
 * @returns {Promise<void>} プロミス。初期化が完了すると解決する。
 */
async function initializeLiff(config) {
  console.log('LIFF init called')
  await liff
    .init({
      liffId: config['liffId'],
      withLoginOnExternalBrowser: true,
    })
    .then(() => {
      // LIFF アプリとして起動していない、かつ未ログインであれば LINE にログインする。
      if (!liff.isInClient() && !liff.isLoggedIn()) {
        liff.login()
      }
      config['successCallback']()
    })
    .catch((err) => {
      config['errorCallback'](err)
    })
}

/**
 * LINE のアクセストークンを取得する。
 *
 * @returns {Promise<string>} プロミス。アクセストークンが解決する。
 * @throws {Error} LIFF が初期化されていない場合にエラーがスローされる。
 */
async function getAccessToken() {
  console.log('getAccessToken called')
  return await liff.getAccessToken()
}
