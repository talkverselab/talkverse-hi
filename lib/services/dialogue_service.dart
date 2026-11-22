import 'dart:convert';
import '../core/embed_env.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import '../core/prefs.dart';

import 'learner_prefs.dart';
import 'script_sync.dart';

/// 회화 리더(일본어앱 시안 02 「만화책 읽기형」)용 회화 모델 — 2026-11-02, 일본어앱 `dialogue_service.dart` 를 옮김.
///
/// 지금 데이터는 옛 `assets/data/dialogues/L1.json`(초안 5편 × 8턴) 하나뿐이라 그것을 그대로 읽어 이 모양으로 바꾼다.
/// 회화 콘텐츠는 바꾸지 않는다(사용자 지시 2026-11-02 "회화는 아직 하지마") — 새 구조(R0~R4·주제별 편 파일)는 회화 작성이 풀리면.
/// 칸: tl = 힌디어(옛 파일의 칸 이름은 스페인어 템플릿 그대로 `es`), gloss = 없음, rd = 한글 독음, ko = 한국어, note = 단어 힌트(`x = 뜻`).
/// 문장 내용어 한 개: 표면형(문장 속)·기본형(사전형 레마)·한글 읽기 — 단어장 연결(일본어앱 2026-11-04).
class Lemma {
  final String surface, base, reading;
  const Lemma(this.surface, this.base, this.reading);
}

class DialogueTurn {
  final int num;
  final String speaker; // A·B
  final String tl;
  final String gloss;
  final String rd;
  final String ko;
  final String note;
  final List<String> tags;
  final String? art; // 장면 그림 URL(나중에 채움)
  final List<Lemma> lemmas; // 문장 내용어 — `tools/add_lemmas.py` 가 채운다
  const DialogueTurn({
    required this.num,
    required this.speaker,
    required this.tl,
    required this.gloss,
    required this.rd,
    required this.ko,
    required this.note,
    required this.tags,
    this.art,
    this.lemmas = const [],
  });

  factory DialogueTurn.fromL1(Map<String, dynamic> j) => DialogueTurn(
        num: j['num'] as int? ?? 0,
        speaker: j['speaker'] as String? ?? 'A',
        tl: j['es'] as String? ?? '',
        gloss: j['gloss'] as String? ?? '', // 힌디어 데이터에는 아직 없음
        rd: j['rd'] as String? ?? '',
        ko: j['ko'] as String? ?? '',
        note: j['note'] as String? ?? '',
        tags: (j['tags'] as List?)?.cast<String>() ?? const [],
        art: j['art'] as String?,
        lemmas: [for (final l in (j['lemmas'] as List? ?? const [])) if (l is List && l.length >= 2) Lemma('${l[0]}', '${l[1]}', l.length > 2 ? '${l[2]}' : '')],
      );

  /// 새 회화 파일(R0~R4, `tools/prompts/dialogue_hi.md` 형식). [female] = 학습자 여성판 — `tl_f`·`rd_f`·`ko_f` 가 있으면 그것.
  factory DialogueTurn.fromJson(Map<String, dynamic> j, {bool female = false}) {
    String pick(String k) => (female ? j['${k}_f'] as String? : null) ?? j[k] as String? ?? '';
    return DialogueTurn(
      num: j['num'] as int? ?? 0,
      speaker: j['speaker'] as String? ?? 'A',
      tl: pick('tl'),
      gloss: '',
      rd: pick('rd'),
      ko: pick('ko'),
      note: j['note'] as String? ?? '',
      tags: (j['tags'] as List?)?.cast<String>() ?? const [],
      art: j['art'] as String?,
      lemmas: [for (final l in (j['lemmas'] as List? ?? const [])) if (l is List && l.length >= 2) Lemma('${l[0]}', '${l[1]}', l.length > 2 ? '${l[2]}' : '')],
    );
  }

  /// 그림 조회용 핵심 단어 후보: 단어 힌트(note)의 표제어(`je m'appelle = 내 이름은`의 왼쪽).
  List<String> get pictureWords => [
        for (final part in note.split(RegExp(r'[,;·]')))
          if (part.contains('=')) part.split('=').first.trim().toLowerCase(),
      ].where((w) => w.isNotEmpty).toList();
}

class Dialogue {
  final String id;
  final String region; // 지금은 옛 레벨 이름(L1) 그대로 — R 재태그는 회화 작업 때
  final String island; // 주제
  final String title;
  final String emoji;
  final String scene;
  final Map<String, String> speakers;
  final Map<String, String> genders;
  final List<String> expressions;
  final List<DialogueTurn> turns;
  final String? art;
  const Dialogue({
    required this.id,
    required this.region,
    required this.island,
    required this.title,
    required this.emoji,
    required this.scene,
    required this.speakers,
    required this.genders,
    required this.expressions,
    required this.turns,
    this.art,
  });

