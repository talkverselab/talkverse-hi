import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/prefs.dart';
import 'dialogue_service.dart';

/// 토크버스 커리큘럼(전 언어 공통 기준 `~/talkverse/CURRICULUM_SPEC.md`, 2026-11-22).
/// 회화 레벨(R0~R4)에서 다이얼로그를 골라 코스를 만들고 → 편마다 듣기·확인 문제 → 틀린 줄 간격 반복(1·3·7일)
/// → 코스 시험 80% 이상이면 다음 코스. 하루 목표 = 새 편 1·2·3 + 복습.
/// 저장 = 기기(Prefs 키 `curriculum_v1`, 전 언어 같은 이름·같은 형식). `today` 는 하루 분량 계산용으로 더한 칸.

/// 간격 반복 간격(일). step 0 → 1일, 1 → 3일, 2 → 7일. 7일 칸에서 또 맞히면 졸업(대기열에서 뺌).
const kReviewDays = [1, 3, 7];
const kPassPercent = 80;
const kGoalNew = {1: '가볍게', 2: '보통', 3: '집중'};

String dayKey(DateTime t) => '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
DateTime _day(String k) => DateTime.parse(k);
String addDays(String day, int n) => dayKey(_day(day).add(Duration(days: n, hours: 12)));

/// 점수 = 정답 수 / 문제 수, 소수점 버림.
int scorePercent(int correct, int total) => total == 0 ? 0 : (correct * 100) ~/ total;
bool isPass(int percent) => percent >= kPassPercent;

class ReviewItem {
  final String lineId; // `<편 id>#<줄 번호>`
  final String due; // YYYY-MM-DD
  final int step;
  const ReviewItem(this.lineId, this.due, this.step);
  Map<String, dynamic> toJson() => {'lineId': lineId, 'due': due, 'step': step};
  factory ReviewItem.fromJson(Map j) => ReviewItem('${j['lineId']}', '${j['due']}', (j['step'] as num?)?.toInt() ?? 0);
}

class CurriculumCourse {
  final String id;
  final List<String> dialogueIds;
  final List<String> practiced;
  final List<int> examScores;
  final String? passedAt;
  const CurriculumCourse({required this.id, required this.dialogueIds, this.practiced = const [], this.examScores = const [], this.passedAt});
  bool get allPracticed => dialogueIds.every(practiced.contains);
  Map<String, dynamic> toJson() => {'id': id, 'dialogueIds': dialogueIds, 'practiced': practiced, 'examScores': examScores, 'passedAt': passedAt};
  factory CurriculumCourse.fromJson(Map j) => CurriculumCourse(
        id: '${j['id']}',
        dialogueIds: [for (final e in (j['dialogueIds'] as List? ?? const [])) '$e'],
        practiced: [for (final e in (j['practiced'] as List? ?? const [])) '$e'],
        examScores: [for (final e in (j['examScores'] as List? ?? const [])) (e as num).toInt()],
        passedAt: j['passedAt'] as String?,
      );
  CurriculumCourse copyWith({List<String>? practiced, List<int>? examScores, String? passedAt}) => CurriculumCourse(
      id: id, dialogueIds: dialogueIds, practiced: practiced ?? this.practiced, examScores: examScores ?? this.examScores, passedAt: passedAt ?? this.passedAt);
}

/// 저장 상태 전체. 바꿀 때는 새 값을 만들어 [CurriculumService.save].
class CurriculumState {
  String? level;
  int dailyGoal; // 새 편 수 1·2·3
  CurriculumCourse? course;
  List<String> passedDialogues;
  List<ReviewItem> review;
  int streakCount;
  String? streakLastDay;
  String? todayDay;
  int todayNew;
  int todayReview;

  CurriculumState({
    this.level,
    this.dailyGoal = 2,
    this.course,
    List<String>? passedDialogues,
    List<ReviewItem>? review,
    this.streakCount = 0,
    this.streakLastDay,
    this.todayDay,
    this.todayNew = 0,
    this.todayReview = 0,
  })  : passedDialogues = passedDialogues ?? [],
        review = review ?? [];

