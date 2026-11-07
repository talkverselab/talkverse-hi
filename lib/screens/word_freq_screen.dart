import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../data/db/app_database.dart';
import '../main.dart';
import '../services/ko_reading.dart';
import '../services/tts_service.dart';
import '../widgets/word_art_thumb.dart';

/// 절벽 단어 — 회화 빈도 1~2,000위를 절벽구간(R1~R5)별 **20어 단원**으로, 단어는 **네모 타일**로 보여 준다(사용자 지시 2026-11-07, 일본어앱과 같은 구조).
/// 위 버튼 「절벽구간 단어만 / 회화 단어 포함」 — 포함이면 회화에 나오지만 2,000위 밖인 단어(DB rank 3001~, 빈도표에 없는 회화 레마)가 「회화」 구간으로 뒤에 붙는다.
class WordFreqScreen extends StatefulWidget {
  const WordFreqScreen({super.key});

  @override
  State<WordFreqScreen> createState() => _WordFreqScreenState();
}

/// 절벽 v2 절대 기준(누적 55/60/70/80%) — 끝 순위. 앱 소개 표도 이 값을 쓴다. R5 는 2,000위에서 끊음(사용자 지시 2026-11-07).
const List<int> kWordCliffs = [28, 39, 84, 226];
const int kWordCap = 2000;
const int kUnit = 20;

class _WordFreqScreenState extends State<WordFreqScreen> {
  List<WordRow> _words = const [];
  List<WordRow> _conv = const [];
  bool _loading = true;
  bool _withConv = false;
  String _filter = 'ALL';

  static Map<String, _Region> get _regions => {
        'ALL': _Region(tr('전체'), AppColors.sumi),
        'R1': _Region('R1 · 1-${kWordCliffs[0]}', AppColors.beni),
        'R2': _Region('R2 · ${kWordCliffs[0] + 1}-${kWordCliffs[1]}', AppColors.beniLight),
        'R3': _Region('R3 · ${kWordCliffs[1] + 1}-${kWordCliffs[2]}', AppColors.kinDeep),
        'R4': _Region('R4 · ${kWordCliffs[2] + 1}-${kWordCliffs[3]}', AppColors.matcha),
        'R5': _Region('R5 · ${kWordCliffs[3] + 1}-$kWordCap', AppColors.muted),
        'C': _Region(tr('회화'), AppColors.ai),
      };

  static String _regionOf(WordRow w) => w.rank > kWordCap ? 'C' : (w.region ?? 'R5');

  @override
  void initState() {
    super.initState();
    KoReadingPrefs.show.addListener(_onRd);
    _load();
  }

  void _onRd() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    KoReadingPrefs.show.removeListener(_onRd);
    super.dispose();
  }

  Future<void> _load() async {
    final rows = await (appDb.select(appDb.words)..orderBy([(w) => OrderingTerm.asc(w.rank)])).get();
    if (!mounted) return;
    setState(() {
      _words = rows.where((w) => w.rank <= kWordCap).toList();
      _conv = rows.where((w) => w.rank > kWordCap).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pool = _withConv ? [..._words, ..._conv] : _words;
    final filtered = _filter == 'ALL' ? pool : pool.where((w) => _regionOf(w) == _filter).toList();
    final units = <List<WordRow>>[
      for (var i = 0; i < filtered.length; i += kUnit) filtered.sublist(i, (i + kUnit).clamp(0, filtered.length)),
    ];
    final regions = _regions;
    final chips = regions.entries.where((e) => e.key != 'C' || _withConv).toList();

    return Scaffold(
      backgroundColor: AppColors.washi,
      appBar: AppBar(
        title: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(tr('절벽 단어'), style: const TextStyle(color: AppColors.sumi, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(trf('회화 빈도 {0}위 · {1}어 단원 · 탭하면 발음', ['2,000', kUnit]), style: const TextStyle(color: AppColors.sumiLight, fontSize: 10, letterSpacing: 1)),
        ]),
        actions: const [KoReadingToggleAction()],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.beni))
          : Column(children: [
              Container(
                color: AppColors.washiDeep,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Column(children: [
                  Row(children: [
                    _ModeButton(
                        label: tr('절벽구간 단어만'),
                        selected: !_withConv,
                        onTap: () => setState(() {
                              _withConv = false;
                              if (_filter == 'C') _filter = 'ALL';
                            })),
                    const SizedBox(width: 8),
                    _ModeButton(label: trf('회화 단어 포함 (+{0})', [_conv.length]), selected: _withConv, onTap: () => setState(() => _withConv = true)),
                  ]),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 32,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final e in chips)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _filter = e.key),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _filter == e.key ? e.value.color : AppColors.washi,
                                  border: Border.all(color: e.value.color, width: _filter == e.key ? 1.5 : 0.8),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(e.value.label, style: TextStyle(color: _filter == e.key ? AppColors.washi : e.value.color, fontWeight: FontWeight.w700, fontSize: 12)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ]),
              ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(12, 8, 12, 16 + bottomInset(context)),
                  itemCount: units.length,
                  itemBuilder: (context, i) => _UnitBlock(index: i + 1, words: units[i], regions: regions),
                ),
              ),
            ]),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.sumi : AppColors.washi,
              border: Border.all(color: selected ? AppColors.sumi : AppColors.line),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(label, style: TextStyle(color: selected ? AppColors.washi : AppColors.sumi, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ),
      );
}

