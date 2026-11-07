import 'dart:async';

import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/pane.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../screens/dialogue_card_screen.dart';
import '../services/achievement_service.dart';
import '../services/art_service.dart';
import '../services/devanagari.dart';
import '../services/dialogue_service.dart';
import '../services/ko_reading.dart';
import '../services/learner_prefs.dart';
import '../services/content_sync.dart';
import '../services/tts_service.dart';
import '../data/db/app_database.dart';
import 'learner_setup_dialog.dart';
import 'lemma_chips.dart';
import 'achievement_desk.dart';

/// 「모든 문장 듣기」 재생 패널 — 일본어앱 Grok UXUI 시안 02 「만화책 읽기형」을 옮김(2026-11-02, 일본어앱 `data/review/uxui/sian_02.md`).
///
/// 장면 컷이 주인공. 아이패드(가로 720 이상): 왼쪽 = 대화 스크립트 목록(번호·화자·힌디어·한국어), 오른쪽 = 큰 장면 컷(말풍선) + 현재 문장 캡션.
/// 폰: 장면 컷이 위(화면 대부분), 스크립트가 아래. 하단 고정 컨트롤 = ▶ 재생 · 진행 슬라이더 · 속도 · 자막 단계(힌디어/단어 뜻/독음/한국어).
/// 컷 전환은 400ms 페이드. 그림: 턴 `art`(장면 그림) → 핵심 단어 그림 → 장면 카드. 장면 그림은 나중에 JSON `art` 에 채운다.
/// `autoPlay: false` 면 편 화면(읽기 모드)으로도 쓴다 — 같은 레이아웃에서 ▶ 를 누르면 순차 재생.
class EpisodePlayPane extends StatefulWidget {
  final Dialogue dialogue;
  final int initialIndex;
  final bool autoPlay;
  const EpisodePlayPane({super.key, required this.dialogue, this.initialIndex = 0, this.autoPlay = true});

  @override
  State<EpisodePlayPane> createState() => _EpisodePlayPaneState();
}

class _EpisodePlayPaneState extends State<EpisodePlayPane> {
  late int _i = widget.initialIndex;
  bool _playing = false;
  double _rate = 1.0; // 0.75 / 1.0 / 1.25
  bool _showGloss = false;
  bool get _showRd => KoReadingPrefs.show.value; // 전역 설정(기본 미표시)
  bool _showKo = true;
  int _session = 0; // 재생 루프 세대(중단 판별)
  bool _done = false; // 완주 연출 표시
  bool _firstDone = false;
  String? _word; // 글자 풀이 중인 낱말(UX 시안 01)
  late final List<GlobalKey> _keys = List.generate(widget.dialogue.turns.length, (_) => GlobalKey());

  Dialogue get d => widget.dialogue;
  DialogueTurn get turn => d.turns[_i];

  void _onRd() { if (mounted) setState(() {}); }

