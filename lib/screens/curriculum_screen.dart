import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/pane.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/curriculum_service.dart';
import '../services/dialogue_service.dart';
import '../services/tts_service.dart';
import 'dialogue_screen.dart';

/// 토크버스 커리큘럼(전 언어 공통 `~/talkverse/CURRICULUM_SPEC.md`, 2026-11-22).
/// 홈 카드 [CurriculumHomeCard] → [CurriculumScreen](레벨 고르기 → 다이얼로그 고르기 → 편마다 연습 → 코스 시험).

String _levelName(String r) => '$r · ${tr(DialogueService.levelKo[r] ?? r)}';

/// 홈 맨 위 카드 — 「오늘: 복습 N · 새 편 N」과 진행 막대, 다 하면 「오늘 분량 끝」·연속 일수.
class CurriculumHomeCard extends StatefulWidget {
  const CurriculumHomeCard({super.key});
  @override
  State<CurriculumHomeCard> createState() => _CurriculumHomeCardState();
}

class _CurriculumHomeCardState extends State<CurriculumHomeCard> {
  CurriculumState? _s;
  final _svc = CurriculumService.instance;

  @override
  void initState() {
    super.initState();
    _svc.revision.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    _svc.revision.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final s = await _svc.load();
    if (mounted) setState(() => _s = s);
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    final today = _svc.today;
    final due = s?.dueOn(today).length ?? 0;
    final newLeft = s == null ? 0 : (s.dailyGoal - s.todayNew).clamp(0, 3);
    final total = s == null ? 1 : s.dailyGoal + due + s.todayReview;
    final done = s == null ? 0 : s.todayNew.clamp(0, s.dailyGoal) + s.todayReview;
    final finished = s?.goalDone(today) ?? false;
    final String line;
    if (s == null || s.level == null) {
      line = tr('레벨을 고르고 회화로 코스를 만들어요');
    } else if (finished) {
      line = trf('오늘 분량 끝 · 연속 {0}일', [s.streakCount]);
    } else {
      line = trf('오늘: 복습 {0} · 새 편 {1}', [due, newLeft]);
    }
    return InkWell(
      onTap: () => openPane(context, (_) => const CurriculumScreen()),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.cal,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.rojoLight),
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.rojo, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.school_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('토크버스 커리큘럼'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.sumi)),
              const SizedBox(height: 3),
              Text(
                s?.level == null ? line : '${_levelName(s!.level!)} · $line',
                style: TextStyle(fontSize: 12, color: finished ? AppColors.matcha : AppColors.sumiLight, fontWeight: finished ? FontWeight.w700 : FontWeight.w500),
              ),
              if (s?.level != null) ...[
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: finished ? 1 : (done / (total == 0 ? 1 : total)).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: AppColors.line,
                    color: finished ? AppColors.matcha : AppColors.rojo,
                  ),
                ),
              ],
            ]),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
        ]),
      ),
    );
  }
}

/// 커리큘럼 본 화면. 상태에 따라 레벨 고르기 · 다이얼로그 고르기 · 코스 진행 · 통과 결과를 그린다.
class CurriculumScreen extends StatefulWidget {
  const CurriculumScreen({super.key});
  @override
  State<CurriculumScreen> createState() => _CurriculumScreenState();
}

