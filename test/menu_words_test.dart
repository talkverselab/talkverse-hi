import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hindi_universe/core/theme.dart';
import 'package:hindi_universe/data/db/app_database.dart';
import 'package:hindi_universe/data/db/seed_loader.dart';
import 'package:hindi_universe/main.dart' show appDb;
import 'package:hindi_universe/screens/about_screen.dart';
import 'package:hindi_universe/screens/word_freq_screen.dart';
import 'package:hindi_universe/screens/devanagari_chart_screen.dart';
import 'package:hindi_universe/services/dialogue_service.dart';
import 'package:hindi_universe/services/ko_reading.dart';
import 'package:hindi_universe/widgets/episode_play_pane.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 2026-11-07 단어·메뉴 개편 — 기기 없이 화면을 그려 본다(단어장 실제 CSV 사용).
void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    appDb = AppDatabase.forTesting(NativeDatabase.memory());
    await SeedLoader(appDb).seedIfNeeded();
  });

  Future<void> show(WidgetTester t, Widget w, Size size) async {
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(theme: AppTheme.light(), home: w));
    await t.runAsync(() => Future.delayed(const Duration(milliseconds: 400)));
    await t.pump();
  }

  test('단어장: 2,000위 안 + 회화 단어, 구간 경계', () async {
    final rows = await appDb.select(appDb.words).get();
    final top = rows.where((w) => w.rank <= kWordCap).toList();
    expect(top.length, greaterThan(1890));
    expect(rows.length - top.length, 7);
    for (final w in top) {
      final want = w.rank <= 28 ? 'R1' : w.rank <= 39 ? 'R2' : w.rank <= 84 ? 'R3' : w.rank <= 226 ? 'R4' : 'R5';
      expect(w.region, want, reason: '${w.rank} ${w.word}');
    }
  });

  test('독음 기본 미표시', () async {
    await KoReadingPrefs.load();
    expect(KoReadingPrefs.show.value, isFalse);
  });

  for (final size in const [Size(360, 740), Size(1180, 820)]) {
    testWidgets('절벽 단어 타일·회화 버튼 $size', (t) async {
      await show(t, const WordFreqScreen(), size);
      expect(find.text('1단원'), findsOneWidget);
      await t.tap(find.textContaining('회화 단어 포함 (+7)'));
      await t.pump();
      // 좁은 화면은 구간 칩을 밀어야 보인다(지연 생성이라 한 번에 끝까지 안 간다)
      final chipList = find.descendant(of: find.byWidgetPredicate((w) => w is ListView && w.scrollDirection == Axis.horizontal), matching: find.byType(Scrollable));
      await t.scrollUntilVisible(find.text('회화'), 120, scrollable: chipList);
      await t.pumpAndSettle();
      await t.tap(find.text('회화').first);
      await t.pump();
      await t.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
      await t.pump();
      expect(find.text('1단원'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('앱 소개 표 $size', (t) async {
      await show(t, const AboutScreen(), size);
      expect(find.text('R5'), findsOneWidget);
      expect(find.text('227-2000'), findsOneWidget);
      expect(find.textContaining('94.6%'), findsWidgets);
      expect(t.takeException(), isNull);
    });
  }

  for (final size in const [Size(360, 740), Size(800, 1100)]) {
    testWidgets('데바나가리와 발음 $size', (t) async {
      await show(t, const DevanagariChartScreen(), size);
      expect(find.text('अ'), findsOneWidget);
      final chips = find.descendant(of: find.byWidgetPredicate((w) => w is ListView && w.scrollDirection == Axis.horizontal), matching: find.byType(Scrollable));
      for (final g in ['모음 부호', 'क 줄', 'ट 줄', 'त 줄', 'प 줄', '누크타']) {
        final chip = find.descendant(of: find.byWidgetPredicate((w) => w is ListView && w.scrollDirection == Axis.horizontal), matching: find.textContaining(g));
        await t.scrollUntilVisible(chip, 120, scrollable: chips);
        await t.ensureVisible(chip);
        await t.pumpAndSettle();
        await t.tap(chip, warnIfMissed: false);
        await t.pump();
        expect(t.takeException(), isNull);
      }
      await t.tap(find.text('फ़'));
      await t.pumpAndSettle();
      expect(find.textContaining('IPA [f]'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('문장 낱말: 탭 = 단어창, 길게 = 글자 풀이', (t) async {
    final glyph = <String>[];
    await show(
      t,
      Scaffold(body: TapWords(text: 'मैं पानी', lemmas: const [Lemma('पानी', 'पानी', '')], style: const TextStyle(fontSize: 18), onWord: glyph.add)),
      const Size(400, 700),
    );
    await t.tap(find.text('पानी'));
    await t.pumpAndSettle();
    expect(find.textContaining('빈도'), findsOneWidget); // 단어창
    expect(glyph, isEmpty);
    await t.tapAt(const Offset(5, 5));
    await t.pumpAndSettle();
    await t.longPress(find.text('पानी'));
    await t.pump();
    expect(glyph, ['पानी']);
  });
}