  @override
  void initState() {
    super.initState();
    KoReadingPrefs.show.addListener(_onRd);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // 대사에 {name} 자리가 있는데 이름이 없으면 먼저 묻는다(앱 켠 뒤 한 번 — 일본어앱 2026-11-04)
      await ensureLearnerName(context, needed: widget.dialogue.turns.any((t) => t.tl.contains('{name}')));
      if (mounted) setState(() {});
      if (widget.autoPlay && mounted) _play();
    });
  }

  @override
  void dispose() {
    KoReadingPrefs.show.removeListener(_onRd);
    _session++;
    TtsService.instance.stop();
    super.dispose();
  }

  Future<void> _play() async {
    final my = ++_session;
    setState(() => _playing = true);
    while (mounted && my == _session && _i < d.turns.length) {
      final t = d.turns[_i];
      _scrollTo(_i);
      await TtsService.instance.speakAs(_ttsText(t), gender: _gender(t.speaker), rate: _rate * 0.45);
      if (!mounted || my != _session) return;
      await Future.delayed(Duration(milliseconds: (650 / _rate).round())); // 턴 사이 숨
      if (!mounted || my != _session) return;
      if (_i >= d.turns.length - 1) {
        // 끝까지 들었다 → 성과 기록 + 순간 연출(시안 02: 확대·강조색·진동, 폭죽 없음)
        final first = await AchievementService.instance.markEpisodeDone(d.id);
        if (mounted && my == _session) setState(() { _done = true; _firstDone = first; });
        break;
      }
      setState(() { _i++; _word = null; });
    }
    if (mounted && my == _session) setState(() => _playing = false);
  }

  void _pause() {
    _session++;
    TtsService.instance.stop();
    setState(() => _playing = false);
  }

  void _goto(int n, {bool play = false}) {
    n = n.clamp(0, d.turns.length - 1);
    _session++;
    TtsService.instance.stop();
    setState(() {
      _i = n;
      _playing = false;
      _word = null;
    });
    _scrollTo(n);
    if (play) _play();
  }

  void _speakOne(DialogueTurn t) => TtsService.instance.speakAs(_ttsText(t), gender: _gender(t.speaker), rate: _rate * 0.45);

  void _scrollTo(int i) {
    final ctx = _keys[i].currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), curve: Curves.easeOut, alignment: 0.3);
  }

  String _ttsText(DialogueTurn t) {
    return t.tl.replaceAll(RegExp(r'\([^)]*\)'), '').replaceAll(RegExp(r'\{[a-z_]+\}'), '').trim();
  }

  bool _inlineSheet = false;

  /// 낱말을 누르면 글자 풀이 — 넓은 화면은 컷 아래 칸에, 좁은 화면은 아래에서 올라오는 시트로.
  void _openWord(String w) {
    if (!Devanagari.isDevanagari(w)) return;
    if (_inlineSheet) {
      setState(() => _word = _word == w ? null : w);
      return;
    }
    showGlyphSheet(context, w, turn.note);
  }

  String _gender(String sp) => d.voiceGender(sp); // 지금 회화는 화자 성별이 데이터에 정해져 있다(A Minjun 남 · B Priya 여)

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    final script = _Script(
      d: d,
      current: _i,
      keys: _keys,
      showGloss: _showGloss,
      showRd: _showRd,
      showKo: _showKo,
      onTap: (i) => _goto(i, play: true),
      onSpeak: _speakOne,
      onWord: _openWord,
    );
    final controls = _ControlBar(
      playing: _playing,
      index: _i,
      total: d.turns.length,
      rate: _rate,
      showGloss: _showGloss,
      showRd: _showRd,
      showKo: _showKo,
      hasRd: d.turns.any((t) => t.rd.isNotEmpty),
      hasGloss: d.turns.any((t) => t.gloss.isNotEmpty),
      onPlay: _playing ? _pause : _play,
      onSeek: (v) => _goto(v),
      onRate: () => setState(() => _rate = _rate >= 1.25 ? 0.75 : (_rate + 0.25)),
      onGloss: () => setState(() => _showGloss = !_showGloss),
      onRd: () => KoReadingToggleAction.toggle(context),
      onKo: () => setState(() => _showKo = !_showKo),
    );
    return LayoutBuilder(builder: (context, c) {
      // 칸이 넓으면(아이패드 가로·전체 화면 900 이상) 좌 스크립트 · 우 컷, 좁으면(아이패드 세로 오른쪽 칸·폰) 컷 위 · 스크립트 아래
      final sideBySide = wide && c.maxWidth >= 900;
      _inlineSheet = sideBySide;
      final cut = _CutPanel(
          d: d, turn: turn, showGloss: _showGloss, showRd: _showRd, showKo: _showKo, onSpeak: () => _speakOne(turn), onWord: _openWord,
          sheet: sideBySide && _word != null ? GlyphSheet(word: _word!, note: turn.note, onClose: () => setState(() => _word = null)) : null);
      final body = Column(children: [
        Expanded(
          child: sideBySide
              ? Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Expanded(flex: 4, child: script),
                  const VerticalDivider(width: 1, color: AppColors.line),
                  Expanded(flex: 6, child: cut),
                ])
              : Column(children: [
                  SizedBox(height: (c.maxHeight * 0.44).clamp(240, 520), child: cut),
                  const Divider(height: 1, color: AppColors.line),
                  Expanded(child: script),
                ]),
        ),
        controls,
      ]);
      if (!_done) return body;
      return Stack(fit: StackFit.expand, children: [
        body,
        EpisodeDoneOverlay(
          dialogue: d,
          firstTime: _firstDone,
          onCards: () {
            setState(() => _done = false);
            openFull(context, (_) => DialogueCardScreen(dialogue: d));
          },
          onClose: () => setState(() => _done = false),
        ),
      ]);
    });
  }
}