  /// 새 회화 파일 한 편. 학습자 여성판이면 `speakers_f`(사랑 편 상대 = 아르준)로 바꾸고 그 화자의 성별도 뒤집는다.
  factory Dialogue.fromJson(Map<String, dynamic> j, {bool female = false}) {
    final sp = ((j['speakers'] as Map?) ?? const {}).map((k, v) => MapEntry('$k', '$v'));
    final g = ((j['genders'] as Map?) ?? const {}).map((k, v) => MapEntry('$k', '$v'.startsWith('m') ? 'male' : 'female'));
    if (female) {
      for (final e in ((j['speakers_f'] as Map?) ?? const {}).entries) {
        sp['${e.key}'] = '${e.value}';
        g['${e.key}'] = g['${e.key}'] == 'male' ? 'female' : 'male';
      }
    }
    return Dialogue(
      id: j['id'] as String,
      region: j['region'] as String? ?? 'R1',
      island: j['island'] as String? ?? '',
      title: j['title'] as String? ?? '',
      emoji: j['emoji'] as String? ?? '💬',
      scene: j['scene'] as String? ?? '',
      speakers: sp,
      genders: g,
      expressions: (j['expressions'] as List?)?.cast<String>() ?? const [],
      turns: ((j['turns'] as List?) ?? const []).map((t) => DialogueTurn.fromJson(t as Map<String, dynamic>, female: female)).toList(),
      art: j['art'] as String?,
    );
  }

  /// 화면에 보일 장면 설명 — 원고의 「A」(학습자)를 이름(없으면 「나」)으로(일본어앱 빌드 111).
  String get sceneShown => scene.replaceAllMapped(RegExp(r'(?<![A-Za-z])A(?![A-Za-z]) ?(?=[가-힣])'), (_) => speakerName('A'));

  /// 편 순서 키: survival → a → b → c, 번호 순.
  String get orderKey {
    final m = RegExp(r'_([abcs])(\d+)$').firstMatch(id);
    if (m == null) return id;
    const o = {'s': 0, 'a': 1, 'b': 2, 'c': 3};
    return '${o[m.group(1)]}${m.group(2)!.padLeft(2, '0')}';
  }

  /// 화자 표시 이름. `{name}` 자리는 학습자 이름(없으면 「나」).
  String speakerName(String sp) {
    final raw = speakers[sp] ?? sp;
    if (raw.contains('{name}')) return LearnerPrefs.name.value.isNotEmpty ? LearnerPrefs.name.value : '나';
    return raw.replaceAll(RegExp(r'[{}]'), '');
  }

  /// 목소리 성별 — 지금 회화는 화자 이름·성별이 정해진 이야기(A Minjun 남 · B Priya 여)라 데이터의 성별을 따른다.
  String voiceGender(String sp) => genders[sp] ?? LearnerPrefs.voiceGender(sp);
}

class DialogueService {
  DialogueService._();
  static final DialogueService instance = DialogueService._();

  static const islands = ['survival', 'friends', 'love', 'life', 'travel', 'culture', 'work', 'study'];
  static const islandKo = {
    'survival': '서바이벌',
    'friends': '친구',
    'love': '사랑',
    'life': '생활',
    'travel': '여행',
    'culture': '문화',
    'work': '일',
    'study': '학업',
  };
  static const islandEmoji = {
    'survival': '🆘',
    'friends': '🤝',
    'love': '💘',
    'life': '🏠',
    'travel': '✈️',
    'culture': '🎬',
    'work': '💼',
    'study': '🎓',
  };
  static const levels = ['R0', 'R1', 'R2', 'R3', 'R4']; // 회화 레벨(커리큘럼 레벨 순서)
  static const levelKo = {'L1': '이야기', 'R0': '왕초보', 'R1': '초보', 'R2': '중급', 'R3': '고급', 'R4': '최상급'};
  static const _prefLast = 'dialogue_last';

  final List<Dialogue> _all = [];
  String? _lastOpened;
  String? get lastOpenedId => _lastOpened;
  Future<void> setLastOpened(String id) async {
    _lastOpened = id;
    (await Prefs.getInstance()).setString(_prefLast, id);
  }

