import 'dart:async';

import 'package:flutter/material.dart';

import '../core/embed_env.dart';
import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/devanagari_phonetics.dart';
import '../services/tts_service.dart';

/// 글자 → 발음 시트: 열리면 1초 뒤 자동 재생 · 다시 듣기 · IPA · 소리나는 곳(그림) · 내는 방식 · 한국어 화자 비교.
/// 조음 위치·모음 그림은 임시(출시 전에 Grok 그림으로 바꾼다 — 사용자 지시 2026-11-08, 출처 표기 없음).
Future<void> showDevanagariSoundSheet(BuildContext context, {required LetterInfo info, required Color color}) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.washi,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _Sheet(info: info, color: color),
    );

class _Sheet extends StatefulWidget {
  final LetterInfo info;
  final Color color;
  const _Sheet({required this.info, required this.color});

  @override
  State<_Sheet> createState() => _SheetState();
}

class _SheetState extends State<_Sheet> {
  Timer? _auto;
  bool _pic = false;

  /// 기기 음성이 글자 하나를 읽게 — 부호(ं ः ्)만 있는 칸은 대표 낱말로.
  String get _say => switch (widget.info.letter) {
        'अं' => 'अंदर',
        'अः' => 'दुःख',
        'क्' => 'क्या',
        'ङ' => 'अंग',
        'ञ' => 'पंजाब',
        _ => widget.info.letter,
      };

  @override
  void initState() {
    super.initState();
    _auto = Timer(const Duration(seconds: 1), () => TtsService.instance.speak(_say));
  }

  @override
  void dispose() {
    _auto?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.info;
    final c = widget.color;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (context, scroll) => SafeArea(
        top: false,
        child: ListView(
          controller: scroll,
          padding: EdgeInsets.fromLTRB(20, 12, 20, 32 + bottomInset(context)),
          children: [
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.sumiLight.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(children: [
              Container(
                width: 84,
                height: 84,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(10)),
                child: FittedBox(child: Padding(padding: const EdgeInsets.all(6), child: Text(l.letter, style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: AppColors.washi, height: 1.3)))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.roman, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c)),
                  const SizedBox(height: 4),
                  Text('IPA [${l.ipa}]', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.sumi)),
                  if (_say != l.letter) Text(trf('예: {0}', [_say]), style: const TextStyle(fontSize: 12, color: AppColors.sumiLight)),
                ]),
              ),
              IconButton(iconSize: 44, color: c, tooltip: tr('다시 듣기'), icon: const Icon(Icons.play_circle_fill), onPressed: () => TtsService.instance.speak(_say)),
            ]),
            const SizedBox(height: 20),
            _box(tr('👄 소리나는 곳'), placeOf(l), c),
            const SizedBox(height: 6),
            InkWell(
              onTap: () => setState(() => _pic = !_pic),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  Icon(_pic ? Icons.expand_less : Icons.expand_more, size: 18, color: c),
                  Text(l.isVowel ? tr('모음 위치 그림 보기') : tr('자음 조음 위치 그림 보기'), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c)),
                ]),
              ),
            ),
            if (_pic) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(8),
                  child: Image.asset(assetPath(l.isVowel ? 'assets/images/ipa/ipa_vowel_chart.png' : 'assets/images/ipa/places_of_articulation.png'), fit: BoxFit.contain),
                ),
              ),
            ],
            const SizedBox(height: 8),
            _box(tr('🗣 내는 방식'), mannerOf(l), c),
            const SizedBox(height: 14),
            _box(tr('🇰🇷 한국어와 비교'), trf('비슷한 소리: {0}\n\n{1}', [l.korSim, l.tip.isEmpty ? _defaultTip(l) : l.tip]), c),
          ],
        ),
      ),
    );
  }

  static String _defaultTip(LetterInfo l) => switch (l.manner) {
        'tenuis' => tr('숨이 새면 옆 칸(유기음)으로 들린다. 된소리처럼 힘을 주되 너무 세게 누르지 않는다.'),
        'aspirate' => tr('숨이 약하면 옆 칸(무기음)과 구별되지 않는다. 뜻이 갈리므로 확실히 내보낸다.'),
        'voiced' => tr('낱말 첫머리에서도 목을 울려야 한다. 울리지 않으면 무기음(된소리 칸)으로 들린다.'),
        'breathy' => tr('울림과 숨을 한 번에. 처음엔 「유성음 + ㅎ」을 빨리 이어 연습하고 점점 하나로 붙인다.'),
        'nasal' => tr('한국어 비음과 거의 같다. 혀 위치만 그 줄(목·입천장·혀 말아·이·입술)에 맞춘다.'),
        _ => '',
      };

  Widget _box(String title, String body, Color c) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.washiDeep, borderRadius: BorderRadius.circular(10), border: Border.all(color: c.withValues(alpha: 0.35))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: c)),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(fontSize: 13.5, height: 1.55, color: AppColors.sumi)),
        ]),
      );
}
