/// 데바나가리 글자 풀이·말투 판정 — UX 시안 01(2026-11-03 통과)의 「글자 풀이」·「말투 꼬리표」.
/// 콘텐츠를 새로 만들지 않는다: 유니코드 분해 + `docs/DIALOGUE_NOTES.md` §3 독음 표기표로 계산한다.
library;

enum GlyphKind { consonant, conjunct, vowel, sign, nasal, other }

class Glyph {
  final String text; // 화면에 보일 글자(모음 부호는 ◌ 위에)
  final GlyphKind kind;
  final String role; // 자음 · 결합 자음 · 모음 · 모음 부호 · 비음
  final String sound; // 한글 소리(자모 또는 음절)
  const Glyph(this.text, this.kind, this.role, this.sound);
}

class Devanagari {
  Devanagari._();

  // 자음 → 한글 첫소리(유기음은 구분하지 않는다 — 표기표 §3)
  static const _cons = {
    'क': 'ㅋ', 'ख': 'ㅋ', 'ग': 'ㄱ', 'घ': 'ㄱ', 'ङ': 'ㅇ',
    'च': 'ㅊ', 'छ': 'ㅊ', 'ज': 'ㅈ', 'झ': 'ㅈ', 'ञ': 'ㄴ',
    'ट': 'ㅌ', 'ठ': 'ㅌ', 'ड': 'ㄷ', 'ढ': 'ㄷ', 'ण': 'ㄴ',
    'त': 'ㅌ', 'थ': 'ㅌ', 'द': 'ㄷ', 'ध': 'ㄷ', 'न': 'ㄴ',
    'प': 'ㅍ', 'फ': 'ㅍ', 'ब': 'ㅂ', 'भ': 'ㅂ', 'म': 'ㅁ',
    'य': 'ㅇ(y)', 'र': 'ㄹ', 'ल': 'ㄹ', 'व': 'ㅂ/ㅇ(w)',
    'श': 'ㅅ(sh)', 'ष': 'ㅅ(sh)', 'स': 'ㅅ', 'ह': 'ㅎ',
  };
  // 누크타가 붙은 자음
  static const _nukta = {'क': 'ㅋ', 'ख': 'ㅋ', 'ग': 'ㄱ', 'ज': 'ㅈ(z)', 'ड': 'ㄹ', 'ढ': 'ㄹ', 'फ': 'ㅍ(f)', 'य': 'ㅇ(y)'};
  // 홀로 쓰는 모음
  static const _vowels = {
    'अ': '아', 'आ': '아', 'इ': '이', 'ई': '이', 'उ': '우', 'ऊ': '우', 'ऋ': '리',
    'ए': '에', 'ऐ': '에', 'ओ': '오', 'औ': '아우', 'ऑ': '오', 'ऍ': '에',
  };
  // 모음 부호(마트라)
  static const _signs = {
    'ा': '긴 아', 'ि': '이', 'ी': '긴 이', 'ु': '우', 'ू': '긴 우', 'ृ': '리',
    'े': '에', 'ै': '에', 'ो': '오', 'ौ': '아우', 'ॉ': '오', 'ॅ': '에',
  };
  static const _virama = '्';
  static const _nuktaMark = '़';

  static bool isDevanagari(String s) => RegExp(r'[ऀ-ॿ]').hasMatch(s);

