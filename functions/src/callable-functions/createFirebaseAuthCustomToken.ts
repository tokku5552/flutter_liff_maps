import * as admin from 'firebase-admin'
import axios from 'axios'
import * as functions from 'firebase-functions/v2'

/**
 * [Request]
 * GET https://asia-northeast1-flutter-liff-maps-cloudfunctions.net/createFirebaseAuthCustomToken
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
export const createfirebaseauthcustomtoken = functions.https.onCall<{ accessToken: string }>(
    async (callableRequest) => {
        const accessToken = callableRequest.data.accessToken as string
        await callGetVerifyAPI(accessToken)
        const lineUserId = await callGetProfileAPI(accessToken)
        const customToken = await admin.auth().createCustomToken(lineUserId)
        return { customToken }
    }
)

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
    if (channelId !== process.env.LINE_CHANNEL_ID) {
        console.error(`channelId: ${channelId}, process.env.LINE_CHANNEL_ID: ${process.env.LINE_CHANNEL_ID}`)
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
