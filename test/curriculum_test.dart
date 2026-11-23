import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hindi_universe/screens/curriculum_screen.dart';
import 'package:hindi_universe/services/curriculum_service.dart';
import 'package:hindi_universe/services/dialogue_service.dart';

Dialogue _d(String id, String island, int n) => Dialogue.fromJson({
      'id': id,
      'region': 'R1',
      'island': island,
      'turns': [
        for (var i = 1; i <= n; i++) {'num': i, 'speaker': i.isOdd ? 'A' : 'B', 'tl': 'मैं वाक्य$id$i बोलता हूँ', 'ko': '뜻$id$i'}
      ],
    });

void main() {
  group('점수 80% 경계', () {
    test('소수점 버림', () {
      expect(scorePercent(7, 9), 77);
      expect(scorePercent(2, 3), 66);
      expect(scorePercent(0, 0), 0);
    });
    test('80% 이상만 통과', () {
      expect(isPass(8, 10), isTrue);
      expect(isPass(79, 100), isFalse);
      expect(isPass(4, 5), isTrue);
      expect(isPass(23, 29), isFalse); // 79.3 → 79
      expect(isPass(24, 30), isTrue);
    });
    test('시험 기록 — 통과면 편 통과, 아니면 틀린 편 연습 다시', () {
      final st = CurriculumState(course: Course('c', ['a', 'b'], practiced: ['a', 'b']));
      expect(st.recordExam(7, 10, {'b'}, '2026-11-22'), isFalse);
      expect(st.course!.practiced, ['a']);
      expect(st.passedDialogues, isEmpty);
      st.course!.practiced.add('b');
      expect(st.recordExam(8, 10, {}, '2026-11-23'), isTrue);
      expect(st.course!.passedAt, '2026-11-23');
      expect(st.passedDialogues, ['a', 'b']);
      expect(st.course!.examScores, [70, 80]);
    });
  });

  group('간격 반복 날짜', () {
    test('1일 → 3일 → 7일 → 졸업', () {
      final st = CurriculumState();
      st.enqueue('x#1', '2026-11-22');
      expect(st.review.single.due, '2026-11-23');
      st.grade('x#1', true, '2026-11-23');
      expect(st.review.single.due, '2026-11-26');
      st.grade('x#1', true, '2026-11-26');
      expect(st.review.single.due, '2026-12-03');
      st.grade('x#1', true, '2026-12-03');
      expect(st.review, isEmpty);
    });
    test('틀리면 1일 뒤 처음 간격으로', () {
      final st = CurriculumState();
      st.enqueue('x#1', '2026-11-22');
      st.grade('x#1', true, '2026-11-23');
      st.grade('x#1', false, '2026-11-26');
      expect(st.review.single.step, 0);
      expect(st.review.single.due, '2026-11-27');
    });
    test('달·해 넘김', () {
      expect(addDays('2026-12-30', 3), '2027-01-02');
      expect(addDays('2028-02-28', 1), '2028-02-29');
    });
  });

  group('하루 분량·연속', () {
    test('새 편 목표를 채우고 복습이 없으면 끝, 연속 일수', () {
      final st = CurriculumState(dailyGoal: 1, course: Course('c', ['a', 'b']));
      expect(st.dayDone('2026-11-22'), isFalse);
      st.markPracticed('a', [1, 2], '2026-11-22');
      expect(st.dayDone('2026-11-22'), isTrue);
      expect(st.streakShown('2026-11-22'), 1);
      // 다음 날: 복습 2줄 + 새 편 1
      expect(st.dueReview('2026-11-23').length, 2);
      st.grade('a#1', true, '2026-11-23');
      st.grade('a#2', true, '2026-11-23');
      st.markPracticed('b', [1], '2026-11-23');
      expect(st.todayReview, 2);
      expect(st.streakShown('2026-11-23'), 2);
      expect(st.streakShown('2026-11-25'), 0);
    });
    test('저장 형식 왕복', () {
      final st = CurriculumState(level: 'R1', course: Course('c', ['a']));
      st.markPracticed('a', [1], '2026-11-22');
      final back = CurriculumState.fromJson(st.toJson());
      expect(back.toJson(), st.toJson());
      expect(st.toJson().keys, containsAll(['level', 'dailyGoal', 'course', 'passedDialogues', 'review', 'streak']));
    });
  });

  group('문제·추천', () {
    test('편마다 줄 수만큼, 최대 10, 보기 4개 중 정답 1', () {
      final a = _d('a', 'friends', 12), b = _d('b', 'life', 4);
      final qs = buildQuestions(a, limit: 10, pool: [b]);
      expect(qs.length, 10);
      for (final q in qs) {
        expect(q.choices.length, 4);
        expect(q.choices.toSet().length, 4);
        // 힌디어: 낱말 목록이 없어 띄어쓰기 낱말로 빈칸을 만든다(뜻·빈칸 번갈아)
        if (q.kind == 'blank') {
          expect(q.prompt.replaceFirst('＿＿', q.choices[q.answer]), 'मैं वाक्यa${q.turn} बोलता हूँ');
        } else {
          expect(q.choices[q.answer], '뜻a${q.turn}');
        }
      }
      expect(buildQuestions(b, limit: 10, pool: [a]).length, 4);
    });
    test('시험 문제 수: 편당 최소 3, 전체 최대 30', () {
      expect(examPerDialogue(3), 10);
      expect(examPerDialogue(5), 6);
      expect(examPerDialogue(10), 3);
    });
    test('추천 = 안 한 편, 주제 겹치지 않게', () {
      final list = [_d('f1', 'friends', 2), _d('f2', 'friends', 2), _d('l1', 'life', 2), _d('w1', 'work', 2)];
      final r = recommend(list, {'l1'}, {}, 3);
      expect(r, ['f1', 'w1', 'f2']);
    });
  });

  testWidgets('시험 화면 — 고르고 결과까지', (t) async {
    final a = _d('a', 'friends', 5);
    final qs = buildQuestions(a, limit: 2);
    await t.pumpWidget(MaterialApp(home: CurriculumQuizScreen(title: 'T', questions: qs, mode: QuizMode.exam)));
    for (var i = 0; i < 2; i++) {
      await t.tap(find.text(qs[i].choices[qs[i].answer]));
      await t.pump();
      await t.tap(find.byType(FilledButton).last);
      await t.pump();
    }
    expect(find.textContaining('100'), findsOneWidget);
  });

  for (final w in [300.0, 390.0]) {
    testWidgets('코스 고르기 칩 줄 — ${w.toInt()}px 폭에서 넘치지 않음', (t) async {
      t.view.physicalSize = Size(w, 800);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(MaterialApp(home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: CurriculumPickBar(count: 5, onCount: (_) {}, onRecommend: () {})))));
      expect(t.takeException(), isNull);
      expect(find.text('추천으로 채우기'), findsOneWidget);
    });
  }

  group('단계(§12) — 데이터에서', () {
    final svc = CurriculumService.instance;
    Map<String, dynamic> j(int rev) => {
          'rev': rev,
          'stages': [
            {'n': 2, 'title': '2단계', 'dialogueIds': ['c', 'zz'], 'pick': [3, 5], 'pass': 80},
            {'n': 1, 'title': '1단계', 'dialogueIds': ['a', 'b']},
            {'n': 3, 'title': '3단계', 'dialogueIds': ['없는편']},
          ],
          'prep': [],
        };
    setUp(() => DialogueService.instance.setForTest([_d('a', 'life', 3), _d('b', 'love', 3), _d('c', 'travel', 3)]));
    tearDown(() => svc.setStages(null));

    test('단계 순서는 n, 앱에 없는 편은 건너뜀, 편 0개 단계는 숨김', () {
      final st = CurriculumService.parseStages(j(1))!;
      svc.setStages(st, rev: 1);
      expect(svc.levelKeys, ['1', '2']);
      expect(svc.levelList('2').map((d) => d.id), ['c']);
      expect(svc.levelTitle('1'), '1단계');
      expect(svc.pickOptions('2'), [3, 5]);
      expect(svc.nextLevel('1'), '2');
      expect(svc.nextLevel('2'), isNull);
      expect(svc.poolFor(DialogueService.instance.byId('b')!).map((d) => d.id), ['a', 'b']);
    });

    test('형식이 틀리면 null → 옛 동작(회화 레벨)', () {
      expect(CurriculumService.parseStages({'rev': 1}), isNull);
      expect(CurriculumService.parseStages({'rev': 1, 'stages': []}), isNull);
      svc.setStages(null);
      expect(svc.levelKeys, ['R1']); // 시험용 편은 모두 R1
    });

    test('옛 저장값 R → 단계: R0·R1 → 1, R2 → 2, R4 → 4', () {
      expect(svc.stageForOldLevel('R0'), '1');
      expect(svc.stageForOldLevel('R1'), '1');
      expect(svc.stageForOldLevel('R2'), '2');
      expect(svc.stageForOldLevel('R4'), '4');
    });

    test('앱 안 기본 JSON: 단계 4개, 편 id 가 모두 형식에 맞음', () {
      final raw = File('assets/curriculum_hi.json').readAsStringSync();
      final st = CurriculumService.parseStages(json.decode(raw) as Map)!;
      expect(st.map((s) => s.key), ['1', '2', '3', '4']);
      expect(st.expand((s) => s.ids).length, 66);
    });
  });
}
