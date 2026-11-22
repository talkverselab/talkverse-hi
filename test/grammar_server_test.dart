import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hindi_universe/screens/grammar_lesson_screen.dart';
import 'package:hindi_universe/screens/sense_course_screen.dart';
import 'package:hindi_universe/services/script_sync.dart';

/// 문법 내용 서버 받기(사용자 지시 2026-11-23 「스텝 10까지 틀은 미리, 내용은 DB 업데이트로」).
String sha(String s) => sha1.convert(utf8.encode(s)).toString().substring(0, 12);

String lesson(int n, String title, int examples) => json.encode({
      'lesson': n,
      'title': title,
      'patterns': [
        {
          'id': 'p$n',
          'examples': [for (var i = 0; i < examples; i++) {'tl': 'वाक्य $i', 'rd': '박티 $i', 'ko': '문장 $i'}],
        }
      ],
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('grammar_sync'));
  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });
  const l1 = 'grammar/lesson1.json';

  test('서버 판이 없으면 앱 안 문법 그대로', () async {
    final s = ScriptSync.forTest(dir: dir, fetch: (_) async => null, baseline: {'rev': 1, 'files': {l1: 'x'}});
    final ls = await GrammarLesson.loadAll(sync: s, bundled: [l1]);
    expect(ls.length, 1);
    expect(ls.single.number, 1);
    expect(ls.single.exampleCount, greaterThan(0));
  });

  test('서버 판이 있으면 그것 — 고친 스텝은 덮어쓰고, 새 스텝은 더하고, 빈 스텝은 숨김, 순서는 파일 안 번호', () async {
    final new1 = lesson(1, '서버 1', 2), new2 = lesson(2, '서버 2', 3), empty3 = lesson(3, '빈 3', 0);
    Future<String?> fetch(String url) async {
      if (url.endsWith('/index.json')) {
        return json.encode({
          'rev': 2,
          'files': {l1: sha(new1), 'grammar/lesson2.json': sha(new2), 'grammar/lesson3.json': sha(empty3)},
        });
      }
      if (url.contains('lesson1')) return new1;
      if (url.contains('lesson2')) return new2;
      if (url.contains('lesson3')) return empty3;
      return null;
    }

    final s = ScriptSync.forTest(dir: dir, fetch: fetch, baseline: {'rev': 1, 'files': {l1: 'old'}});
    expect(await s.refresh(), isTrue);
    final ls = await GrammarLesson.loadAll(sync: s, bundled: [l1]);
    expect(ls.map((l) => l.title), ['서버 1', '서버 2']);
    expect(ls.map((l) => l.exampleCount), [2, 3]);
  });

  test('서버 목록에서 빠진 스텝은 앱 안에 있어도 숨김', () async {
    final new2 = lesson(2, '서버 2', 1);
    Future<String?> fetch(String url) async {
      if (url.endsWith('/index.json')) return json.encode({'rev': 2, 'files': {'grammar/lesson2.json': sha(new2)}});
      if (url.contains('lesson2')) return new2;
      return null;
    }

    final s = ScriptSync.forTest(dir: dir, fetch: fetch, baseline: {'rev': 1, 'files': {l1: 'old'}});
    await s.refresh();
    final ls = await GrammarLesson.loadAll(sync: s, bundled: [l1]);
    expect(ls.map((l) => l.number), [2]);
  });

  test('언어감각: 빈 급·빈 회차는 숨기고 급 순서·제목은 파일 그대로', () {
    final d = SenseCourse.visible({
      'levels': [
        {'id': 'L1', 'title': '하나', 'lessons': [{'id': 'a', 'sentences': [{'tl': 'x'}]}, {'id': 'b', 'sentences': []}]},
        {'id': 'L2', 'title': '빈 급', 'lessons': []},
        {'id': 'L3', 'title': '참고만', 'lessons': [{'id': 'c', 'kind': 'ref', 'points': [{'sentences': [{'tl': 'y'}]}]}]},
        {'id': 'L4', 'title': '빈 참고', 'lessons': [{'id': 'd', 'kind': 'ref', 'points': [{'sentences': []}]}]},
      ],
    });
    final lv = (d['levels'] as List).cast<Map>();
    expect(lv.map((l) => l['id']), ['L1', 'L3']);
    expect((lv.first['lessons'] as List).length, 1);
  });
}