  /// 단어를 글자 칸으로 나눈다. 예: हूँ → [ह 자음 ㅎ][◌ू 긴 우][◌ँ 비음 ㅇ], नमस्ते → [न][म][स्त 결합][◌े].
  static List<Glyph> split(String word) {
    final cps = word.runes.map(String.fromCharCode).toList();
    final out = <Glyph>[];
    var i = 0;
    while (i < cps.length) {
      final c = cps[i];
      if (_cons.containsKey(c)) {
        // 자음(+누크타)(+비라마+자음…) 묶음
        final buf = StringBuffer();
        final jamo = <String>[];
        var j = i;
        while (j < cps.length && _cons.containsKey(cps[j])) {
          var ch = cps[j];
          var snd = _cons[ch]!;
          if (j + 1 < cps.length && cps[j + 1] == _nuktaMark) {
            snd = _nukta[ch] ?? snd;
            ch = '$ch$_nuktaMark';
            j++;
          }
          buf.write(ch);
          jamo.add(snd);
          j++;
          if (j < cps.length && cps[j] == _virama && j + 1 < cps.length && _cons.containsKey(cps[j + 1])) {
            buf.write(_virama);
            j++;
            continue;
          }
          if (j < cps.length && cps[j] == _virama) {
            buf.write(_virama); // 단어 끝 비라마(모음 없음)
            j++;
          }
          break;
        }
        final conj = jamo.length > 1;
        out.add(Glyph(buf.toString(), conj ? GlyphKind.conjunct : GlyphKind.consonant, conj ? '결합 자음' : '자음', jamo.join('+')));
        i = j;
      } else if (_vowels.containsKey(c)) {
        out.add(Glyph(c, GlyphKind.vowel, '모음', _vowels[c]!));
        i++;
      } else if (_signs.containsKey(c)) {
        out.add(Glyph('◌$c', GlyphKind.sign, '모음 부호', _signs[c]!));
        i++;
      } else if (c == 'ँ' || c == 'ं') {
        out.add(Glyph('◌$c', GlyphKind.nasal, '비음', 'ㅇ'));
        i++;
      } else if (c == 'ः') {
        out.add(Glyph('◌$c', GlyphKind.other, '숨', 'ㅎ'));
        i++;
      } else {
        i++; // 문장 부호 등은 건너뛴다
      }
    }
    return out;
  }

  /// 문장을 낱말로(데바나가리 결합 문자 포함). 문장 부호는 뺀다.
  static List<String> words(String text) =>
      text.split(RegExp(r'[^\p{L}\p{M}\p{N}]+', unicode: true)).where((w) => w.isNotEmpty).toList();

  /// 존대 꼬리표 — 대명사·명령형 어미로 판정. 없으면 null.
  static ({String label, String tip})? register(String text) {
    final ws = words(text).toSet();
    bool any(Iterable<String> xs) => xs.any(ws.contains);
    if (any(const ['आप', 'आपका', 'आपकी', 'आपके', 'आपको', 'आपसे']) || ws.any((w) => w.endsWith('िए') || w.endsWith('इए') || w.endsWith('ीजिए'))) {
      return (label: '존댓말 आप', tip: 'आप — 낯선 사람·윗사람에게 쓰는 존댓말. 동사도 -इए/-िए, -ते हैं 꼴로.');
    }
    if (any(const ['तू', 'तेरा', 'तेरी', 'तेरे', 'तुझे', 'तुझसे'])) {
      return (label: '아주 가까움 तू', tip: 'तू — 아주 가까운 사이(또는 낮춤). 친구 사이에도 조심해서 쓴다.');
    }
    if (any(const ['तुम', 'तुम्हारा', 'तुम्हारी', 'तुम्हारे', 'तुम्हें', 'तुमसे', 'तुमको'])) {
      return (label: '반말 तुम', tip: 'तुम — 친구·또래에게 쓰는 반말. 동사는 -ओ, -ते हो 꼴로.');
    }
    return null;
  }

  /// 성별 꼬리표 — 회화 note 의 「(남성)/(여성)」에서. 없으면 null.
  static ({String label, String tip})? gender(String note) {
    if (note.contains('(남성)')) return (label: '남성형', tip: '말하는 사람이 남자일 때의 꼴(예: रहा, करता, -ूँगा). 여자는 रही, करती, -ूँगी.');
    if (note.contains('(여성)')) return (label: '여성형', tip: '말하는 사람이 여자일 때의 꼴(예: रही, करती, -ूँगी). 남자는 रहा, करता, -ूँगा.');
    return null;
  }
}