  Map<String, dynamic> toJson() => {
        'level': level,
        'dailyGoal': dailyGoal,
        'course': course?.toJson(),
        'passedDialogues': passedDialogues,
        'review': [for (final r in review) r.toJson()],
        'streak': {'count': streakCount, 'lastDay': streakLastDay},
        'today': {'day': todayDay, 'new': todayNew, 'review': todayReview},
      };

  factory CurriculumState.fromJson(Map j) {
    final s = (j['streak'] as Map?) ?? const {};
    final t = (j['today'] as Map?) ?? const {};
    return CurriculumState(
      level: j['level'] as String?,
      dailyGoal: ((j['dailyGoal'] as num?)?.toInt() ?? 2).clamp(1, 3),
      course: j['course'] is Map ? CurriculumCourse.fromJson(j['course'] as Map) : null,
      passedDialogues: [for (final e in (j['passedDialogues'] as List? ?? const [])) '$e'],
      review: [for (final e in (j['review'] as List? ?? const [])) if (e is Map) ReviewItem.fromJson(e)],
      streakCount: (s['count'] as num?)?.toInt() ?? 0,
      streakLastDay: s['lastDay'] as String?,
      todayDay: t['day'] as String?,
      todayNew: (t['new'] as num?)?.toInt() ?? 0,
      todayReview: (t['review'] as num?)?.toInt() ?? 0,
    );
  }

  /// 날이 바뀌었으면 오늘 칸을 비운다.
  void rollDay(String today) {
    if (todayDay == today) return;
    todayDay = today;
    todayNew = 0;
    todayReview = 0;
  }

  List<ReviewItem> dueOn(String today) => review.where((r) => r.due.compareTo(today) <= 0).toList();

  /// 줄을 대기열에 넣는다(이미 있으면 그대로). 새로 넣는 줄은 내일 첫 복습.
  void enqueue(String lineId, String today) {
    if (review.any((r) => r.lineId == lineId)) return;
    review.add(ReviewItem(lineId, addDays(today, kReviewDays[0]), 0));
  }

  /// 문제 결과를 대기열에 반영 — 맞히면 다음 간격(7일 칸에서 맞히면 졸업), 틀리면 1일 칸으로.
  void grade(String lineId, bool correct, String today) {
    final i = review.indexWhere((r) => r.lineId == lineId);
    final step = i < 0 ? -1 : review[i].step;
    ReviewItem? next;
    if (!correct) {
      next = ReviewItem(lineId, addDays(today, kReviewDays[0]), 0);
    } else if (i < 0) {
      next = ReviewItem(lineId, addDays(today, kReviewDays[0]), 0);
    } else if (step + 1 < kReviewDays.length) {
      next = ReviewItem(lineId, addDays(today, kReviewDays[step + 1]), step + 1);
    }
    if (i >= 0) review.removeAt(i);
    if (next != null) review.add(next);
  }

  /// 오늘 분량을 다 했는지 — 새 편 목표 + 오늘 만기 복습이 비었는지.
  bool goalDone(String today) => todayDay == today && todayNew >= dailyGoal && dueOn(today).isEmpty;

  /// 오늘 분량을 막 끝냈으면 연속 일수를 올린다.
  void touchStreak(String today) {
    if (!goalDone(today) || streakLastDay == today) return;
    streakCount = streakLastDay != null && addDays(streakLastDay!, 1) == today ? streakCount + 1 : 1;
    streakLastDay = today;
  }
}

/// 확인 문제 한 개. kind: meaning(힌디어 → 뜻 고르기) · blank(빈칸 낱말 고르기).
class CurriculumQuestion {
  final String lineId;
  final String kind;
  final String prompt; // 화면 위 문장(blank 면 ＿＿ 자리)
  final String sub; // 보조 줄(blank 면 뜻)
  final String speak; // 읽어 줄 힌디어 전체
  final String gender;
  final List<String> choices;
  final int answer;
  const CurriculumQuestion({required this.lineId, required this.kind, required this.prompt, required this.sub, required this.speak, required this.gender, required this.choices, required this.answer});
}

