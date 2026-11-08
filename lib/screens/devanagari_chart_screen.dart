import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../services/devanagari_phonetics.dart';
import '../widgets/devanagari_sound_sheet.dart';

/// 데바나가리와 발음 — 일본어앱 「50음도와 발음」의 힌디어판(사용자 지시 2026-11-08, 공통 프롬프터 §5-3).
/// 묶음 칩(모음·모음 부호·자음 다섯 줄·반모음·누크타) + 격자 + 로마자 토글. 글자를 누르면 발음 시트(1초 뒤 자동 재생).
/// 자음 다섯 줄은 같은 칸 배열(무기 무성 · 유기 무성 · 유성 · 유성 유기 · 비음)이라 줄을 바꿔 봐도 칸의 뜻이 같다.
class DevanagariChartScreen extends StatefulWidget {
  const DevanagariChartScreen({super.key});

  @override
  State<DevanagariChartScreen> createState() => _DevanagariChartScreenState();
}

class _Group {
  final String key;
  final String label;
  final Color color;
  const _Group(this.key, this.label, this.color);
}

class _DevanagariChartScreenState extends State<DevanagariChartScreen> {
  String _group = 'vowel';
  bool _roman = true;

  static List<_Group> get _groups => [
        _Group('vowel', tr('모음'), AppColors.beni),
        _Group('matra', tr('모음 부호'), AppColors.beniLight),
        _Group('velar', tr('क 줄 · 목'), AppColors.ai),
        _Group('palatal', tr('च 줄 · 입천장'), AppColors.oliva),
        _Group('retroflex', tr('ट 줄 · 혀 말아'), AppColors.lusa),
        _Group('dental', tr('त 줄 · 이'), AppColors.mar),
        _Group('labial', tr('प 줄 · 입술'), AppColors.matcha),
        _Group('other', tr('य र ल व · श स ह'), AppColors.irregular),
        _Group('nukta', tr('누크타(점)'), AppColors.sumiLight),
      ];

  static List<String> get _stopCols => [tr('무기'), tr('유기'), tr('유성'), tr('유성 유기'), tr('비음')];

  @override
  Widget build(BuildContext context) {
    final groups = _groups;
    final g = groups.firstWhere((x) => x.key == _group);
    final letters = lettersOf(_group);
    final stops = const {'velar', 'palatal', 'retroflex', 'dental', 'labial'}.contains(_group);
    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(
        title: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(tr('데바나가리와 발음'), style: const TextStyle(color: AppColors.sumi, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(tr('글자를 누르면 소리·입 모양·한국어 비교'), style: const TextStyle(color: AppColors.sumiLight, fontSize: 10, letterSpacing: 1)),
        ]),
        actions: [
          TextButton(
            onPressed: () => setState(() => _roman = !_roman),
            child: Text(_roman ? tr('로마자 숨기기') : tr('로마자 보기'), style: const TextStyle(fontSize: 12, color: AppColors.ai, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Column(children: [
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            children: [
              for (final x in groups)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _group = x.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _group == x.key ? x.color : AppColors.washi,
                        border: Border.all(color: x.color, width: _group == x.key ? 1.5 : 0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(x.label, style: TextStyle(color: _group == x.key ? AppColors.washi : x.color, fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(builder: (context, c) {
            final cols = stops ? 5 : (c.maxWidth / 96).floor().clamp(3, 6);
            return ListView(
              padding: EdgeInsets.fromLTRB(12, 4, 12, 24 + bottomInset(context)),
              children: [
                if (stops)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      for (final h in _stopCols)
                        Expanded(child: Text(h, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: AppColors.sumiLight, fontWeight: FontWeight.w700))),
                    ]),
                  ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, mainAxisSpacing: 8, crossAxisSpacing: 8, mainAxisExtent: 104),
                  itemCount: letters.length,
                  itemBuilder: (context, i) => _Cell(l: letters[i], color: g.color, roman: _roman),
                ),
                const SizedBox(height: 14),
                Text(_note(_group), style: const TextStyle(fontSize: 12.5, height: 1.55, color: AppColors.sumiLight)),
              ],
            );
          }),
        ),
      ]),
    );
  }

  static String _note(String g) => switch (g) {
        'vowel' => tr('짧은·긴 모음이 짝을 이룬다(इ/ई, उ/ऊ). 자음 뒤에서는 모음 글자 대신 「모음 부호」를 붙인다.'),
        'matra' => tr('자음 क 에 모음 부호를 붙인 모양. 부호는 위·아래·왼쪽·오른쪽에 붙지만 소리는 언제나 자음 다음이다.'),
        'nukta' => tr('글자 아래 점(누크타)은 페르시아·아랍·영어에서 온 소리. 구어에서는 점을 빼고 읽는 사람도 많다.'),
        'other' => tr('र 는 혀로 한 번 톡, ल 은 혀를 붙인 채 — 한국어 ㄹ 하나로 두 소리를 구별해야 한다.'),
        _ => tr('네 칸의 파열음이 한국어 화자에게 가장 어렵다: 무기(된소리처럼) · 유기(거센소리) · 유성(목을 울림) · 유성 유기(울림+숨).'),
      };
}

class _Cell extends StatelessWidget {
  final LetterInfo l;
  final Color color;
  final bool roman;
  const _Cell({required this.l, required this.color, required this.roman});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showDevanagariSoundSheet(context, info: l, color: color),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.washi,
          border: Border.all(color: color.withValues(alpha: 0.45)),
          borderRadius: BorderRadius.circular(10),
          boxShadow: kCardShadow,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(l.letter, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: color, height: 1.3)),
              if (roman) Text(l.roman, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.sumiLight)),
            ]),
          ),
        ),
      ),
    );
  }
}