/// 왼쪽 「대화 스크립트」 목록.
class _Script extends StatelessWidget {
  final Dialogue d;
  final int current;
  final List<GlobalKey> keys;
  final bool showGloss, showRd, showKo;
  final void Function(int) onTap;
  final void Function(DialogueTurn) onSpeak;
  final void Function(String) onWord;
  const _Script({required this.d, required this.current, required this.keys, required this.showGloss, required this.showRd, required this.showKo, required this.onTap, required this.onSpeak, required this.onWord});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
        child: Row(children: [
          const Icon(Icons.volume_up_outlined, size: 16, color: AppColors.sumi),
          const SizedBox(width: 6),
          Text(tr('대화 스크립트'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.sumi)),
          const Spacer(),
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.sumi, width: 1.2)),
            child: Text('${d.turns.length}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.sumi)),
          ),
        ]),
      ),
      Expanded(
        child: ListView.builder(
          padding: EdgeInsets.fromLTRB(12, 4, 12, 12 + bottomInset(context)),
          itemCount: d.turns.length,
          itemBuilder: (context, i) {
            final t = d.turns[i];
            final on = i == current;
            final me = t.speaker == 'A';
            return Padding(
              key: keys[i],
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: InkWell(
                onTap: () => onTap(i),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.fromLTRB(10, 9, 8, 9),
                  decoration: BoxDecoration(
                    color: on ? AppColors.beni.withValues(alpha: 0.07) : AppColors.washi,
                    border: Border.all(color: on ? AppColors.beni : AppColors.line, width: on ? 1.6 : 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${t.num}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: on ? AppColors.beni : AppColors.muted, height: 1.5)),
                    const SizedBox(width: 8),
                    _SpeakerDot(name: d.speakerName(t.speaker), me: me, on: on),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        TapWords(text: LearnerPrefs.fill(t.tl), lemmas: t.lemmas, style: TextStyle(fontSize: on ? 16.5 : 15, fontWeight: FontWeight.w800, color: AppColors.sumi, height: 1.5), onWord: onWord),
                        if (showGloss && t.gloss.isNotEmpty && t.gloss != t.tl) Text(t.gloss, style: const TextStyle(fontSize: 11, color: AppColors.ai, fontWeight: FontWeight.w600)),
                        if (showRd && t.rd.isNotEmpty) Text(LearnerPrefs.fill(t.rd, ko: true), style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
                        if (showKo) Text(LearnerPrefs.fill(t.ko, ko: true), style: const TextStyle(fontSize: 12.5, color: AppColors.sumiLight, height: 1.35)),
                        TurnTags(turn: t),
                        if (on && t.note.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text('💡 ${t.note}', style: const TextStyle(fontSize: 11, color: AppColors.beniDeep, height: 1.35))),
                      ]),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => onSpeak(t),
                      icon: Icon(Icons.volume_up_outlined, size: 18, color: on ? AppColors.beni : AppColors.sumi),
                    ),
                  ]),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }
}

class _SpeakerDot extends StatelessWidget {
  final String name;
  final bool me, on;
  const _SpeakerDot({required this.name, required this.me, required this.on});
  @override
  Widget build(BuildContext context) => Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, color: me ? AppColors.beni : AppColors.sumi),
        child: Text(me ? 'A' : (name.isEmpty ? '?' : name.characters.first), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white)),
      );
}