String cleanTl(String s) => s.replaceAll(RegExp(r'\([^)]*\)'), '').replaceAll(RegExp(r'\{[a-z_]+\}'), '').replaceAll(RegExp(r'\s+'), ' ').trim();
String cleanKo(String s, String name) => s.replaceAll('{name}', name).replaceAll(RegExp(r'[{}]'), '').trim();
final _punct = RegExp(r'[।॥,.!?;:"“”‘’…—\-]');
List<String> _words(String tl) => [for (final w in cleanTl(tl).split(' ')) if (w.replaceAll(_punct, '').isNotEmpty) w.replaceAll(_punct, '')];

/// 편 하나의 줄로 문제를 만든다(줄마다 하나, 최대 [max]). 뜻 고르기와 빈칸을 번갈아. [pool] = 오답 보기 후보로 쓸 다른 편.
List<CurriculumQuestion> buildQuestions(Dialogue d, {List<Dialogue> pool = const [], int max = 10, int seed = 0, Set<int>? onlyNums}) {
  final rnd = Random(seed ^ d.id.hashCode);
  final turns = [for (final t in d.turns) if (cleanTl(t.tl).isNotEmpty && t.ko.trim().isNotEmpty && (onlyNums == null || onlyNums.contains(t.num))) t];
  final allTurns = [...d.turns, for (final o in pool) if (o.id != d.id) ...o.turns];
  final kos = {for (final t in allTurns) cleanKo(t.ko, '나')}.where((k) => k.isNotEmpty).toList();
  final words = {for (final t in allTurns) ..._words(t.tl)}.where((w) => w.runes.length >= 2).toList();
  final picked = [...turns]..shuffle(rnd);
  final out = <CurriculumQuestion>[];
  for (final t in picked.take(max)) {
    final tl = cleanTl(t.tl);
    final ko = cleanKo(t.ko, d.speakerName('A'));
    final lineId = '${d.id}#${t.num}';
    final gender = d.voiceGender(t.speaker);
    final ws = _words(t.tl).where((w) => w.runes.length >= 2).toList();
    final wantBlank = out.length.isOdd && ws.isNotEmpty;
    if (wantBlank) {
      ws.sort((a, b) => b.runes.length.compareTo(a.runes.length));
      final target = ws[rnd.nextInt(min(3, ws.length))];
      final wrong = (words.where((w) => w != target && !ws.contains(w)).toList()..shuffle(rnd)).take(3).toList();
      if (wrong.length == 3) {
        final choices = [target, ...wrong]..shuffle(rnd);
        out.add(CurriculumQuestion(
            lineId: lineId, kind: 'blank', prompt: tl.replaceFirst(target, '＿＿'), sub: ko, speak: tl, gender: gender, choices: choices, answer: choices.indexOf(target)));
        continue;
      }
    }
    final wrong = (kos.where((k) => k != cleanKo(t.ko, '나')).toList()..shuffle(rnd)).take(3).toList();
    if (wrong.length < 3) continue;
    final choices = [ko, ...wrong]..shuffle(rnd);
    out.add(CurriculumQuestion(lineId: lineId, kind: 'meaning', prompt: tl, sub: '', speak: tl, gender: gender, choices: choices, answer: choices.indexOf(ko)));
  }
  return out;
}

/// 코스 시험 — 편당 최소 3문제, 합계 최대 30문제.
List<CurriculumQuestion> buildExam(List<Dialogue> ds, {List<Dialogue> pool = const [], int seed = 0}) {
  if (ds.isEmpty) return const [];
  final per = max(3, 30 ~/ ds.length);
  final out = <CurriculumQuestion>[for (final d in ds) ...buildQuestions(d, pool: pool, max: per, seed: seed + 7)];
  out.shuffle(Random(seed));
  return out.take(30).toList();
}

