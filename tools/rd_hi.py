#!/usr/bin/env python3
"""힌디어 → 한글 독음(docs/DIALOGUE_NOTES.md §3 표). 슈와 탈락·비음 동화를 규칙으로 처리한다. 틀린 턴은 손으로 고치고 `rd_manual: true`."""
import re, sys, unicodedata

CONS = {'क':'k','ख':'k','ग':'g','घ':'g','ङ':'ng','च':'c','छ':'c','ज':'j','झ':'j','ञ':'n','ट':'t','ठ':'t','ड':'d','ढ':'d','ण':'n',
        'त':'t','थ':'t','द':'d','ध':'d','न':'n','प':'p','फ':'p','ब':'b','भ':'b','म':'m','य':'y','र':'r','ल':'l','व':'w','श':'sh','ष':'sh','स':'s','ह':'h'}
NUKTA = {'ड':'r','ढ':'r','ज':'j','फ':'p','क':'k','ख':'k','ग':'g'}
MATRA = {'ा':'a','ि':'i','ी':'i','ु':'u','ू':'u','े':'e','ै':'e','ो':'o','ौ':'au','ृ':'ri','ॉ':'o','ॅ':'e'}
INDEP = {'अ':'a','आ':'a','इ':'i','ई':'i','उ':'u','ऊ':'u','ए':'e','ऐ':'e','ओ':'o','औ':'au','ऋ':'ri','ऑ':'o'}
FIXED = {'मैं':'메','है':'헤','हैं':'헹','हूं':'훙','हूँ':'훙','नहीं':'나힝','यहां':'야항','वहां':'와항','कहां':'카항','यहाँ':'야항','वहाँ':'와항','कहाँ':'카항','क्या':'캬','और':'아우르','यह':'예','वह':'워','रुपये':'루파예','रुपए':'루파에','हम्म':'흠'}
ONSET = {'k':'ㅋ','g':'ㄱ','c':'ㅊ','j':'ㅈ','t':'ㅌ','d':'ㄷ','n':'ㄴ','p':'ㅍ','b':'ㅂ','m':'ㅁ','r':'ㄹ','l':'ㄹ','s':'ㅅ','h':'ㅎ','':'ㅇ','ng':'ㅇ','sh':'ㅅ','y':'ㅇ','w':'ㅇ'}
L = 'ㄱㄲㄴㄷㄸㄹㅁㅂㅃㅅㅆㅇㅈㅉㅊㅋㅌㅍㅎ'
V = 'ㅏㅐㅑㅒㅓㅔㅕㅖㅗㅘㅙㅚㅛㅜㅝㅞㅟㅠㅡㅢㅣ'
T = ' ㄱㄲㄳㄴㄵㄶㄷㄹㄺㄻㄼㄽㄾㄿㅀㅁㅂㅄㅅㅆㅇㅈㅊㅋㅌㅍㅎ'
VOW = {'a':'ㅏ','i':'ㅣ','u':'ㅜ','e':'ㅔ','o':'ㅗ'}
YV = {'a':'ㅑ','i':'ㅣ','u':'ㅠ','e':'ㅖ','o':'ㅛ'}
WV = {'a':'ㅘ','i':'ㅟ','u':'ㅜ','e':'ㅞ','o':'ㅝ'}
SHV = {'a':'ㅑ','i':'ㅣ','u':'ㅠ','e':'ㅖ','o':'ㅛ'}
ALONE = {'k':'크','g':'그','c':'치','j':'즈','t':'트','d':'드','p':'프','b':'브','r':'르','s':'스','sh':'슈','h':'흐','y':'이','w':'우','ng':'그'}
CODA = {'m':'ㅁ','n':'ㄴ','l':'ㄹ','ng':'ㅇ'}


def syl(o, v, c=' '):
    return chr(0xAC00 + (L.index(o) * 21 + V.index(v)) * 28 + T.index(c))


def parse(w):
    """낱말 → [자음, 모음(None=모음 없음), 비음, 묶음 여부] 목록."""
    w = unicodedata.normalize('NFD', w)
    out, i = [], 0
    while i < len(w):
        ch = w[i]
        if ch in CONS:
            c = CONS[ch]
            n = w[i + 1] if i + 1 < len(w) else ''
            if n == '़':
                c = NUKTA.get(ch, c); i += 1
                n = w[i + 1] if i + 1 < len(w) else ''
            cluster = bool(out) and out[-1][1] is None and out[-1][4]
            if n == '्':
                out.append([c, None, False, cluster, True]); i += 2; continue
            if n in MATRA:
                out.append([c, MATRA[n], False, cluster, False]); i += 2
            else:
                out.append([c, 'A', False, cluster, False]); i += 1  # A = 지울 수 있는 내재 모음
        elif ch in INDEP:
            out.append(['', INDEP[ch], False, False, False]); i += 1
        elif ch in 'ंँ':
            if out: out[-1][2] = True
            i += 1
        elif ch == 'ः':
            i += 1
        else:
            i += 1
    return out


