import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hindi_universe/screens/word_quiz_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('단어 퀴즈 — 10문제, 보기 4개', (t) async {
    SharedPreferences.setMockInitialValues({});
    final words = [for (var i = 0; i < 14; i++) WQWord('शब्द$i', '샵드$i', '뜻$i')];
    await t.pumpWidget(MaterialApp(home: WordQuizScreen(words: words, seed: 1)));
    await t.pumpAndSettle();
    expect(find.text('1 / 10', findRichText: true), findsNothing);
    expect(find.byKey(const ValueKey('wq-stem')), findsOneWidget);
    for (var k = 0; k < 4; k++) {
      expect(find.byKey(ValueKey('wq-opt-$k')), findsOneWidget);
    }
  });
}
