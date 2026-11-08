import '../core/l10n.dart';

/// 데바나가리 글자별 발음 정보 — IPA · 소리나는 곳 · 한국어 화자 비교(2026-11-08, 일본어앱 kana_phonetics 의 힌디어판).
/// IPA 는 표준 힌디어(델리) 기준. 조음 위치·모음 그림(assets/images/ipa/)은 임시 — 출시 전에 Grok 그림으로 바꾼다.
class LetterInfo {
  final String letter; // 표에 보이는 글자(모음 부호 묶음은 क + 부호)
  final String roman;
  final String ipa;
  final String group; // vowel·matra·velar·palatal·retroflex·dental·labial·other·nukta
  final String manner; // vowel·tenuis·aspirate·voiced·breathy·nasal·approx·fric·sign
  final String korSim; // 비슷한 한국어 소리
  final String tip; // 한국어 화자에게: 다른 점·요령
  const LetterInfo(this.letter, this.roman, this.ipa, this.group, this.manner, this.korSim, this.tip);
  bool get isVowel => group == 'vowel' || group == 'matra';
}

const _vowels = [
  LetterInfo('अ', 'a', 'ə', 'vowel', 'vowel', '어(짧게)', "'아'보다 입을 덜 벌린 짧은 '어'. 낱말 끝에서는 보통 소리 내지 않는다(नाम = 남)."),
  LetterInfo('आ', 'ā', 'aː', 'vowel', 'vowel', '아(길게)', "입을 크게 벌린 '아'. अ 와 길이·입 모양이 달라 뜻이 갈린다(कम 적다 / काम 일)."),
  LetterInfo('इ', 'i', 'ɪ', 'vowel', 'vowel', '이(짧게)', "짧고 느슨한 '이'. ई 보다 혀가 조금 낮다."),
  LetterInfo('ई', 'ī', 'iː', 'vowel', 'vowel', '이(길게)', "길고 팽팽한 '이'. 입술을 옆으로 편다."),
  LetterInfo('उ', 'u', 'ʊ', 'vowel', 'vowel', '우(짧게)', "짧고 느슨한 '우'. 입술을 덜 내민다."),
  LetterInfo('ऊ', 'ū', 'uː', 'vowel', 'vowel', '우(길게)', "길고 동그랗게 내민 '우'."),
  LetterInfo('ऋ', 'ṛ', 'ɾɪ', 'vowel', 'vowel', '리', "오늘날 힌디어에서는 '리'로 읽는다(कृपया 크리파야)."),
  LetterInfo('ए', 'e', 'eː', 'vowel', 'vowel', '에(길게)', "한국어 '에'보다 조금 좁고 길다. 이중모음이 되지 않게 한 소리로."),
  LetterInfo('ऐ', 'ai', 'ɛː', 'vowel', 'vowel', '애(길게)', "'아이'가 아니라 입을 더 벌린 '애'(है = 헤/해)."),
  LetterInfo('ओ', 'o', 'oː', 'vowel', 'vowel', '오(길게)', "입술을 둥글게 한 긴 '오'. '오우'로 미끄러지지 않는다."),
  LetterInfo('औ', 'au', 'ɔː', 'vowel', 'vowel', '오(입을 더 벌려)', "'아우'가 아니라 입을 더 벌린 '오'(और = 오르). 지역에 따라 '아우'에 가깝게도 들린다."),
  LetterInfo('अं', 'ṁ', '̃ / ŋ', 'vowel', 'sign', '받침 ㅇ·ㄴ·ㅁ', '아누스바라(점) — 앞 모음을 콧소리로 내거나, 뒤 자음에 맞춰 ㅇ·ㄴ·ㅁ 받침이 된다(हिंदी 힌디, अंदर 안다르).'),
  LetterInfo('अः', 'ḥ', 'ɦ', 'vowel', 'sign', '가벼운 ㅎ', '비사르가 — 산스크리트계 낱말 끝의 가벼운 ㅎ. 일상어에서는 드물다.'),
];

