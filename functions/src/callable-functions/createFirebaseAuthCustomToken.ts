import * as functions from 'firebase-functions'

export const createFirebaseAuthCustomToken = functions.region(`asia-northeast1`).https.onCall(async (data) => {
    console.log(`Hello world! ${data}`)
    // const accessToken = data.accessToken as string
    // const idToken = data.idToken as string
})
