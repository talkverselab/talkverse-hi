import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';

import 'content_sync.dart';
import 'learner_prefs.dart';

/// 단어 그림(talkverse.uk 공용 그림 저장소) — 2026-11-03.
///
/// talkverse.uk 세션이 Cloudflare 에 올린 공개 API(인증 없음) — 일본어앱에서 옮김(2026-11-02). 힌디어 세트는 아직 0장:
/// - 목록 `GET https://auth.talkverse.uk/art/hi/manifest?level=R1` (level 생략 = 전체)
///   → `{lang, level, count, base, items:[{id, rank, level, word, reading, ko, en, pos, key_1024, key_512}]}`
/// - 그림 = `base + key` (512·1024 webp, 1년 캐시). 
/// 매니페스트는 SharedPreferences 에 하루 캐시하고, 없으면 그림 없이 카드가 그대로 나온다(실패해도 화면은 멀쩡해야 한다).
class ArtService {
  ArtService._();
  static final ArtService instance = ArtService._();

  static const manifestUrl = 'https://auth.talkverse.uk/art/hi/manifest';
  static const sceneManifestUrl = 'https://auth.talkverse.uk/art/hi/scene/manifest';
  final Map<String, Map<int, String>> _scene = {}; // 편id → {컷번호 → URL}
  final Map<String, Future<void>> _sceneLoading = {};

  /// 장면 컷(A·B 한 쌍당 1장, 턴 → 컷 (num+1)÷2). 학습자가 여자면 `<편id>_f` 컷을 먼저(일본어앱 2026-11-04).
  Future<String?> sceneCut(String episodeId, int turnNum, {bool large = false}) async {
    final n = (turnNum + 1) ~/ 2;
    if (LearnerPrefs.gender.value == 'female') {
      final f = await _sceneCuts('${episodeId}_f', large: large);
      if (f[n] != null) return f[n];
    }
    final cuts = await _sceneCuts(episodeId, large: large);
    if (cuts.isEmpty) return null;
    return cuts[n] ?? cuts[cuts.keys.reduce((a, b) => (a - n).abs() <= (b - n).abs() ? a : b)];
  }

  Future<Map<int, String>> _sceneCuts(String episodeId, {bool large = false}) async {
    final key = '$episodeId${large ? ':L' : ''}';
    if (_scene.containsKey(key)) return _scene[key]!;
    // 시작 때 받아 둔 전체 장면 매니페스트(ContentSync) — 편마다 네트워크를 타지 않는다
    final idx = ContentSync.instance.sceneIndex[episodeId];
    if (idx != null && idx.isNotEmpty) {
      final b = ContentSync.instance.base;
      return _scene[key] = {for (final e in idx.entries) e.key: '$b/${e.value}'};
    }
    await (_sceneLoading[key] ??= () async {
      final out = <int, String>{};
      try {
        final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
        final req = await client.getUrl(Uri.parse('$sceneManifestUrl?episode=${Uri.encodeQueryComponent(episodeId)}'));
        req.headers.set(HttpHeaders.userAgentHeader, 'talkverse-hi/0.1');
        final res = await req.close().timeout(const Duration(seconds: 12));
        if (res.statusCode == 200) {
          final j = json.decode(await res.transform(utf8.decoder).join()) as Map<String, dynamic>;
          final base = (j['base'] as String? ?? '').replaceAll(RegExp(r'/$'), '');
          for (final it in (j['items'] as List? ?? const [])) {
            final m = it as Map<String, dynamic>;
            final k = (large ? m['key_1168'] : m['key_584']) as String? ?? m['key_1168'] as String?;
            final cut = m['cut'];
            if (k != null && cut is int && base.isNotEmpty) out[cut] = '$base/$k';
          }
        }
        client.close();
      } catch (e) {
        debugPrint('ArtService: scene manifest 실패 $episodeId $e');
      }
      _scene[key] = out;
    }());
    return _scene[key] ?? const {};
  }
  static const _prefKey = 'art_manifest_fr_v1';
  static const _prefAt = 'art_manifest_fr_at';
  static const _ttl = Duration(hours: 24);