/// 오른쪽(또는 위) 장면 컷 + 캡션.
class _CutPanel extends StatelessWidget {
  final Dialogue d;
  final DialogueTurn turn;
  final bool showGloss, showRd, showKo;
  final VoidCallback onSpeak;
  final void Function(String) onWord;
  final Widget? sheet; // 넓은 화면의 글자 풀이 칸(컷 아래)
  const _CutPanel({required this.d, required this.turn, required this.showGloss, required this.showRd, required this.showKo, required this.onSpeak, required this.onWord, this.sheet});

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(wide ? 16 : 12, 10, wide ? 16 : 12, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (wide)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              const Icon(Icons.image_outlined, size: 16, color: AppColors.sumi),
              const SizedBox(width: 6),
              Text(tr('회화 장면'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.sumi)),
              const Spacer(),
              Text(d.speakerName(turn.speaker), style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w700)),
            ]),
          ),
        Expanded(child: SceneCut(dialogue: d, turn: turn)), // 문장은 아래 _Caption 에(그림을 덮지 않음)
        const SizedBox(height: 10),
        _Caption(d: d, turn: turn, showGloss: showGloss, showRd: showRd, showKo: showKo, onSpeak: onSpeak, onWord: onWord),
        if (sheet != null) ...[const SizedBox(height: 10), sheet!],
      ]),
    );
  }
}

/// 현재 문장 캡션.
class _Caption extends StatelessWidget {
  final Dialogue d;
  final DialogueTurn turn;
  final bool showGloss, showRd, showKo;
  final VoidCallback onSpeak;
  final void Function(String) onWord;
  const _Caption({required this.d, required this.turn, required this.showGloss, required this.showRd, required this.showKo, required this.onSpeak, required this.onWord});

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(turn.num),
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(16, wide ? 12 : 10, 12, wide ? 12 : 10),
        decoration: BoxDecoration(color: AppColors.washi, border: Border.all(color: AppColors.beni, width: 1.3), borderRadius: BorderRadius.circular(14), boxShadow: kCardShadow),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              TapWords(text: LearnerPrefs.fill(turn.tl), lemmas: turn.lemmas, style: TextStyle(fontSize: wide ? 20 : 17, fontWeight: FontWeight.w800, color: AppColors.sumi, height: 1.5), onWord: onWord),
              if (showGloss && turn.gloss.isNotEmpty && turn.gloss != turn.tl) Text(turn.gloss, style: const TextStyle(fontSize: 12, color: AppColors.ai, fontWeight: FontWeight.w600)),
              if (showRd && turn.rd.isNotEmpty) Text(LearnerPrefs.fill(turn.rd, ko: true), style: const TextStyle(fontSize: 12.5, color: AppColors.muted)),
              if (showKo) Padding(padding: const EdgeInsets.only(top: 2), child: Text(LearnerPrefs.fill(turn.ko, ko: true), style: const TextStyle(fontSize: 13.5, color: AppColors.sumiLight, height: 1.35))),
              if (turn.lemmas.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: LemmaChips(turn: turn, compact: !wide)),
            ]),
          ),
          IconButton(onPressed: onSpeak, icon: const Icon(Icons.volume_up, color: AppColors.beni, size: 26)),
        ]),
      ),
    );
  }
}

/// 하단 고정 컨트롤: ▶ 재생 · 진행 슬라이더 · 속도 · 자막 단계.
class _ControlBar extends StatelessWidget {
  final bool playing, showGloss, showRd, showKo, hasRd, hasGloss;
  final int index, total;
  final double rate;
  final VoidCallback onPlay, onRate, onGloss, onRd, onKo;
  final ValueChanged<int> onSeek;
  const _ControlBar({
    required this.playing,
    required this.index,
    required this.total,
    required this.rate,
    required this.showGloss,
    required this.showRd,
    required this.showKo,
    required this.hasRd,
    this.hasGloss = true,
    required this.onPlay,
    required this.onSeek,
    required this.onRate,
    required this.onGloss,
    required this.onRd,
    required this.onKo,
  });

