import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hindi_universe/screens/sense_course_screen.dart';

void main() {
  test('언어감각 원고 — 10급, 급마다 외울 대화 10줄 + 참고, 한국어 표시 번호는 힌디어 쪽에 있음', () {
    final d = json.decode(File('assets/data/grammar/sense_course.json').readAsStringSync()) as Map<String, dynamic>;
    final levels = (d['levels'] as List).cast<Map<String, dynamic>>();
    expect(levels.length, 10);
    final mark = RegExp(r'\{([^|}]+)\|(\d+)\}');
    for (final lv in levels) {
      final ls = (lv['lessons'] as List).cast<Map<String, dynamic>>();
      expect(ls.map((l) => l['kind']), ['memorize', 'ref']);
      final ss = (ls[0]['sentences'] as List).cast<Map<String, dynamic>>();
      expect(ss.length, 10);
      for (final s in ss) {
        final tl = {for (final m in mark.allMatches(s['tl'] as String)) m.group(2)};
        final ko = {for (final m in mark.allMatches(s['ko'] as String)) m.group(2)};
        expect(tl.containsAll(ko), isTrue, reason: s['tl'] as String);
        expect(plainMarked(s['tl'] as String).contains('{'), isFalse);
        expect((s['rd'] as String).isNotEmpty, isTrue);
      }
    }
  });

  testWidgets('색 표시 — 같은 번호는 같은 색', (t) async {
    final a = markedSpans('कैफ़े {में|1}', const TextStyle()), b = markedSpans('카페{에|1}', const TextStyle());
    expect((a.last as TextSpan).style!.color, (b.last as TextSpan).style!.color);
  });
}
