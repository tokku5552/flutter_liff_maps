import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'auth/ui/auth.dart';
import 'firebase_options.dart';
import 'liff.dart';
import 'park_map/ui/park_map.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeLiff();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '公園マップ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      scrollBehavior: _AppScrollBehavior(),
      debugShowCheckedModeBanner: false,
      home: const ParkMap(),
      builder: (context, child) {
        if (isLiffInitializationErrored) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'LIFF アプリの初期化に失敗しました。\n'
                  'LINE のトーク画面から LIFF アプリとして起動してください。\n'
                  'エラー: $liffInitializationError',
                ),
              ),
            ),
          );
        }
        return AuthGuard(child: child!);
      },
    );
  }
}

/// マウスやトラックパッドで自然なスクロール挙動にするための設定。
class _AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}