  @override
  Widget build(BuildContext context) {
    final wide = isWide(context);
    Widget chip(String t, bool on, VoidCallback? tap, {bool fixed = false}) => Padding(
          padding: const EdgeInsets.only(left: 6),
          child: InkWell(
            onTap: tap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: fixed ? AppColors.beni : (on ? AppColors.ai.withValues(alpha: 0.10) : Colors.transparent),
                border: Border.all(color: fixed ? AppColors.beni : (on ? AppColors.ai : AppColors.line)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(t, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: fixed ? Colors.white : (on ? AppColors.ai : AppColors.muted))),
            ),
          ),
        );
    final rateLabel = '${rate.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')}x';
    final playBtn = Row(mainAxisSize: MainAxisSize.min, children: [
      InkWell(
        onTap: onPlay,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 46,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(shape: BoxShape.circle, color: playing ? AppColors.beni : AppColors.washi, border: Border.all(color: AppColors.beni, width: 1.6)),
          child: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: playing ? Colors.white : AppColors.beni, size: 28),
        ),
      ),
      const SizedBox(width: 8),
      Text(playing ? tr('일시정지') : tr('재생'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.sumi)),
    ]);
    final slider = SliderTheme(
      data: SliderTheme.of(context).copyWith(trackHeight: 4, thumbColor: AppColors.beni, activeTrackColor: AppColors.beni, inactiveTrackColor: AppColors.line, overlayShape: SliderComponentShape.noOverlay, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7)),
      child: Slider(value: index.toDouble(), min: 0, max: (total - 1).clamp(1, 999).toDouble(), divisions: total > 1 ? total - 1 : 1, onChanged: (v) => onSeek(v.round())),
    );
    final subs = Row(mainAxisSize: MainAxisSize.min, children: [
      Text(tr('자막'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.sumi)),
      const SizedBox(width: 4),
      chip('हिन्दी', true, null, fixed: true),
      if (hasGloss) chip('단어 뜻', showGloss, onGloss),
      if (hasRd) chip('독음', showRd, onRd),
      chip('한국어', showKo, onKo),
    ]);
    final speed = Row(mainAxisSize: MainAxisSize.min, children: [
      Text(tr('속도'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.sumi)),
      chip(rateLabel, true, onRate),
    ]);
    return LayoutBuilder(builder: (context, c) => Container(
      padding: EdgeInsets.fromLTRB(16, 8, 12, 8 + bottomInset(context)),
      decoration: const BoxDecoration(color: AppColors.washi, border: Border(top: BorderSide(color: AppColors.line))),
      child: wide && c.maxWidth >= 900
          ? Row(children: [
              playBtn,
              const SizedBox(width: 10),
              Expanded(child: slider),
              Text('${index + 1}/$total', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              const SizedBox(width: 12),
              speed,
              const SizedBox(width: 10),
              subs,
            ])
          : Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [playBtn, const SizedBox(width: 6), Expanded(child: slider), Text('${index + 1}/$total', style: const TextStyle(fontSize: 11, color: AppColors.muted))]),
              SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [speed, const SizedBox(width: 8), subs])),
            ]),
    ));
  }
}

/// 장면 컷: 장면 그림 → 단어 그림 → 장면 카드. 둥근 틀, 컷 전환 400ms 페이드, 말풍선(현재 대사) 오버레이.
class SceneCut extends StatelessWidget {
  final Dialogue dialogue;
  final DialogueTurn turn;
  final bool bubble;
  const SceneCut({super.key, required this.dialogue, required this.turn, this.bubble = false});

  Future<_ArtPick?> _pick() async {
    // 1) 장면 컷(uk /art/hi/scene, A·B 한 쌍당 1장) → 2) 턴 art → 3) 단어 그림 → 4) 장면 카드
    final scene = await ArtService.instance.sceneCut(dialogue.id, turn.num, large: true);
    if (scene != null) return _ArtPick(scene, null);
    if (turn.art != null) return _ArtPick(turn.art!, null);
    for (final w in turn.pictureWords) {
      final u = await ArtService.instance.urlFor(w);
      if (u != null) return _ArtPick(u, w);
    }
    final inText = await ArtService.instance.urlInText(turn.tl);
    if (inText != null) return _ArtPick(inText.value, inText.key);
    if (dialogue.art != null) return _ArtPick(dialogue.art!, null);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final me = turn.speaker == 'A';
    return FutureBuilder<_ArtPick?>(
      key: ValueKey('${dialogue.id}:${turn.num}'),
      future: _pick(),
      builder: (context, snap) {
        final p = snap.data;
        final pic = Stack(fit: StackFit.expand, children: [
          if (p == null)
            _SceneCard(dialogue: dialogue, turn: turn)
          else
            Image(image: artProvider(p.url), fit: p.word == null ? BoxFit.cover : BoxFit.contain, errorBuilder: (_, _, _) => _SceneCard(dialogue: dialogue, turn: turn)),
          if (p?.word != null)
            Positioned(
              left: 10,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.washi.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
                child: Text(p!.word!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.sumi)),
              ),
            ),
        ]);
        return LayoutBuilder(builder: (context, c) => AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Container(
            key: ValueKey('${turn.num}:${p?.url}'),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: AppColors.washiDeep, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(18), boxShadow: kCardShadow),
            child: bubble
                ? Column(children: [
                    Expanded(child: pic),
                    _LineStrip(speaker: dialogue.speakerName(turn.speaker), me: me, text: LearnerPrefs.fill(turn.tl), small: c.maxHeight < 220),
                  ])
                : pic,
          ),
        ));
      },
    );
  }
}