  /// 넓은 화면에서 탭이 동시에 떠 두 번 불려도 한 번만 읽는다(`_loaded` 플래그는 경쟁으로 목록이 두 번 찬다).
  Future<void>? _loading;
  Future<void> ensureLoaded() => _loading ??= _load();

  /// 원고가 서버 판으로 바뀌거나 학습자 성별이 바뀌어 다시 읽힐 때마다 오른다.
  final ValueNotifier<int> revision = ValueNotifier(0);
  bool _female = false;

  /// 새 회화(R0~R4) 파일을 읽는다 — 앱 안 편 + 서버에서 받은 새 편, 덮어쓴 판이 있으면 그것([ScriptSync], 일본어앱 빌드 113·114).
  /// 하나도 없으면 false(옛 L1 로 돈다).
  Future<bool> _readR() async {
    final sync = ScriptSync.instance;
    await sync.init();
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final pat = RegExp(r'^assets/data/dialogues/R[0-4]/[^/]+/[^/]+\.json$');
    // 통합 앱이면 매니페스트 키에 packages/hindi_universe/ 가 붙어 있다 — 접두를 떼고 견준다
    final rels = <String>{
      for (final p in manifest.listAssets().map(stripAssetPrefix).where(pat.hasMatch)) p.substring('assets/data/'.length),
      ...sync.added.where((p) => pat.hasMatch('assets/data/$p')),
    }..removeAll(sync.removed);
    final next = <Dialogue>[];
    for (final rel in rels) {
      try {
        final d = Dialogue.fromJson(json.decode(await sync.load(rel)) as Map<String, dynamic>, female: _female);
        if (d.turns.isNotEmpty) next.add(d);
      } catch (_) {}
    }
    if (next.isEmpty) return false;
    next.sort((a, b) => '${a.region}${a.orderKey}'.compareTo('${b.region}${b.orderKey}'));
    _all
      ..clear()
      ..addAll(next);
    return true;
  }


  Future<void> _load() async {
    _lastOpened = (await Prefs.getInstance()).getString(_prefLast);
    _female = LearnerPrefs.isFemale;
    if (await _readR()) {
      // 서버에 더 새 원고가 있으면 뒤에서 받아 다시 읽는다(없거나 실패하면 그대로)
      ScriptSync.instance.refresh().then((changed) async {
        if (changed && await _readR()) revision.value++;
      });
      // 학습자 성별이 바뀌면 그 판으로 다시 읽는다(तुम थके हो ↔ थकी हो)
      LearnerPrefs.gender.addListener(() async {
        if (_female == LearnerPrefs.isFemale) return;
        _female = LearnerPrefs.isFemale;
        if (await _readR()) revision.value++;
      });
      return;
    }
    try {
      final j = json.decode(await rootBundle.loadString(assetPath('assets/data/dialogues/L1.json'))) as Map<String, dynamic>;
      final chars = (j['characters'] as Map<String, dynamic>? ?? const {});
      final names = chars.map((k, v) => MapEntry(k, ((v as Map)['name'] ?? k).toString()));
      final genders = chars.map((k, v) => MapEntry(k, ((v as Map)['gender'] ?? 'female').toString()));
      final level = j['level'] as String? ?? 'L1';
      for (final e in (j['episodes'] as List? ?? const [])) {
        final m = e as Map<String, dynamic>;
        final turns = ((m['turns'] as List?) ?? const []).map((t) => DialogueTurn.fromL1(t as Map<String, dynamic>)).toList();
        if (turns.isEmpty) continue;
        _all.add(Dialogue(
          id: '${level}_${m['id']}',
          region: level,
          island: 'love', // 옛 L1 = 매칭 앱에서 시작하는 연애 이야기(원칙: 기존 연애 서사는 love 주제)
          title: m['title'] as String? ?? m['id'] as String,
          emoji: m['emoji'] as String? ?? '💬',
          scene: m['scenario'] as String? ?? '',
          speakers: names,
          genders: genders,
          expressions: const [],
          turns: turns,
        ));
      }
    } catch (_) {}
  }

  Dialogue? byId(String id) => _all.where((d) => d.id == id).firstOrNull;
  List<Dialogue> get all => List.unmodifiable(_all);
  List<String> get regions => _all.map((d) => d.region).toSet().toList();

  List<Dialogue> list({String? region, String? island}) =>
      _all.where((d) => (region == null || d.region == region) && (island == null || d.island == island)).toList();

  List<String> islandsOf(String region) {
    final has = _all.where((d) => d.region == region).map((d) => d.island).toSet();
    return islands.where(has.contains).toList();
  }

  int count(String region) => _all.where((d) => d.region == region).length;
}