/// 한 단원 = 20어. 머리줄(단원 번호·순위 범위·구간) + 네모 타일 격자.
class _UnitBlock extends StatelessWidget {
  final int index;
  final List<WordRow> words;
  final Map<String, _Region> regions;
  const _UnitBlock({required this.index, required this.words, required this.regions});

  @override
  Widget build(BuildContext context) {
    final first = words.first;
    final key = _WordFreqScreenState._regionOf(first);
    final region = regions[key];
    final conv = key == 'C';
    final cols = (MediaQuery.sizeOf(context).width / 112).floor().clamp(3, 8);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 6, 2, 6),
          child: Row(children: [
            Text(trf('{0}단원', [index]), style: const TextStyle(color: AppColors.sumi, fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            if (!conv) Text('#${first.rank}-${words.last.rank}', style: const TextStyle(color: AppColors.sumiLight, fontSize: 11)),
            const Spacer(),
            if (region != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: region.color, borderRadius: BorderRadius.circular(4)),
                child: Text(conv ? tr('회화') : key, style: const TextStyle(color: AppColors.washi, fontSize: 10, fontWeight: FontWeight.w800)),
              ),
          ]),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, mainAxisSpacing: 6, crossAxisSpacing: 6),
          itemCount: words.length,
          itemBuilder: (context, i) => _WordTile(w: words[i], color: region?.color ?? AppColors.sumi, conv: conv),
        ),
      ]),
    );
  }
}

/// 네모 타일 — 순위·독음 · 그림(있으면) · 단어 · 뜻 한 줄. 탭하면 발음.
class _WordTile extends StatelessWidget {
  final WordRow w;
  final Color color;
  final bool conv;
  const _WordTile({required this.w, required this.color, required this.conv});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => TtsService.instance.speak(w.word),
      child: Container(
        decoration: BoxDecoration(color: AppColors.washi, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(8), boxShadow: kCardShadow),
        padding: const EdgeInsets.all(6),
        child: LayoutBuilder(builder: (context, c) {
          final art = (c.maxHeight * 0.36).clamp(24.0, 72.0);
          return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Row(children: [
              Text(conv ? tr('회화') : '#${w.rank}', style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w800)),
              const Spacer(),
              if (w.cefr != null && KoReadingPrefs.show.value)
                Flexible(child: Text(w.cefr!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, color: AppColors.sumiLight))),
            ]),
            const SizedBox(height: 2),
            WordArtThumb(word: w.word, rank: conv ? null : w.rank, size: art),
            const SizedBox(height: 2),
            FittedBox(fit: BoxFit.scaleDown, child: Text(w.word, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.sumi))),
            if ((w.meaningKo ?? '').isNotEmpty)
              Text(w.meaningKo!, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: AppColors.sumiLight)),
          ]);
        }),
      ),
    );
  }
}

class _Region {
  final String label;
  final Color color;
  const _Region(this.label, this.color);
}