/// 그림 아래 대사 띠 — 화자 이름(학습자 = 포인트색) + 한 줄. 그림을 덮지 않는다(일본어앱 2026-11-04, 오버레이 말풍선 금지).
class _LineStrip extends StatelessWidget {
  final String speaker;
  final bool me;
  final String text;
  final bool small;
  const _LineStrip({required this.speaker, required this.me, required this.text, this.small = false});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(12, small ? 6 : 8, 12, small ? 6 : 8),
        decoration: const BoxDecoration(color: AppColors.washi, border: Border(top: BorderSide(color: AppColors.line))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            margin: const EdgeInsets.only(top: 3, right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(color: me ? AppColors.beni : AppColors.ai, borderRadius: BorderRadius.circular(8)),
            child: Text(speaker, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
          ),
          Expanded(child: Text(text, maxLines: small ? 2 : 3, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: small ? 12.5 : 15, fontWeight: FontWeight.w800, color: AppColors.sumi, height: 1.35))),
        ]),
      );
}

class _ArtPick {
  final String url;
  final String? word;
  const _ArtPick(this.url, this.word);
}

/// 그림이 없을 때의 장면 카드(이모지 + 장면 한 줄 + 화자).
class _SceneCard extends StatelessWidget {
  final Dialogue dialogue;
  final DialogueTurn turn;
  const _SceneCard({required this.dialogue, required this.turn});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final small = c.maxHeight < 220; // 홈 「오늘의 컷」 같은 작은 틀
      return Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFFFF7F0), Color(0xFFF3F0FF)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        padding: EdgeInsets.fromLTRB(14, small ? 44 : 18, 14, 10),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(dialogue.emoji, style: TextStyle(fontSize: small ? 34 : 56)),
          SizedBox(height: small ? 4 : 10),
          Flexible(child: Text(dialogue.scene, textAlign: TextAlign.center, maxLines: small ? 2 : 3, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: small ? 11 : 13, color: AppColors.sumiLight, height: 1.4))),
          if (!small) ...[
            const SizedBox(height: 6),
            Text(dialogue.speakerName(turn.speaker), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.beni)),
          ],
        ]),
      );
    });
  }
}


/// 글자 풀이 — 아래에서 올라오는 시트.
Future<void> showGlyphSheet(BuildContext context, String word, String note) => showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.washi,
      builder: (c) => SafeArea(top: false, child: GlyphSheet(word: word, note: note, onClose: () => Navigator.pop(c))),
    );

/// 문장을 낱말 단위로 누를 수 있게(2026-11-07) — **탭하면 단어창**(단어장에 있는 말), 단어장에 없으면 글자 풀이. **길게 누르면 글자 풀이**.
/// 레마(내용어)는 표면형 → 기본형으로 찾고, 그 밖의 낱말은 표면형 그대로 찾는다. 단어장에 있는 레마는 밑줄. 띄어쓰기·문장 부호는 그대로 둔다.
class TapWords extends StatefulWidget {
  final String text;
  final TextStyle style;
  final void Function(String) onWord;
  final List<Lemma> lemmas;
  const TapWords({super.key, required this.text, required this.style, required this.onWord, this.lemmas = const []});

  @override
  State<TapWords> createState() => _TapWordsState();
}

