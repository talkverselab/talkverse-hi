import 'package:flutter/material.dart';

import '../core/pane.dart';
import '../core/platform.dart';
import '../core/theme.dart';
import '../embed.dart';
import '../widgets/spanish_decor.dart';
import 'about_screen.dart';
import 'chunk_search_screen.dart';
import 'conversation_screen.dart';
import 'devanagari_chart_screen.dart';
import 'dialogue_screen.dart';
import 'episode_screen.dart';
import 'grammar_lesson_screen.dart';
import 'profile_screen.dart';
import 'sentence_flashcard_screen.dart';
import 'speaking_practice_screen.dart';
import 'progress_screen.dart';
import 'topic_vocab_screen.dart';
import 'verb_screen.dart';
import 'word_flashcard_screen.dart';
import 'word_freq_screen.dart';
import '../core/l10n.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  static const List<Widget> _screens = [
    HomeScreen(),
    ConversationScreen(),
    ProgressScreen(),
    ProfileScreen(),
  ];

  static List<NavigationDestination> get _tabs => [
    NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: tr('홈')),
    NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: tr('학습')),
    NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: tr('진행')),
    NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: tr('프로필')),
  ];

  final _pane = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final stack = IndexedStack(index: _index, children: _screens);
    // 폰(한 화면): 하단 탭 + 내용 전체 화면
    if (!isWide(context)) {
      return Scaffold(
        body: stack,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: _tabs,
        ),
      );
    }
    // 넓은 화면(아이패드·태블릿·폴드 펼침): 레일 + 왼쪽 칸(탭 화면) | 오른쪽 칸(연 화면) — 일본어앱 main_screen 과 같은 구조(2026-11-02).
    // 회화 재생·카드 같은 학습은 openFull 로 전체 화면.
    final w = MediaQuery.sizeOf(context).width;
    final left = (w * 0.34).clamp(300.0, 440.0);
    final tabs = _tabs;
    return Pane(
      navKey: _pane,
      child: NavigatorPopHandler(
        onPopWithResult: (_) => _pane.currentState?.maybePop(),
        child: Scaffold(
          body: SafeArea(
            bottom: false,
            child: Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  labelType: w >= 900 ? NavigationRailLabelType.all : NavigationRailLabelType.selected,
                  backgroundColor: AppColors.washiDeep,
                  indicatorColor: AppColors.beni.withValues(alpha: 0.12),
                  selectedIconTheme: const IconThemeData(color: AppColors.beniDeep),
                  unselectedIconTheme: const IconThemeData(color: AppColors.muted),
                  selectedLabelTextStyle: const TextStyle(color: AppColors.beni, fontSize: 11, fontWeight: FontWeight.w600),
                  unselectedLabelTextStyle: const TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w600),
                  destinations: [
                    for (final t in tabs)
                      NavigationRailDestination(icon: t.icon, selectedIcon: t.selectedIcon, label: Text(t.label)),
                  ],
                  // 맨 아래 「앱 소개」 — 절벽구간 설명(사용자 지시 2026-11-07)
                  trailing: Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Builder(builder: (context) => InkWell(  // Pane 아래 context 라야 오른쪽 칸에 열린다
                          onTap: () => openPane(context, (_) => const AboutScreen()),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: Column(mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.info_outline, color: AppColors.muted, size: 22),
                              const SizedBox(height: 4),
                              Text(tr('앱 소개'), style: const TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        )),
                      ),
                    ),
                  ),
                ),
                const VerticalDivider(width: 1, thickness: 1, color: AppColors.line),
                SizedBox(width: left, child: stack),
                const VerticalDivider(width: 1, thickness: 1, color: AppColors.line),
                Expanded(
                  child: ClipRect(
                    child: Navigator(
                      key: _pane,
                      onGenerateInitialRoutes: (_, _) => [MaterialPageRoute(builder: (_) => const _PanePlaceholder())],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 오른쪽 칸이 비어 있을 때.
class _PanePlaceholder extends StatelessWidget {
  const _PanePlaceholder();

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.washi,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TileBadge(text: 'HI', size: 56, color: AppColors.lusa),
              const SizedBox(height: 14),
              Text(
                tr('왼쪽에서 고르면 여기에 열립니다 · 회화 재생·카드는 전체 화면'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cal,
      body: Stack(
        children: [
          const Positioned(top: 0, left: 0, right: 0, height: 260, child: MeshBackdrop()),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Text(
                                'Namaste!',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.tinta,
                                  letterSpacing: -1,
                                ),
                              ),
                              SizedBox(width: 6),
                              Text('👋', style: TextStyle(fontSize: 22)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tr('한국 학습자, 오늘도 시작해요'),
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.tintaLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const StreakChip(days: 1),
                    const SizedBox(width: 8),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.cal,
                        border: Border.all(color: AppColors.gualda),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, color: AppColors.rojo, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  tr('오늘의 학습'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.rojo,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 8),
                const _TodayMission(),
                const SizedBox(height: 22),
                Row(
                  children: [
                    SolMark(size: 22),
                    SizedBox(width: 8),
                    Text(
                      tr('메인 메뉴'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.tinta,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _MenuGrid(),
                const SizedBox(height: 28),
                const BandDivider(),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    tr('힌디어유니버스 · 2026'),
                    style: TextStyle(
                      color: AppColors.tintaLight,
                      fontSize: 11,
                      letterSpacing: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 홈 '오늘의 학습' — 첫 미완료 에피소드와 실제 진행도 연결.
class _TodayMission extends StatefulWidget {
  const _TodayMission();

  @override
  State<_TodayMission> createState() => _TodayMissionState();
}

class _TodayMissionState extends State<_TodayMission> {
  EpisodeMeta? _meta;
  int _learned = 0;
  int _total = 40;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await EpisodeCatalog.instance.ensureLoaded();
    final all = EpisodeCatalog.instance.all;
    if (all.isEmpty) return;
    final turns = await appDb.select(appDb.turns).get();
    final progress = await appDb.select(appDb.userProgress).get();
    final learnedIds = progress.where((p) => p.learned).map((p) => p.turnId).toSet();
    for (final meta in all) {
      final epTurns = turns
          .where((t) => t.level == meta.level && t.episodeId == meta.id)
          .toList();
      final total = epTurns.length;
      final learned = epTurns.where((t) => learnedIds.contains(t.id)).length;
      if (total == 0 || learned < total || meta == all.last) {
        if (mounted) {
          setState(() {
            _meta = meta;
            _learned = learned;
            _total = total == 0 ? 40 : total;
          });
        }
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = _meta;
    if (meta == null) return const SizedBox(height: 120);
    final ratio = _total == 0 ? 0.0 : _learned / _total;
    return InkWell(
      onTap: () async {
        await openPane(context, (_) => EpisodeScreen(meta: meta));
        _load();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.rojoDeep, AppColors.rojo],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Color(0x1A32325D), blurRadius: 5, offset: Offset(0, 2), spreadRadius: -1),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              meta.level == 'L1' ? 'SHURUĀT · 입문' : meta.level,
              style: const TextStyle(
                color: AppColors.gualdaBright,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${meta.level} · ${meta.title}',
              style: const TextStyle(
                color: AppColors.cal,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              trf('스토리 {0}', [meta.emoji]),
              style: TextStyle(color: AppColors.cal.withValues(alpha: 0.85), fontSize: 12),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                backgroundColor: AppColors.rojoDeep,
                color: AppColors.gualdaBright,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$_learned / $_total turn',
              style: const TextStyle(color: AppColors.cal, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuGrid extends StatelessWidget {
  // UX 시안 01(2026-11-03 통과): 메뉴를 묶음 3개로 — 순서 문법 → 회화 → 단어(2026-11-07, 일본어앱과 같은 순서). 준비중(성·수·발음)은 타일 대신 묶음 끝 한 줄,
  // 데이터가 아직 빈 메뉴(동사 활용·표현·빈도 단어)는 타일에 「준비 중」 꼬리표.
  @override
  Widget build(BuildContext context) {
    final talk = <_MenuItem>[
      _MenuItem(label: tr('회화'), sub: 'Bātchīt', badge: 'Ch', color: AppColors.rojo,
        builder: (_) => const DialogueHomeScreen()),
      _MenuItem(label: tr('문장 카드'), sub: 'वाक्य', badge: 'S', color: AppColors.tinta,
        builder: (_) => const SentenceFlashcardScreen()),
      _MenuItem(label: tr('문장 말하기'), sub: tr('한글 보고 힌디어로'), badge: '🎙', color: AppColors.rojo,
        builder: (_) => const SpeakingPracticeScreen()),
    ];
    final basics = <_MenuItem>[
      _MenuItem(label: tr('데바나가리와 발음'), sub: 'अ आ क ख', badge: 'अ', color: AppColors.beni,
        builder: (_) => const DevanagariChartScreen()),
    ];
    final grammar = <_MenuItem>[
      _MenuItem(label: tr('문법'), sub: 'व्याकरण', badge: 'G', color: AppColors.rojoDeep,
        builder: (_) => const GrammarHubScreen()),
      _MenuItem(label: tr('동사 활용'), sub: 'Rūp', badge: 'V', color: AppColors.irregular, soon: true,
        builder: (_) => const VerbScreen()),
      _MenuItem(label: tr('청크 검색'), sub: 'खोज', badge: '🔍', color: AppColors.gualdaDeep,
        builder: (_) => const ChunkSearchScreen()),
    ];
    final words = <_MenuItem>[
      _MenuItem(label: tr('절벽 단어'), sub: 'R1~R5', badge: 'F', color: AppColors.lusa,
        builder: (_) => const WordFreqScreen()),
      _MenuItem(label: tr('단어'), sub: 'Śabd', badge: 'W', color: AppColors.oliva,
        builder: (_) => const TopicVocabScreen()),
      _MenuItem(label: tr('표현'), sub: 'Abhivyakti', badge: 'E', color: AppColors.rojoLight, soon: true,
        builder: (_) => TopicVocabScreen(
            title: tr('주제별 표현'),
            asset: 'assets/data/vocab/travel_expressions.json')),
      _MenuItem(label: tr('단어 카드'), sub: 'कार्ड', badge: 'R', color: AppColors.gualdaDeep,
        builder: (_) => const WordFlashcardScreen()),
    ];

    Widget title(String t) => Padding(
          padding: const EdgeInsets.fromLTRB(2, 12, 2, 8),
          child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gualdaDeep)),
        );
    Widget grid(List<_MenuItem> items) => GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: 150, // 고정 높이 — 아이패드 왼쪽 좁은 칸(300~440)에서 비율로 잡으면 아래가 넘친다
          ),
          itemCount: items.length,
          itemBuilder: (context, i) => _MenuTile(item: items[i]),
        );

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      title(tr('기초')),
      grid(basics),
      title(tr('문법·글자')),
      grid(grammar),
      Padding(
        padding: const EdgeInsets.fromLTRB(2, 10, 2, 0),
        child: Text(tr('곧 열려요 · 성·수'), style: const TextStyle(fontSize: 12, color: AppColors.gualdaDeep)),
      ),
      title(tr('회화')),
      grid(talk),
      title(tr('단어')),
      grid(words),
    ]);
  }
}

class _MenuItem {
  final String label;
  final String sub;
  final String badge;
  final Color color;
  final WidgetBuilder builder;
  final bool soon; // 데이터가 아직 비어 있음 → 「준비 중」 꼬리표
  _MenuItem({
    required this.label,
    required this.sub,
    required this.badge,
    required this.color,
    required this.builder,
    this.soon = false,
  });
}

class _MenuTile extends StatelessWidget {
  final _MenuItem item;
  const _MenuTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => openPane(context, item.builder),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cal,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.gualda),
          boxShadow: const [
            BoxShadow(color: Color(0x1A32325D), blurRadius: 5, offset: Offset(0, 2), spreadRadius: -1),
            BoxShadow(color: Color(0x14000000), blurRadius: 3, offset: Offset(0, 1), spreadRadius: -1),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TileBadge(text: item.badge, size: 44, color: item.color),
              const SizedBox(height: 8),
              Text(
                item.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.tinta,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.sub,
                style: const TextStyle(fontSize: 10, color: AppColors.tintaLight),
                overflow: TextOverflow.ellipsis,
              ),
              if (item.soon)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(tr('준비 중'), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.beni)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