  String _base = '';
  final Map<String, String> _byWord = {}; // word → key_512
  final Map<int, String> _byRank = {}; // rank → key_512
  final Map<String, int> _rankByWord = {}; // word → rank
  Future<void>? _loading;
  bool get isLoaded => _byWord.isNotEmpty;

  /// 단어(표제어) 또는 빈도 순위로 512px 그림 주소. 없으면 null.
  Future<String?> urlFor(String word, {int? rank}) async {
    await _ensure();
    final key = _byWord[word] ?? (rank != null ? _byRank[rank] : null);
    if (key == null || _base.isEmpty) return null;
    return _base.endsWith('/') ? '$_base$key' : '$_base/$key';
  }

  /// 문장 안에 들어 있는 그림 단어 중 가장 긴 것의 그림. 핵심 단어에 그림이 없을 때의 보조.
  Future<MapEntry<String, String>?> urlInText(String text) async {
    await _ensure();
    if (_base.isEmpty || text.isEmpty) return null;
    String? best;
    // 낱말 단위로(부분 문자열로 찾으면 짧은 낱말이 긴 낱말에 걸린다). 데바나가리 모음 부호·비음 점은 결합 문자(\p{M})라 함께 둔다.
    final words = text.split(RegExp(r"[^\p{L}\p{M}\p{N}-]+", unicode: true)).toSet();
    for (final w in _byWord.keys) {
      if (w.length < 2 || !words.contains(w.toLowerCase())) continue;
      if (best == null || w.length > best.length) best = w;
    }
    if (best == null) return null;
    final key = _byWord[best]!;
    return MapEntry(best, _base.endsWith('/') ? '$_base$key' : '$_base/$key');
  }

  /// 로드 없이 즉시 조회(이미 받아 둔 경우만).
  String? urlForSync(String word, {int? rank}) {
    final key = _byWord[word] ?? (rank != null ? _byRank[rank] : null);
    if (key == null || _base.isEmpty) return null;
    return _base.endsWith('/') ? '$_base$key' : '$_base/$key';
  }

  Future<void> _ensure() => _loading ??= _load();

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final at = prefs.getInt(_prefAt) ?? 0;
    final cached = prefs.getString(_prefKey);
    final fresh = DateTime.now().millisecondsSinceEpoch - at < _ttl.inMilliseconds;
    if (cached != null && fresh && _apply(cached)) return;
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
      final req = await client.getUrl(Uri.parse(manifestUrl));
      final res = await req.close().timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        if (_apply(body)) {
          await prefs.setString(_prefKey, body);
          await prefs.setInt(_prefAt, DateTime.now().millisecondsSinceEpoch);
          client.close();
          return;
        }
      }
      client.close();
    } catch (e) {
      debugPrint('ArtService: manifest 실패 $e');
    }
    if (cached != null) _apply(cached); // 오래된 캐시라도 쓴다
  }

  bool _apply(String body) {
    try {
      final j = json.decode(body) as Map<String, dynamic>;
      final base = j['base'] as String? ?? '';
      final items = j['items'] as List<dynamic>? ?? const [];
      if (base.isEmpty || items.isEmpty) return false;
      _base = base;
      _byWord.clear();
      _byRank.clear();
      _rankByWord.clear();
      for (final it in items) {
        final m = it as Map<String, dynamic>;
        final key = m['key_512'] as String? ?? m['key_1024'] as String?;
        if (key == null) continue;
        final w = m['word'] as String?;
        if (w != null && w.isNotEmpty) _byWord[w] = key;
        final r = m['rank'];
        final rank = r is int ? r : (r is String ? int.tryParse(r) : null);
        if (rank != null) {
          _byRank[rank] = key;
          if (w != null && w.isNotEmpty) _rankByWord[w] = rank;
        }
      }
      return _byWord.isNotEmpty;
    } catch (e) {
      debugPrint('ArtService: manifest 파싱 실패 $e');
      return false;
    }
  }
}