/// 추천으로 채우기 — 아직 통과하지 않은 편에서 주제(island)가 겹치지 않게 돌려 가며.
List<String> recommend(List<Dialogue> levelDialogues, Set<String> passed, int n, {Set<String> already = const {}}) {
  final left = levelDialogues.where((d) => !passed.contains(d.id) && !already.contains(d.id)).toList();
  final byIsland = <String, List<Dialogue>>{};
  for (final d in left) {
    byIsland.putIfAbsent(d.island, () => []).add(d);
  }
  final out = <String>[...already];
  while (out.length < n && byIsland.values.any((l) => l.isNotEmpty)) {
    for (final l in byIsland.values) {
      if (l.isNotEmpty && out.length < n) out.add(l.removeAt(0).id);
    }
  }
  // 남은 편이 모자라면 통과한 편으로 채운다(다시 고를 수 있음)
  for (final d in levelDialogues) {
    if (out.length >= n) break;
    if (!out.contains(d.id)) out.add(d.id);
  }
  return out;
}

class CurriculumService {
  CurriculumService._();
  static final CurriculumService instance = CurriculumService._();
  static const key = 'curriculum_v1';

  /// 저장할 때마다 오른다(홈 카드가 다시 그림).
  final ValueNotifier<int> revision = ValueNotifier(0);

  /// 시험에서 날짜를 바꿔 보려고 둔 시계.
  @visibleForTesting
  DateTime Function() clock = DateTime.now;
  String get today => dayKey(clock());

  Future<CurriculumState> load() async {
    final raw = (await Prefs.getInstance()).getString(key);
    CurriculumState s;
    try {
      s = raw == null ? CurriculumState() : CurriculumState.fromJson(json.decode(raw) as Map);
    } catch (_) {
      s = CurriculumState();
    }
    s.rollDay(today);
    return s;
  }

  Future<void> save(CurriculumState s) async {
    s.touchStreak(today);
    await (await Prefs.getInstance()).setString(key, json.encode(s.toJson()));
    revision.value++;
  }

  /// 회화 레벨(R0~R4) 중 편이 있는 것만, 낮은 순.
  static List<String> levels() {
    final rs = DialogueService.instance.regions.where((r) => RegExp(r'^R\d$').hasMatch(r)).toList()..sort();
    return rs;
  }

  /// 편 하나 연습(확인 문제) 결과 반영. 처음 연습한 편이면 오늘 새 편 수 +1.
  void applyPractice(CurriculumState s, Dialogue d, Map<String, bool> results) {
    final t = today;
    final c = s.course;
    if (c != null && !c.practiced.contains(d.id)) {
      s.course = c.copyWith(practiced: [...c.practiced, d.id]);
      s.todayNew++;
    }
    for (final turn in d.turns) {
      s.enqueue('${d.id}#${turn.num}', t);
    }
    for (final e in results.entries) {
      if (!e.value) s.grade(e.key, false, t);
    }
  }

  /// 복습 결과 반영.
  void applyReview(CurriculumState s, Map<String, bool> results) {
    for (final e in results.entries) {
      s.grade(e.key, e.value, today);
    }
    s.todayReview += results.length;
  }

  /// 코스 시험 결과. 통과면 편을 통과 목록에 넣고 코스를 닫는다. 레벨의 편을 다 통과하면 다음 레벨로. 돌려주는 값 = 점수.
  int applyExam(CurriculumState s, Map<String, bool> results) {
    final c = s.course!;
    final score = scorePercent(results.values.where((v) => v).length, results.length);
    for (final e in results.entries) {
      s.grade(e.key, e.value, today);
    }
    if (isPass(score)) {
      s.passedDialogues = {...s.passedDialogues, ...c.dialogueIds}.toList();
      // 통과한 코스는 passedAt 을 달아 남겨 두고(결과 화면), 「다음 코스」를 누르면 비운다
      s.course = c.copyWith(examScores: [...c.examScores, score], passedAt: today);
      final lv = s.level;
      if (lv != null) {
        final all = DialogueService.instance.list(region: lv).map((d) => d.id);
        if (all.every(s.passedDialogues.contains)) {
          final ls = levels();
          final i = ls.indexOf(lv);
          if (i >= 0 && i + 1 < ls.length) s.level = ls[i + 1];
        }
      }
    } else {
      // 틀린 편만 다시 연습
      final wrongDs = {for (final e in results.entries) if (!e.value) e.key.split('#').first};
      s.course = c.copyWith(practiced: c.practiced.where((id) => !wrongDs.contains(id)).toList(), examScores: [...c.examScores, score]);
    }
    return score;
  }
}
