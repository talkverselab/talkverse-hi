import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hindi_universe/data/entitlement.dart';
import 'package:hindi_universe/data/purchase.dart';
import 'package:hindi_universe/services/curriculum_service.dart';
import 'package:hindi_universe/services/dialogue_service.dart';

/// 이용권 잠금 경계(PAYWALL_SPEC §2·§5): 1단계 열림 · 2단계 잠김 · 이용권 있으면 열림.
Dialogue _d(String id, String region) => Dialogue.fromJson({
      'id': id,
      'region': region,
      'island': 'life',
      'turns': [
        {'num': 1, 'speaker': 'A', 'tl': 'नमस्ते', 'ko': '안녕'}
      ],
    });

void main() {
  final svc = CurriculumService.instance;
  setUp(() {
    Purchase.owned.value = const {};
    DialogueService.instance.setForTest([_d('a', 'R1'), _d('b', 'R2')]);
    final j = json.decode(File('assets/curriculum_hi.json').readAsStringSync()) as Map<String, dynamic>;
    // 앱 안 JSON 의 free 값 그대로, 편만 시험용으로
    final st = CurriculumService.parseStages({
      ...j,
      'stages': [
        {...(j['stages'] as List)[0] as Map, 'dialogueIds': ['a']},
        {...(j['stages'] as List)[1] as Map, 'dialogueIds': ['b']},
      ],
    })!;
    svc.setStages(st, rev: (j['rev'] as num).toInt());
  });
  tearDown(() {
    svc.setStages(null);
    Purchase.owned.value = const {};
  });

  test('앱 안 커리큘럼 JSON rev 2 — 1단계만 free, 무료 한도 freeSteps 2·freeSenseLevels 1', () {
    final j = json.decode(File('assets/curriculum_hi.json').readAsStringSync()) as Map<String, dynamic>;
    expect(j['rev'], greaterThanOrEqualTo(2));
    expect([for (final s in j['stages'] as List) (s as Map)['free']], [true, false, false, false]);
    expect(j['freeSteps'], 2);
    expect(j['freeSenseLevels'], 1);
  });

  test('이용권 없음: 1단계·그 편 열림, 2단계·그 편 잠김, 문법 3스텝·언어감각 2급 잠김', () {
    expect(Entitlement.premium, isFalse);
    expect(Entitlement.stageOpen('1'), isTrue);
    expect(Entitlement.stageOpen('2'), isFalse);
    expect(Entitlement.dialogueOpen(DialogueService.instance.byId('a')!), isTrue);
    expect(Entitlement.dialogueOpen(DialogueService.instance.byId('b')!), isFalse);
    expect(Entitlement.grammarStepOpen(2), isTrue);
    expect(Entitlement.grammarStepOpen(3), isFalse);
    expect(Entitlement.senseLevelOpen(1), isTrue);
    expect(Entitlement.senseLevelOpen(2), isFalse);
  });

  test('이용권 있음(lang_hi_* 또는 all_*): 모두 열림, 기한 지난 구독은 닫힘', () {
    Purchase.owned.value = {'lang_hi_life': 0};
    expect(Entitlement.stageOpen('2'), isTrue);
    expect(Entitlement.dialogueOpen(DialogueService.instance.byId('b')!), isTrue);
    expect(Entitlement.grammarStepOpen(9), isTrue);
    Purchase.owned.value = {'all_1y': DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch};
    expect(Entitlement.senseLevelOpen(5), isTrue);
    Purchase.owned.value = {'lang_hi_1m': DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch};
    expect(Entitlement.stageOpen('2'), isFalse);
    Purchase.owned.value = {'lang_ja_life': 0}; // 다른 언어 이용권은 안 됨
    expect(Entitlement.stageOpen('2'), isFalse);
  });

  test('단계 JSON 이 없으면 옛 레벨 기준: R0·R1 무료', () {
    svc.setStages(null);
    expect(Entitlement.dialogueOpen(DialogueService.instance.byId('a')!), isTrue);
    expect(Entitlement.dialogueOpen(DialogueService.instance.byId('b')!), isFalse);
  });
}
