import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/chat_screen.dart';

/// Firebase를 초기화하고 앱을 시작하는 진입점.
///
/// [WidgetsFlutterBinding.ensureInitialized]로 Flutter 엔진을 초기화한 뒤,
/// Firebase 초기화를 완료하고 [ProviderScope]로 감싼 루트 위젯을 실행한다.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MyApp()));
}

/// 앱의 루트 위젯으로, Material 3 기반의 라이트/다크 테마를 정의한다.
///
/// [ChatScreen]을 홈 화면으로 설정하고, [colorScheme]을 통해
/// 앱 전체의 색상 테마를 일관되게 관리한다.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Instructional Tutoring System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Apple SD Gothic Neo',
        fontFamilyFallback: const ['Malgun Gothic', 'Dotum', 'sans-serif'],
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        fontFamily: 'Apple SD Gothic Neo',
        fontFamilyFallback: const ['Malgun Gothic', 'Dotum', 'sans-serif'],
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const ChatScreen(),
    );
  }
}
