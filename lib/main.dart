import 'package:firebase_core/firebase_core.dart';
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
      home: const ParkMap(),
      builder: (context, child) {
        return AuthGuard(child: child!);
      },
    );
  }
}