def schwa(s):
    if not s: return s
    if s[-1][1] == 'A' and len(s) > 1 and not s[-1][2] and not (s[-1][3] and s[-1][0] in ('r', 'y', 'w')):  # मित्र·वाक्य 처럼 र·य·व 로 끝나는 묶음만 끝 모음 유지
        s[-1][1] = None
    for i in range(len(s) - 2, 0, -1):
        # 모음 C a C 모음 → 탈락
        if s[i][1] == 'A' and not s[i][2] and not s[i][3] and s[i - 1][1] is not None and s[i + 1][1] is not None and not s[i + 1][3]:
            s[i][1] = None
    return s


def nasal_coda(nxt):
    if nxt in ('p', 'b', 'm'): return 'ㅁ'
    if nxt in ('t', 'd', 'c', 'j', 'n', 's', 'sh'): return 'ㄴ'
    return 'ㅇ'


def word(w):
    if w in FIXED: return FIXED[w]
    s = schwa(parse(w))
    out, i = [], 0
    while i < len(s):
        c, v, nas, _, _ = s[i]
        nxt = s[i + 1] if i + 1 < len(s) else None
        if v is None:
            if nxt and nxt[0] == c and c not in CODA and nxt[1] is not None:  # 겹자음(बच्चा → 바차)
                i += 1
                continue
            # y 묶음(क्या → 캬)
            if nxt and nxt[0] == 'y' and nxt[1] not in (None,) and c in ONSET and c not in ('y', 'w', 'r', 'h'):
                nxt[0] = 'Y' + c
                i += 1
                continue
            if out and out[-1][1] and c in CODA and (not nxt or nxt[1] is not None or True) and out[-1][2] == ' ':
                out[-1][2] = CODA[c]
            else:
                if c in CODA and out and out[-1][1] is None and out[-1][0]:  # 끝 자음군(पॉपकॉर्न → 코른, रस्म → 라슴)
                    x = out[-1][0]
                    out[-1][0] = x[:-1] + chr(ord(x[-1]) + T.index(CODA[c]))
                elif c in CODA:  # फ़िल्म → 필름
                    out.append([{'m': '름', 'n': '른', 'l': '를', 'ng': '응'}[c] if out and out[-1][2] == 'ㄹ' else {'m': '므', 'n': '느', 'l': '르', 'ng': '응'}[c], None, ' '])
                elif c == 'g' and not nxt and out and out[-1][2] == 'ㅇ':  # मीटिंग → 미팅
                    pass
                elif not (c == 'h' and not nxt):  # 끝 ह 는 적지 않음(वाह → 와)
                    out.append([ALONE.get(c, ''), None, ' '])
            i += 1
            continue
        vv = 'a' if v == 'A' else v
        pre = []
        if vv == 'au': vs = ['a', 'u']
        elif vv == 'ri': pre, vs = ['ri'], []
        else: vs = [vv]
        if pre:
            out.append([ONSET.get(c.lstrip('Y'), 'ㅇ') if c else 'ㅇ', 'ㅡ', ' ']) if c else None
            out.append(['ㄹ', 'ㅣ', ' '])
        else:
            v0 = vs[0]
            if c.startswith('Y'): o, m = ONSET[c[1:]], YV[v0]
            elif c == 'y': o, m = 'ㅇ', YV[v0]
            elif c == 'w': o, m = 'ㅇ', WV[v0]
            elif c == 'sh': o, m = 'ㅅ', SHV[v0]
            else: o, m = ONSET.get(c, 'ㅇ'), VOW[v0]
            if c == 'l' and out and out[-1][1] and out[-1][2] == ' ':  # 모음 사이 ㄹ 은 ㄹㄹ(चलो → 찰로)
                out[-1][2] = 'ㄹ'
            out.append([o, m, ' '])
            for x in vs[1:]: out.append(['ㅇ', VOW[x], ' '])
        if nas: out[-1][2] = nasal_coda(nxt[0].lstrip('Y') if nxt else '')
        i += 1
    return ''.join(x[0] if x[1] is None else syl(*x) for x in out)


def convert(text):
    def f(m):
        return word(m.group(0))
    text = text.replace('।', '.').replace('॥', '.')
    return re.sub(r'[ऀ-ॿ]+', f, text)


if __name__ == '__main__':
    for a in sys.argv[1:] or ['नमस्ते मेरा नाम प्रिया है। तुम कहाँ से हो?', 'समझना कमरा दिल्ली हिंदी शहर बढ़िया प्यार मित्र ज़रूर ठीक अंदर बंद चाय पानी दोस्त रहा जाऊँगा']:
        print(convert(a))
