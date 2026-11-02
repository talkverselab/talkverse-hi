import 'package:flutter_test/flutter_test.dart';
import 'package:hindi_universe/services/devanagari.dart';

void main() {
  test('글자 풀이 — 자음·모음 부호·비음', () {
    final g = Devanagari.split('हूँ');
    expect(g.map((x) => x.text).toList(), ['ह', '◌ू', '◌ँ']);
    expect(g.map((x) => x.sound).toList(), ['ㅎ', '긴 우', 'ㅇ']);
  });
  test('결합 자음', () {
    final g = Devanagari.split('नमस्ते');
    expect(g.map((x) => x.text).toList(), ['न', 'म', 'स्त', '◌े']);
    expect(g[2].kind, GlyphKind.conjunct);
  });
  test('누크타', () {
    expect(Devanagari.split('ज़रूर').first.sound, 'ㅈ(z)');
  });
  test('말투 꼬리표', () {
    expect(Devanagari.register('और तुम?')?.label, '반말 तुम');
    expect(Devanagari.register('माफ़ कीजिए, संग्रहालय कहाँ है?')?.label, '존댓말 आप');
    expect(Devanagari.register('हाँ, दो महीने से।'), isNull);
    expect(Devanagari.gender('रहा हूँ = ~하는 중(남성)')?.label, '남성형');
  });
}
