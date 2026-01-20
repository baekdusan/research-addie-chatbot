import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase 프로젝트 연동을 위한 설정 템플릿 파일.
///
/// 이 파일은 Firebase 설정의 예시로, 실제 값이 아닌 플레이스홀더를 포함한다.
///
/// ## 사용 방법
/// 1. 이 파일을 `lib/firebase_options.dart`로 복사
/// 2. Firebase 콘솔(https://console.firebase.google.com)에서 프로젝트 생성
/// 3. 프로젝트 설정 > 일반 > 내 앱에서 웹 앱 추가
/// 4. 발급받은 API 키, 앱 ID, 프로젝트 ID 등의 값으로 플레이스홀더 교체
///
/// 또는 FlutterFire CLI를 사용하여 자동 생성할 수 있다:
/// ```bash
/// dart pub global activate flutterfire_cli
/// flutterfire configure
/// ```
///
/// **주의**: 실제 firebase_options.dart 파일은 민감한 정보를 포함하므로
/// .gitignore에 추가하여 버전 관리에서 제외하는 것을 권장한다.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_API_KEY',
    appId: 'YOUR_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    authDomain: 'YOUR_PROJECT.firebaseapp.com',
    storageBucket: 'YOUR_PROJECT.appspot.com',
  );
}