class _CurriculumScreenState extends State<CurriculumScreen> {
  final _svc = CurriculumService.instance;
  CurriculumState? _s;
  bool _pickLevel = false;
  // 다이얼로그 고르기
  int _size = 5;
  final List<String> _picked = [];
  bool _confirmAbandon = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await DialogueService.instance.ensureLoaded();
    final s = await _svc.load();
    if (mounted) setState(() => _s = s);
  }

  Future<void> _save() async {
    await _svc.save(_s!);
    if (mounted) setState(() {});
  }

  List<Dialogue> get _levelDs => _s?.level == null ? const [] : DialogueService.instance.list(region: _s!.level);

  @override
  Widget build(BuildContext context) {
    final s = _s;
    Widget body;
    if (s == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (s.level == null || _pickLevel) {
      body = _levelPicker(s);
    } else if (s.course == null || _confirmAbandon) {
      body = _confirmAbandon ? _abandonView(s) : _coursePicker(s);
    } else if (s.course!.passedAt != null) {
      body = _passedView(s);
    } else {
      body = _courseView(s);
    }
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(
        title: Text(tr('토크버스 커리큘럼'), style: const TextStyle(color: AppColors.sumi, fontWeight: FontWeight.w800, fontSize: 16)),
        actions: [
          if (s?.level != null && !_pickLevel)
            TextButton(onPressed: () => setState(() => _pickLevel = true), child: Text(_levelName(s!.level!), style: const TextStyle(color: AppColors.rojo, fontSize: 12))),
        ],
      ),
      body: body,
    );
  }

  EdgeInsets _pad(BuildContext c) => EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset(c));

  // ── 레벨 고르기 ──
  Widget _levelPicker(CurriculumState s) {
    final ls = CurriculumService.levels();
    return ListView(padding: _pad(context), children: [
      Text(tr('레벨을 고르세요'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.sumi)),
      const SizedBox(height: 4),
      Text(tr('처음이면 가장 낮은 레벨부터 권해요.'), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      const SizedBox(height: 12),
      for (final (i, r) in ls.indexed)
        Card(
          elevation: 0,
          color: s.level == r ? AppColors.washiDeep : AppColors.cal,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: s.level == r ? AppColors.rojo : AppColors.line)),
          child: ListTile(
            title: Text(_levelName(r), style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(trf('회화 {0}편 · 통과 {1}편', [
              DialogueService.instance.count(r),
              DialogueService.instance.list(region: r).where((d) => s.passedDialogues.contains(d.id)).length,
            ])),
            trailing: s.level == null && i == 0
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.rojo, borderRadius: BorderRadius.circular(10)),
                    child: Text(tr('추천'), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)))
                : null,
            onTap: () async {
              if (s.level != r) {
                s.level = r;
                // 다른 레벨로 옮기면 진행 중 코스는 그대로 두지 않는다(레벨이 섞이지 않게)
                if (s.course != null && s.course!.dialogueIds.any((id) => DialogueService.instance.byId(id)?.region != r)) s.course = null;
                _picked.clear();
                await _save();
              }
              setState(() => _pickLevel = false);
            },
          ),
        ),
    ]);
  }

  // ── 다이얼로그 고르기 ──
  Widget _coursePicker(CurriculumState s) {
    final ds = _levelDs;
    final passed = s.passedDialogues.toSet();
    _size = _size.clamp(1, 10);
    final cap = ds.length < _size ? ds.length : _size;
    return ListView(padding: _pad(context), children: [
      Text(tr('이번 코스에서 연습할 회화를 고르세요'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.sumi)),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Text(tr('개수'), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        for (final n in const [3, 5, 10])
          ChoiceChip(
            label: Text('$n'),
            selected: _size == n,
            onSelected: (_) => setState(() {
              _size = n;
              while (_picked.length > n) {
                _picked.removeLast();
              }
            }),
          ),
        OutlinedButton.icon(
          onPressed: () => setState(() {
            final r = recommend(ds, passed, cap);
            _picked
              ..clear()
              ..addAll(r);
          }),
          icon: const Icon(Icons.auto_awesome, size: 16),
          label: Text(tr('추천으로 채우기')),
        ),
      ]),
      const SizedBox(height: 12),
      _goalRow(s),
      const SizedBox(height: 8),
      for (final d in ds)
        CheckboxListTile(
          value: _picked.contains(d.id),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: (v) => setState(() {
            if (v == true) {
              if (_picked.length < _size) _picked.add(d.id);
            } else {
              _picked.remove(d.id);
            }
          }),
          title: Text('${d.emoji} ${d.title}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: Text('${tr(DialogueService.islandKo[d.island] ?? d.island)} · ${d.turns.length}${tr('턴')}${passed.contains(d.id) ? ' · ${tr('통과')} ✓' : ''}',
              style: TextStyle(fontSize: 11, color: passed.contains(d.id) ? AppColors.matcha : AppColors.muted)),
        ),
      const SizedBox(height: 12),
      FilledButton(
        onPressed: _picked.isEmpty
            ? null
            : () async {
                s.course = CurriculumCourse(id: 'c${DateTime.now().millisecondsSinceEpoch}', dialogueIds: List.of(_picked));
                _picked.clear();
                await _save();
              },
        style: FilledButton.styleFrom(backgroundColor: AppColors.rojo, padding: const EdgeInsets.symmetric(vertical: 14)),
        child: Text(trf('코스 시작 ({0}편)', [_picked.length])),
      ),
    ]);
  }

  Widget _goalRow(CurriculumState s) => Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Text(tr('하루 목표'), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        for (final e in kGoalNew.entries)
          ChoiceChip(
            label: Text(trf('{0}(새 편 {1})', [tr(e.value), e.key])),
            selected: s.dailyGoal == e.key,
            onSelected: (_) async {
              s.dailyGoal = e.key;
              await _save();
            },
          ),
      ]);

  Widget _abandonView(CurriculumState s) => Padding(
        padding: _pad(context),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(tr('지금 코스를 그만두고 새 코스를 만들까요?'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(tr('통과한 회화와 복습 기록은 그대로 남아요.'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.beni),
            onPressed: () async {
              s.course = null;
              _confirmAbandon = false;
              await _save();
            },
            child: Text(tr('새 코스 만들기')),
          ),
          TextButton(onPressed: () => setState(() => _confirmAbandon = false), child: Text(tr('지금 코스 계속하기'))),
        ]),
      );

  // ── 코스 진행 ──
  Widget _courseView(CurriculumState s) {
    final c = s.course!;
    final ds = [for (final id in c.dialogueIds) DialogueService.instance.byId(id)].whereType<Dialogue>().toList();
    final due = s.dueOn(_svc.today);
    return ListView(padding: _pad(context), children: [
      _goalRow(s),
      const SizedBox(height: 12),
      if (due.isNotEmpty)
        _box(
          color: AppColors.lusa,
          icon: Icons.replay_rounded,
          title: trf('오늘 복습 {0}줄', [due.length]),
          sub: tr('복습을 먼저 해요'),
          onTap: () => _runReview(s),
        ),
      Padding(
        padding: const EdgeInsets.fromLTRB(2, 8, 2, 6),
        child: Text(trf('이번 코스 · 연습 {0}/{1}편', [c.practiced.where(c.dialogueIds.contains).length, c.dialogueIds.length]),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.gualdaDeep)),
      ),
      for (final d in ds)
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.line)),
          child: ListTile(
            leading: Text(d.emoji, style: const TextStyle(fontSize: 24)),
            title: Text(d.title, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(c.practiced.contains(d.id) ? tr('연습 끝') : tr('듣기 → 확인 문제'),
                style: TextStyle(fontSize: 11, color: c.practiced.contains(d.id) ? AppColors.matcha : AppColors.muted)),
            trailing: Icon(c.practiced.contains(d.id) ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
                color: c.practiced.contains(d.id) ? AppColors.matcha : AppColors.muted),
            onTap: () async {
              await openFull(context, (_) => _PracticeScreen(dialogue: d, pool: _levelDs));
              await _load();
            },
          ),
        ),
      const SizedBox(height: 12),
      if (c.examScores.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(trf('지난 시험 {0}% — 틀린 회화를 다시 연습한 뒤 다시 시험', [c.examScores.last]),
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AppColors.beni)),
        ),
      FilledButton.icon(
        onPressed: c.allPracticed ? () => _runExam(s, ds) : null,
        style: FilledButton.styleFrom(backgroundColor: AppColors.rojo, padding: const EdgeInsets.symmetric(vertical: 14)),
        icon: const Icon(Icons.flag_rounded),
        label: Text(c.allPracticed ? tr('코스 시험 보기 (80% 이상 통과)') : tr('모든 회화를 연습하면 코스 시험')),
      ),
      const SizedBox(height: 8),
      TextButton(onPressed: () => setState(() => _confirmAbandon = true), child: Text(tr('새 코스 만들기'), style: const TextStyle(color: AppColors.muted))),
    ]);
  }

  Widget _passedView(CurriculumState s) {
    final c = s.course!;
    return Padding(
      padding: _pad(context),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Icon(Icons.emoji_events_rounded, size: 64, color: AppColors.gualdaBright),
        const SizedBox(height: 8),
        Text(trf('코스 통과 {0}%', [c.examScores.isEmpty ? 0 : c.examScores.last]),
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.matcha)),
        const SizedBox(height: 6),
        Text(trf('지금 레벨: {0}', [_levelName(s.level ?? '')]), textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.sumiLight)),
        const SizedBox(height: 20),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.rojo, padding: const EdgeInsets.symmetric(vertical: 14)),
          onPressed: () async {
            s.course = null;
            await _save();
          },
          child: Text(tr('다음 코스 고르기')),
        ),
      ]),
    );
  }

  Widget _box({required Color color, required IconData icon, required String title, required String sub, required VoidCallback onTap}) => Card(
        elevation: 0,
        color: color.withValues(alpha: .08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: color)),
        child: ListTile(leading: Icon(icon, color: color), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(sub), onTap: onTap),
      );

  Future<void> _runReview(CurriculumState s) async {
    final due = s.dueOn(_svc.today);
    final byD = <String, Set<int>>{};
    for (final r in due) {
      final p = r.lineId.split('#');
      if (p.length == 2) byD.putIfAbsent(p[0], () => {}).add(int.tryParse(p[1]) ?? -1);
    }
    final qs = <CurriculumQuestion>[
      for (final e in byD.entries)
        if (DialogueService.instance.byId(e.key) case final d?) ...buildQuestions(d, pool: DialogueService.instance.list(region: d.region), onlyNums: e.value, max: 99, seed: s.todayReview + 3),
    ];
    // 지워졌거나 문제를 못 만드는 줄은 대기열에서 졸업시킨다
    final asked = qs.map((q) => q.lineId).toSet();
    s.review.removeWhere((r) => due.any((x) => x.lineId == r.lineId) && !asked.contains(r.lineId));
    if (qs.isEmpty) return _save();
    final res = await openFull<Map<String, bool>>(context, (_) => CurriculumQuizScreen(title: tr('복습'), questions: qs));
    if (res == null || res.isEmpty) return;
    final fresh = await _svc.load();
    _svc.applyReview(fresh, res);
    _s = fresh;
    await _save();
  }

  Future<void> _runExam(CurriculumState s, List<Dialogue> ds) async {
    final qs = buildExam(ds, pool: _levelDs, seed: s.course!.examScores.length);
    final res = await openFull<Map<String, bool>>(context, (_) => CurriculumQuizScreen(title: tr('코스 시험'), questions: qs, exam: true));
    if (res == null || res.length < qs.length) return; // 끝까지 안 풀면 기록하지 않는다
    final fresh = await _svc.load();
    _svc.applyExam(fresh, res);
    _s = fresh;
    await _save();
  }
}

