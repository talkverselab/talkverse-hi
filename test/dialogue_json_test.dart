import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hindi_universe/services/dialogue_service.dart';

/// 새 회화 파일(R0~R4) 읽기 — 학습자 여성판(tl_f·speakers_f)과 장면 설명의 「A」 → 이름.
void main() {
  final j = json.decode(File('assets/data/dialogues/R4/love/r4_love_b1.json').readAsStringSync()) as Map<String, dynamic>;

  test('기본판(학습자 남성)', () {
    final d = Dialogue.fromJson(j);
    expect(d.region, 'R4');
    expect(d.speakers['B'], 'अनन्या');
    expect(d.genders['B'], 'female');
    expect(d.turns.first.tl, contains('काम कर रहे हो'));
  });

  test('여성판 — tl_f 와 상대(speakers_f)·성별', () {
    final d = Dialogue.fromJson(j, female: true);
    expect(d.speakers['B'], 'अर्जुन');
    expect(d.genders['B'], 'male');
    expect(d.turns.first.tl, contains('काम कर रही हो'));
    expect(d.turns[1].tl, d.turns[1].tl); // tl_f 없는 턴은 기본판 그대로
  });

  test('편 순서 키', () {
    expect(Dialogue.fromJson(j).orderKey, '201');
  });
}