const _matras = [
  LetterInfo('का', 'kā', 'kaː', 'matra', 'vowel', '까', 'ा = 아(길게). 글자 오른쪽에 세로 막대.'),
  LetterInfo('कि', 'ki', 'kɪ', 'matra', 'vowel', '끼', 'ि = 이(짧게). 왼쪽에 쓰지만 소리는 자음 뒤.'),
  LetterInfo('की', 'kī', 'kiː', 'matra', 'vowel', '끼-', 'ी = 이(길게). 오른쪽에 쓴다.'),
  LetterInfo('कु', 'ku', 'kʊ', 'matra', 'vowel', '꾸', 'ु = 우(짧게). 글자 아래.'),
  LetterInfo('कू', 'kū', 'kuː', 'matra', 'vowel', '꾸-', 'ू = 우(길게). 글자 아래.'),
  LetterInfo('कृ', 'kṛ', 'kɾɪ', 'matra', 'vowel', '끄리', 'ृ = 리. 글자 아래 갈고리.'),
  LetterInfo('के', 'ke', 'keː', 'matra', 'vowel', '께', 'े = 에. 글자 위 비스듬한 획.'),
  LetterInfo('कै', 'kai', 'kɛː', 'matra', 'vowel', '깨', 'ै = 애. 위 획 두 개.'),
  LetterInfo('को', 'ko', 'koː', 'matra', 'vowel', '꼬', 'ो = 오. 막대 + 위 획.'),
  LetterInfo('कौ', 'kau', 'kɔː', 'matra', 'vowel', '꼬(입을 더 벌려)', 'ौ = 입을 더 벌린 오. 막대 + 위 획 두 개.'),
  LetterInfo('कं', 'kaṁ', 'kəŋ', 'matra', 'sign', '깡', 'ं = 콧소리 받침(점).'),
  LetterInfo('कँ', 'kã', 'kə̃', 'matra', 'sign', '까(콧소리)', 'ँ = 찬드라빈두(달+점). 모음 전체를 콧소리로(हाँ 항).'),
  LetterInfo('क्', 'k', 'k', 'matra', 'sign', 'ㄱ(받침)', '् = 할란트. 모음을 없애 자음만 — 겹자음을 만들 때 쓴다(क्या 캬).'),
];

LetterInfo _c(String l, String r, String ipa, String g, String m, String k, [String extra = '']) => LetterInfo(l, r, ipa, g, m, k, extra);

