import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';

import 'firebase_options.dart';

// FIXME: 仮で実行前に LINE Login Channel ID を入れる。
const channelId = 'YOUR-CHANNEL-ID-HERE';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LineSDK.instance.setup(channelId);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.userChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            final user = snapshot.data;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LoginStatus(user: user),
                if (user == null)
                  const _SignInButton()
                else
                  const _SignOutButton(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LoginStatus extends StatelessWidget {
  const _LoginStatus({required this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Text('未ログイン');
    }
    return Text('ログイン済み: ${user!.uid.substring(0, 12)}...');
  }
}

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
      child: Text(isLoading ? '...' : 'LINE でログイン'),
    );
  }

  Future<void> _onPressed() async {
    if (isLoading) {
      return;
    }
    setState(() {
      isLoading = true;
    });
    try {
      final loginResult = await LineSDK.instance.login(
        scopes: ['profile', 'openid', 'email'],
      );
      final token = loginResult.accessToken.value;
      final callable = FirebaseFunctions.instanceFor(region: 'asia-northeast1')
          .httpsCallable('createFirebaseAuthCustomToken');
      final response = await callable.call<Map<String, dynamic>>(
        <String, dynamic>{'accessToken': token},
      );
      final customToken = response.data['customToken'] as String;
      final userCredential =
          await FirebaseAuth.instance.signInWithCustomToken(customToken);
      debugPrint(userCredential.user?.uid);
    } on PlatformException catch (e) {
      debugPrint(e.message);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}

class _SignOutButton extends StatelessWidget {
  const _SignOutButton();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => FirebaseAuth.instance.signOut(),
      child: const Text('サインアウト'),
    );
  }
}