class _TapWordsState extends State<TapWords> {
  late List<String> _parts;
  late Map<String, String> _base; // 표면형 → 기본형(레마)
  Map<String, WordRow> _found = const {};

  static final _word = RegExp(r'^[\p{L}\p{M}\p{N}]+$', unicode: true);
  bool _tappable(String p) => _word.hasMatch(p) && Devanagari.isDevanagari(p);
  String _key(String p) => _base[p] ?? Devanagari.normalize(p);

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  @override
  void didUpdateWidget(TapWords old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text || old.lemmas != widget.lemmas) _prepare();
  }

  void _prepare() {
    _parts = RegExp(r'[\p{L}\p{M}\p{N}]+|[^\p{L}\p{M}\p{N}]+', unicode: true).allMatches(widget.text).map((m) => m[0]!).toList();
    _base = {for (final l in widget.lemmas) l.surface: l.base};
    final text = widget.text;
    wordsByLemmas(_parts.where(_tappable).map(_key)).then((f) {
      if (mounted && text == widget.text) setState(() => _found = f);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lemmaStyle = widget.style.copyWith(decoration: TextDecoration.underline, decorationColor: AppColors.ai.withValues(alpha: 0.5));
    return Wrap(children: [
      for (final p in _parts)
        if (_tappable(p))
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              final w = _found[_key(p)];
              w != null ? showWordSheet(context, w) : widget.onWord(p);
            },
            onLongPress: () => widget.onWord(p),
            child: Text(p, style: _base.containsKey(p) && _found.containsKey(_key(p)) ? lemmaStyle : widget.style),
          )
        else
          Text(p, style: widget.style),
    ]);
  }
}

/// 말투 꼬리표 — 존대(आप/तुम/तू)·성별형(note 의 (남성)/(여성)). 누르면 한 줄 설명.
class TurnTags extends StatelessWidget {
  final DialogueTurn turn;
  const TurnTags({super.key, required this.turn});

  @override
  Widget build(BuildContext context) {
    final tags = [Devanagari.register(turn.tl), Devanagari.gender(turn.note)].whereType<({String label, String tip})>().toList();
    if (tags.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(spacing: 6, runSpacing: 4, children: [
        for (final t in tags)
          Tooltip(
            message: tr(t.tip),
            triggerMode: TooltipTriggerMode.tap,
            showDuration: const Duration(seconds: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: AppColors.beni.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(tr(t.label), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.beni)),
            ),
          ),
      ]),
    );
  }
}

/// 글자 풀이 — 낱말을 자음·모음 부호·비음 칸으로(UX 시안 01). 자음 = 남색, 모음 부호 = 자홍, 비음·결합 = 인디고 테두리.
class GlyphSheet extends StatelessWidget {
  final String word;
  final String note;
  final VoidCallback onClose;
  const GlyphSheet({super.key, required this.word, required this.note, required this.onClose});

  Color _edge(GlyphKind k) => switch (k) {
        GlyphKind.consonant => AppColors.sumi,
        GlyphKind.sign || GlyphKind.vowel => AppColors.beni,
        _ => AppColors.ai,
      };

  @override
  Widget build(BuildContext context) {
    final gs = Devanagari.split(word);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 12),
      decoration: BoxDecoration(color: AppColors.washi, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(14), boxShadow: kCardShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Text(tr('글자 풀이'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.sumi)),
          const SizedBox(width: 10),
          Text(word, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.beni)),
          const Spacer(),
          IconButton(visualDensity: VisualDensity.compact, onPressed: onClose, icon: const Icon(Icons.close, size: 18, color: AppColors.muted)),
        ]),
        const SizedBox(height: 6),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final g in gs)
            Container(
              constraints: const BoxConstraints(minWidth: 72),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _edge(g.kind), width: 1.4), borderRadius: BorderRadius.circular(10)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(g.text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.sumi, height: 1.4)),
                Text('${tr(g.role)} ${g.sound}', style: const TextStyle(fontSize: 11, color: AppColors.sumiLight)),
              ]),
            ),
        ]),
        if (note.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(note, style: const TextStyle(fontSize: 13, color: AppColors.sumi, height: 1.4)),
        ],
      ]),
    );
  }
}