final _consonants = [
  _c('क', 'ka', 'k', 'velar', 'tenuis', 'ㄲ'),
  _c('ख', 'kha', 'kʰ', 'velar', 'aspirate', 'ㅋ'),
  _c('ग', 'ga', 'ɡ', 'velar', 'voiced', 'ㄱ'),
  _c('घ', 'gha', 'ɡʱ', 'velar', 'breathy', 'ㄱ+ㅎ'),
  _c('ङ', 'ṅa', 'ŋ', 'velar', 'nasal', '받침 ㅇ', '홀로는 거의 안 쓰고 겹자음 안에서만 나온다.'),
  _c('च', 'ca', 'tʃ', 'palatal', 'tenuis', 'ㅉ', "혀를 조금 더 둥글게 해 영어 ch 처럼(चाय 차이)."),
  _c('छ', 'cha', 'tʃʰ', 'palatal', 'aspirate', 'ㅊ'),
  _c('ज', 'ja', 'dʒ', 'palatal', 'voiced', 'ㅈ'),
  _c('झ', 'jha', 'dʒʱ', 'palatal', 'breathy', 'ㅈ+ㅎ'),
  _c('ञ', 'ña', 'ɲ', 'palatal', 'nasal', 'ㄴ(니)', '홀로는 거의 안 쓰고 겹자음 안에서만 나온다.'),
  _c('ट', 'ṭa', 'ʈ', 'retroflex', 'tenuis', 'ㄸ(혀 말아)'),
  _c('ठ', 'ṭha', 'ʈʰ', 'retroflex', 'aspirate', 'ㅌ(혀 말아)'),
  _c('ड', 'ḍa', 'ɖ', 'retroflex', 'voiced', 'ㄷ(혀 말아)'),
  _c('ढ', 'ḍha', 'ɖʱ', 'retroflex', 'breathy', 'ㄷ+ㅎ(혀 말아)'),
  _c('ण', 'ṇa', 'ɳ', 'retroflex', 'nasal', 'ㄴ(혀 말아)'),
  _c('त', 'ta', 't̪', 'dental', 'tenuis', 'ㄸ'),
  _c('थ', 'tha', 't̪ʰ', 'dental', 'aspirate', 'ㅌ'),
  _c('द', 'da', 'd̪', 'dental', 'voiced', 'ㄷ'),
  _c('ध', 'dha', 'd̪ʱ', 'dental', 'breathy', 'ㄷ+ㅎ'),
  _c('न', 'na', 'n', 'dental', 'nasal', 'ㄴ'),
  _c('प', 'pa', 'p', 'labial', 'tenuis', 'ㅃ'),
  _c('फ', 'pha', 'pʰ', 'labial', 'aspirate', 'ㅍ', '구어에서는 f 로도 발음된다(फिर 피르/fir).'),
  _c('ब', 'ba', 'b', 'labial', 'voiced', 'ㅂ'),
  _c('भ', 'bha', 'bʱ', 'labial', 'breathy', 'ㅂ+ㅎ'),
  _c('म', 'ma', 'm', 'labial', 'nasal', 'ㅁ'),
  _c('य', 'ya', 'j', 'other', 'approx', '이·야', '혀를 입천장 가까이 올린 반모음.'),
  _c('र', 'ra', 'ɾ', 'other', 'approx', 'ㄹ(모음 사이)', "혀끝으로 윗잇몸을 한 번 톡 친다 — 한국어 '나라'의 ㄹ. 영어 r 처럼 혀를 말지 않는다."),
  _c('ल', 'la', 'l', 'other', 'approx', 'ㄹ(받침)', "혀끝을 윗잇몸에 붙인 채 소리 낸다 — 한국어 '달'의 받침 ㄹ. र 와 구별."),
  _c('व', 'va', 'ʋ', 'other', 'approx', '와·v 사이', '윗니를 아랫입술에 가볍게 대고 마찰 없이 — 영어 v 와 w 의 중간.'),
  _c('श', 'śa', 'ʃ', 'other', 'fric', '샤·쉬', "혀를 둥글게 한 '쉬' — 영어 sh."),
  _c('ष', 'ṣa', 'ʂ', 'other', 'fric', '샤', '원래 혀를 만 sh. 오늘날 일상 발음은 श 와 거의 같다.'),
  _c('स', 'sa', 's', 'other', 'fric', 'ㅅ', "한국어 'ㅅ'보다 또렷한 s. 'ㅆ'에 가깝다."),
  _c('ह', 'ha', 'ɦ', 'other', 'fric', 'ㅎ', '목에서 울림이 섞인 ㅎ. 모음 사이에서도 약해지지 않는다.'),
  _c('क़', 'qa', 'q', 'nukta', 'tenuis', 'ㅋ(목 깊이)', '누크타(아래 점) — 페르시아·아랍계 낱말. 혀뿌리를 목젖에 대는 깊은 ㅋ. 구어에서는 क 로도 읽는다.'),
  _c('ख़', 'xa', 'x', 'nukta', 'fric', 'ㅋ+ㅎ 마찰', '목 뒤에서 긁는 소리(독일어 Bach 의 ch). ख़ुश 쿠쉬.'),
  _c('ग़', 'ġa', 'ɣ', 'nukta', 'fric', 'ㄱ 마찰', 'ख़ 의 울림 소리. 구어에서는 ग 로도 읽는다.'),
  _c('ज़', 'za', 'z', 'nukta', 'fric', 'z', '영어 z. 한국어에 없다 — ㅈ 이 아니라 ㅅ 을 울려서(ज़रूर 자루르).'),
  _c('फ़', 'fa', 'f', 'nukta', 'fric', 'f', '영어 f. 윗니를 아랫입술에 대고 바람을 낸다.'),
  _c('ड़', 'ṛa', 'ɽ', 'nukta', 'approx', 'ㄹ(혀 말아 튕김)', '혀끝을 말았다가 앞으로 튕기며 ㄹ — 낱말 가운데·끝에 나온다(बड़ा 바라).'),
  _c('ढ़', 'ṛha', 'ɽʱ', 'nukta', 'approx', 'ㄹ+ㅎ', 'ड़ 에 숨을 더한 소리(पढ़ना 파르나).'),
];