/// 편 하나 연습 — ① 듣기·읽기 ② 따라 말하기(선택, 줄을 눌러 반복) ③ 확인 문제.
class _PracticeScreen extends StatelessWidget {
  final Dialogue dialogue;
  final List<Dialogue> pool;
  const _PracticeScreen({required this.dialogue, required this.pool});

  @override
  Widget build(BuildContext context) {
    final d = dialogue;
    Widget step(String n, String title, String sub, VoidCallback onTap, {bool main = false}) => Card(
          elevation: 0,
          color: main ? AppColors.rojo.withValues(alpha: .07) : AppColors.cal,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: main ? AppColors.rojo : AppColors.line)),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: main ? AppColors.rojo : AppColors.gualdaDeep, foregroundColor: Colors.white, child: Text(n)),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(sub, style: const TextStyle(fontSize: 12)),
            onTap: onTap,
          ),
        );
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(title: Text('${d.emoji} ${d.title}', style: const TextStyle(color: AppColors.sumi, fontWeight: FontWeight.w800, fontSize: 15))),
      body: ListView(padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset(context)), children: [
        Text(d.sceneShown, style: const TextStyle(fontSize: 12, color: AppColors.sumiLight, height: 1.4)),
        const SizedBox(height: 12),
        step('1', tr('듣기·읽기'), tr('「모든 문장 듣기」로 회화 전체를 듣고 줄마다 뜻을 봐요'),
            () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DialogueScreen(dialogue: d)))),
        step('2', tr('따라 말하기 (선택)'), tr('줄을 눌러 한 줄씩 반복해 듣고 따라 말해요 — 점수는 없어요'),
            () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DialogueScreen(dialogue: d)))),
        step('3', tr('확인 문제'), tr('뜻 고르기 · 빈칸 낱말 고르기, 최대 10문제'), () async {
          final qs = buildQuestions(d, pool: pool, seed: DateTime.now().day);
          final res = await Navigator.of(context).push<Map<String, bool>>(
              MaterialPageRoute(builder: (_) => CurriculumQuizScreen(title: d.title, questions: qs)));
          if (res == null || res.length < qs.length) return;
          final svc = CurriculumService.instance;
          final s = await svc.load();
          svc.applyPractice(s, d, res);
          await svc.save(s);
          if (context.mounted) Navigator.of(context).pop();
        }, main: true),
      ]),
    );
  }
}

