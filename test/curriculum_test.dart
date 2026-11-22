import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hindi_universe/services/curriculum_service.dart';
import 'package:hindi_universe/services/dialogue_service.dart';

Dialogue _d(String id, String island, int n) => Dialogue.fromJson({
      'id': id,
      'region': 'R1',
      'island': island,
      'title': id,
      'speakers': {'A': '나', 'B': 'प्रिया'},
      'genders': {'A': 'm', 'B': 'f'},
      'turns': [
        for (var i = 1; i <= n; i++) {'num': i, 'speaker': i.isOdd ? 'A' : 'B', 'tl': 'मैं आज बाज़ार$i जाता हूँ वहाँ$id', 'ko': '뜻 $id-$i'},
      ],
    });

void main() {
  test('점수 = 소수점 버림, 80% 경계', () {
    expect(scorePercent(8, 10), 80);
    expect(isPass(scorePercent(8, 10)), isTrue);
    expect(scorePercent(23, 29), 79); // 79.31 → 79
    expect(isPass(scorePercent(23, 29)), isFalse);
    expect(scorePercent(4, 5), 80);
    expect(isPass(79), isFalse);
    expect(scorePercent(0, 0), 0);
  });

  test('간격 반복 1 → 3 → 7일, 틀리면 1일, 7일 칸에서 맞히면 졸업', () {
    final s = CurriculumState();
    s.enqueue('a#1', '2026-11-22');
    expect(s.review.single.due, '2026-11-23');
    s.grade('a#1', true, '2026-11-23');
    expect((s.review.single.due, s.review.single.step), ('2026-11-26', 1));
    s.grade('a#1', true, '2026-11-26');
    expect((s.review.single.due, s.review.single.step), ('2026-12-03', 2));
    s.grade('a#1', false, '2026-12-03');
    expect((s.review.single.due, s.review.single.step), ('2026-12-04', 0));
    s.grade('a#1', true, '2026-12-04');
    s.grade('a#1', true, '2026-12-07');
    s.grade('a#1', true, '2026-12-14');
    expect(s.review, isEmpty);
    // 달 넘김·윤년
    expect(addDays('2028-02-28', 1), '2028-02-29');
    expect(addDays('2026-12-31', 7), '2027-01-07');
  });

  test('만기 복습·하루 목표·연속 일수', () {
    final s = CurriculumState(dailyGoal: 1);
    s.rollDay('2026-11-22');
    s.enqueue('a#1', '2026-11-21'); // 22일 만기
    expect(s.dueOn('2026-11-22').length, 1);
    s.todayNew = 1;
    expect(s.goalDone('2026-11-22'), isFalse);
    s.grade('a#1', true, '2026-11-22');
    expect(s.goalDone('2026-11-22'), isTrue);
    s.touchStreak('2026-11-22');
    expect(s.streakCount, 1);
    s.rollDay('2026-11-23');
    expect(s.todayNew, 0);
    s.todayNew = 1;
    s.touchStreak('2026-11-23');
    expect(s.streakCount, 2);
    s.rollDay('2026-11-25');
    expect(s.goalDone('2026-11-25'), isFalse); // 3일 칸 복습이 25일 만기
    s.grade('a#1', true, '2026-11-25');
    s.todayNew = 1;
    s.touchStreak('2026-11-25');
    expect(s.streakCount, 1);
  });

  test('저장 형식 curriculum_v1 왕복', () {
    final s = CurriculumState(level: 'R1', dailyGoal: 3, course: const CurriculumCourse(id: 'c1', dialogueIds: ['x', 'y'], practiced: ['x'], examScores: [70]));
    s.enqueue('x#2', '2026-11-22');
    final j = json.decode(json.encode(s.toJson())) as Map;
    expect(j.keys, containsAll(['level', 'dailyGoal', 'course', 'passedDialogues', 'review', 'streak']));
    expect((j['course'] as Map).keys, containsAll(['id', 'dialogueIds', 'practiced', 'examScores', 'passedAt']));
    final back = CurriculumState.fromJson(j);
    expect(back.course!.examScores, [70]);
    expect(back.review.single.lineId, 'x#2');
    expect(back.course!.allPracticed, isFalse);
  });

  test('확인 문제: 편마다 줄 수만큼 최대 10, 보기 4개·정답 하나', () {
    final a = _d('r1_life_a1', 'life', 12);
    final b = _d('r1_love_a1', 'love', 6);
    final qs = buildQuestions(a, pool: [b]);
    expect(qs.length, 10);
    for (final q in qs) {
      expect(q.choices.length, 4);
      expect(q.choices.toSet().length, 4);
      expect(q.answer, inInclusiveRange(0, 3));
    }
    expect(qs.map((q) => q.kind).toSet(), {'meaning', 'blank'});
    expect(buildQuestions(b, pool: [a]).length, 6);
    // 시험: 편당 최소 3, 합계 최대 30
    final exam = buildExam([a, b], pool: [a, b]);
    expect(exam.length, lessThanOrEqualTo(30));
    expect(exam.where((q) => q.lineId.startsWith('r1_love_a1')).length, greaterThanOrEqualTo(3));
  });

  test('추천으로 채우기: 통과 안 한 편, 주제 안 겹치게', () {
    final ds = [_d('r1_life_a1', 'life', 3), _d('r1_life_a2', 'life', 3), _d('r1_love_a1', 'love', 3), _d('r1_travel_a1', 'travel', 3)];
    final r = recommend(ds, {'r1_love_a1'}, 2);
    expect(r, ['r1_life_a1', 'r1_travel_a1']);
    expect(recommend(ds, {}, 10).length, 4);
  });
}
