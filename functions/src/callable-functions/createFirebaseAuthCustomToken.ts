import * as admin from 'firebase-admin'
import * as functions from 'firebase-functions'
import axios from 'axios'

const LINE_CHANNEL_ID = `YOUR-CHANNEL-ID-HERE`

/**
 * [Request]
 * GET https://asia-northeast1-maps-flutter-web-sample.cloudfunctions.net/createFirebaseAuthCustomToken
 *
 * {
 *   data: {
 *     accessToken: <string>
 *   }
 * }
 *
 * [Response]
 *
 * {
 *   customToken: <string>
 * }
 *
 * リクエストボディで受け付けた LINE ログインのアクセストークンから、LINE の
 *
 * - GET verify API
 * - GET profile API
 *
 * をコールし、その妥当性を検証して、該当ユーザーの LINE ID でカスタムトークンを作成して返す。
 */
export const createFirebaseAuthCustomToken = functions.region(`asia-northeast1`).https.onCall(async (data) => {
    const accessToken = data.accessToken as string
    await callGetVerifyAPI(accessToken)
    const lineUserId = await callGetProfileAPI(accessToken)
    const customToken = await admin.auth().createCustomToken(lineUserId)
    return { customToken }
})

/**
 * Client から送られてきた LINE アクセストークンを使って GET verify API をコールし、
 * そのチャネル ID と有効期限を検証する。
 * @param accessToken Client から送られてきた LINE アクセストークン。
 */
const callGetVerifyAPI = async (accessToken: string): Promise<void> => {
    const response = await axios.get<LINEGetVerifyAPIResponse>(
        `https://api.line.me/oauth2/v2.1/verify?access_token=${accessToken}`
    )
    if (response.status !== 200) {
        throw new Error(`[${response.status}]: GET /oauth2/v2.1/verify`)
    }

    const channelId = response.data.client_id
    if (channelId !== LINE_CHANNEL_ID) {
        throw new Error(`LINE Login チャネル ID が正しくありません。`)
    }

    const expiresIn = response.data.expires_in
    if (expiresIn <= 0) {
        throw new Error(`アクセストークンの有効期限が過ぎています。`)
    }
}

/**
 * Client から送られてきた LINE アクセストークンを使って GET profile API をコールし、
 * @param accessToken Client から送られてきた LINE アクセストークン。
 * @returns LINE ユーザー ID.
 */
const callGetProfileAPI = async (accessToken: string): Promise<string> => {
    const response = await axios.get<LINEGetProfileResponse>(`https://api.line.me/v2/profile`, {
        headers: { Authorization: `Bearer ${accessToken}` }
    })
    if (response.status !== 200) {
        throw new Error(`[${response.status}]: GET /v2/profile`)
    }
    return response.data.userId
}
