import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:js/js_util.dart' as js_util;

import '../../js/flutter_liff.dart' as liff;

/// [FirebaseAuth] の認証状態を監視して表示内容をコントロールする。
/// 未ログインの場合は [_SingedOutGuard] ウィジェットを表示する。
/// ログイン済みの場合のみ [child] で与えられたウィジェットが表示される。
/// [MaterialApp] の builder メソッド内部で使用することで、その [BuildContext] を
/// 継ぐすべてのウィジェットに適用される。
class AuthGuard extends StatelessWidget {
  const AuthGuard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _OverlayLoading();
        }
        final user = snapshot.data;
        if (user == null) {
          return const _SingedOutGuard();
        }
        return child;
      },
    );
  }
}

/// 認証状態の確認中に [AuthGuard] で [Stack] に重ねるためのウィジェット。
class _OverlayLoading extends StatelessWidget {
  const _OverlayLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: ColoredBox(
        color: Colors.white,
        child: SizedBox.expand(
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

/// 未サインイン時に [AuthGuard] で [Stack] に重ねてコンテンツを見えないように
/// するためのウィジェット。
class _SingedOutGuard extends StatelessWidget {
  const _SingedOutGuard();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('下記のボタンからログインしてください。'),
            _SignInButton(),
          ],
        ),
      ),
    );
  }
}

/// LIFF から得られる accessToken を用いて、[FirebaseAuth] のカスタムトークン
/// 認証を行うボタン。
class _SignInButton extends StatefulWidget {
  const _SignInButton();

  @override
  State<_SignInButton> createState() => _SignInButtonState();
}

class _SignInButtonState extends State<_SignInButton> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : _onPressed,
      child: Text(isLoading ? '...' : 'LINE アカウントで連携ログイン'),
    );
  }

  Future<void> _onPressed() async {
    if (isLoading) {
      return;
    }
    setState(() {
      isLoading = true;
    });
    final scaffoldMessengerState = ScaffoldMessenger.of(context);
    try {
      final accessToken =
          await js_util.promiseToFuture<String>(liff.getAccessToken());
      final callable = FirebaseFunctions.instanceFor(region: 'asia-northeast1')
          .httpsCallable('createfirebaseauthcustomtoken');
      final response = await callable.call<Map<String, dynamic>>(
        <String, dynamic>{'accessToken': accessToken},
      );
      final customToken = response.data['customToken'] as String;
      await FirebaseAuth.instance.signInWithCustomToken(customToken);
      // NOTE: [開発・実装時のヒント]
      // 上記の Firebase Function の開発が済むまでは、上記の try 句の中の
      // 記述をすべてコメントアウトして、下記の匿名サインインを有効にするのも
      // Flutter Web の動作確認をするには有効である。
      // await FirebaseAuth.instance.signInAnonymously();
      scaffoldMessengerState
          .showSnackBar(const SnackBar(content: Text('サインインしました。')));
    }
    // ignore: avoid_catches_without_on_clauses
    catch (e) {
      // js_util.promiseToFuture() でどんなエラーが起きうるか把握していないため。
      // 業務レベルのアプリでは然るべき Exception や Error を補足するべき。
      scaffoldMessengerState
          .showSnackBar(SnackBar(content: Text('サインインに失敗しました。（エラー: $e）')));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}
