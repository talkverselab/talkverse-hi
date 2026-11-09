import 'package:flutter/material.dart';

import 'embed.dart';

export 'embed.dart' show appDb, HindiUniverseApp;

/// 단독 앱(힌디어유니버스). 초기화와 화면은 embed.dart — 통합 앱 Talkverse 도 같은 두 함수를 쓴다(2026-11-09).
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setStandaloneOrientations(); // 폰은 세로 고정, 태블릿·폴드 펼침은 회전 허용
  await embedInit(standalone: true);
  runApp(embedApp(onOrientation: setStandaloneOrientations));
}