/// 4지선다 문제 풀이 — 끝나면 {lineId: 맞음} 을 돌려준다(같은 줄이 두 번 나오면 둘 다 맞아야 맞음).
class CurriculumQuizScreen extends StatefulWidget {
  final String title;
  final List<CurriculumQuestion> questions;
  final bool exam;
  const CurriculumQuizScreen({super.key, required this.title, required this.questions, this.exam = false});
  @override
  State<CurriculumQuizScreen> createState() => _CurriculumQuizScreenState();
}

class _CurriculumQuizScreenState extends State<CurriculumQuizScreen> {
  int _i = 0;
  int? _chosen;
  int _correct = 0;
  final Map<String, bool> _res = {};

  List<CurriculumQuestion> get _qs => widget.questions;

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
  }

  void _choose(int k) {
    if (_chosen != null) return;
    final q = _qs[_i];
    final ok = k == q.answer;
    setState(() {
      _chosen = k;
      if (ok) _correct++;
      _res[q.lineId] = (_res[q.lineId] ?? true) && ok;
    });
    TtsService.instance.speakAs(q.speak, gender: q.gender);
  }

  void _next() => setState(() {
        _i++;
        _chosen = null;
      });

  @override
  Widget build(BuildContext context) {
    final total = _qs.length;
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(title: Text(widget.title, style: const TextStyle(color: AppColors.sumi, fontWeight: FontWeight.w800, fontSize: 15))),
      body: total == 0
          ? Center(child: Text(tr('문제를 만들 줄이 없어요')))
          : _i >= total
              ? _result(total)
              : _question(_qs[_i], total),
    );
  }

  Widget _result(int total) {
    final p = scorePercent(_correct, total);
    final pass = isPass(p);
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset(context)),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('$p%', textAlign: TextAlign.center, style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: !widget.exam || pass ? AppColors.matcha : AppColors.beni)),
        Text(trf('{0}문제 중 {1}개 맞음', [total, _correct]), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.sumiLight)),
        if (widget.exam) ...[
          const SizedBox(height: 8),
          Text(pass ? tr('통과! 다음 코스로 넘어가요') : tr('80% 미만 — 틀린 회화만 다시 연습해요'),
              textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, color: pass ? AppColors.matcha : AppColors.beni)),
        ],
        const SizedBox(height: 24),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.rojo, padding: const EdgeInsets.symmetric(vertical: 14)),
          onPressed: () => Navigator.of(context).pop(_res),
          child: Text(tr('마침')),
        ),
      ]),
    );
  }

  Widget _question(CurriculumQuestion q, int total) {
    final answered = _chosen != null;
    return ListView(padding: EdgeInsets.fromLTRB(16, 12, 16, 24 + bottomInset(context)), children: [
      LinearProgressIndicator(value: _i / total, backgroundColor: AppColors.line, color: AppColors.rojo),
      const SizedBox(height: 6),
      Text('${_i + 1} / $total · ${q.kind == 'blank' ? tr('빈칸에 들어갈 낱말') : tr('알맞은 뜻')}', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: Text(q.prompt, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.sumi, height: 1.4))),
        IconButton(
          tooltip: tr('듣기'),
          icon: const Icon(Icons.volume_up_rounded, color: AppColors.rojo),
          onPressed: q.kind == 'blank' && !answered ? null : () => TtsService.instance.speakAs(q.speak, gender: q.gender),
        ),
      ]),
      if (q.sub.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(q.sub, style: const TextStyle(fontSize: 13, color: AppColors.sumiLight))),
      const SizedBox(height: 16),
      for (final (k, c) in q.choices.indexed)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: OutlinedButton(
            onPressed: () => _choose(k),
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              backgroundColor: !answered
                  ? AppColors.cal
                  : k == q.answer
                      ? AppColors.matcha.withValues(alpha: .12)
                      : k == _chosen
                          ? AppColors.beni.withValues(alpha: .10)
                          : AppColors.cal,
              side: BorderSide(color: answered && k == q.answer ? AppColors.matcha : answered && k == _chosen ? AppColors.beni : AppColors.line),
            ),
            child: Text(c, style: TextStyle(fontSize: q.kind == 'blank' ? 18 : 14, color: AppColors.sumi)),
          ),
        ),
      if (answered) ...[
        if (q.kind == 'blank') Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(q.speak, style: const TextStyle(fontSize: 15, color: AppColors.matcha))),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.rojo, padding: const EdgeInsets.symmetric(vertical: 14)),
          onPressed: _next,
          child: Text(_i + 1 >= total ? tr('결과 보기') : tr('다음')),
        ),
      ],
    ]);
  }
}