/// 표 순서대로 묶음.
List<LetterInfo> lettersOf(String group) => switch (group) {
      'vowel' => _vowels,
      'matra' => _matras,
      _ => _consonants.where((c) => c.group == group).toList(),
    };

LetterInfo? letterInfo(String letter) {
  for (final l in [..._vowels, ..._matras, ..._consonants]) {
    if (l.letter == letter) return l;
  }
  return null;
}

/// 소리나는 곳(조음 위치) 설명 — 묶음별.
String placeOf(LetterInfo l) => switch (l.group) {
      'velar' => tr('연구개음 — 혀 뒤쪽을 여린입천장에 붙였다 뗀다(한국어 ㄱ·ㅋ 자리).'),
      'palatal' => tr('구개음 — 혓몸을 단단한 입천장에 대고 떼며 마찰이 살짝 섞인다(ㅈ·ㅊ 자리).'),
      'retroflex' => tr('권설음 — 혀끝을 위로 말아 입천장 가운데를 친다. 한국어에 없는 자리라 둔탁하게 들린다.'),
      'dental' => tr('치음 — 혀끝을 윗니 뒷면에 붙였다 뗀다. 한국어 ㄷ보다 앞, 권설음 ट 와 짝을 이룬다.'),
      'labial' => tr('양순음 — 두 입술을 붙였다 뗀다.'),
      'nukta' || 'other' => tr('반모음·마찰음 — 혀나 입술을 가까이 대고 공기를 흘린다.'),
      _ => tr('모음 — 혀 높이·앞뒤와 입술 모양, 그리고 길이로 구별한다(짧은·긴 모음 짝).'),
    };

/// 소리 내는 방식 설명 — 힌디어 파열음의 네 갈래가 한국어 화자에게 가장 어렵다.
String mannerOf(LetterInfo l) => switch (l.manner) {
      'tenuis' => tr('무기 무성 — 숨을 내보내지 않는다. 한국어 된소리(ㄲ·ㅉ·ㄸ·ㅃ)에 가깝다. 손바닥을 입 앞에 대면 바람이 거의 없어야 한다.'),
      'aspirate' => tr('유기 무성 — 숨을 세게 내보낸다. 한국어 거센소리(ㅋ·ㅊ·ㅌ·ㅍ)와 비슷하다.'),
      'voiced' => tr('유성 — 처음부터 성대를 울린다. 한국어 첫소리 ㄱ·ㄷ·ㅂ은 울리지 않으니, \'아가\'의 가운데 ㄱ처럼 울리게 한다.'),
      'breathy' => tr('유성 유기 — 성대를 울리면서 숨을 함께 낸다. 한국어에 없다. \'ㄱ\'과 \'ㅎ\'을 따로 내지 말고 한 소리로(घर 가르가 아니라 gʱar).'),
      'nasal' => tr('비음 — 코로 소리를 낸다.'),
      'approx' => tr('흐름소리 — 막지 않고 흘린다.'),
      'fric' => tr('마찰음 — 좁은 틈으로 바람을 비빈다.'),
      'sign' => tr('부호 — 홀로 소리가 아니라 앞뒤 글자의 소리를 바꾼다.'),
      _ => tr('모음'),
    };
