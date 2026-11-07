#!/usr/bin/python3
"""회화 파일의 감정 칸 → 감정 계획 자동 생성(사용자 지시 2026-11-07 — 감정을 손으로 다시 적지 않는다).
  python3 tools/tts/make_plan.py [편id...]   (없으면 emotion 이 다 있는 편 전부) → data/tts/plan/<편id>.json
턴의 `emotion` 또는 `segs`([[감정, 본문], …])를 읽는다. 여성판은 `tl_f` + `segs_f`(없으면 그 턴 첫 감정 하나).
목소리: 고정 인물은 이름으로, 단역은 편의 `cast` 칸 → 없으면 genders 로 순서대로. 감정이 빠진 턴이 있는 편은 만들지 않고 알린다.
make_jobs.py 가 (목소리, 감정)별 참고 음성을 쓰므로 이 계획만 있으면 그 감정으로 생성된다."""
import json, re, sys
import ttslib as L

NAMED = {'प्रिया': 'priya', 'अनन्या': 'ananya', 'रोहन': 'rohan', 'अर्जुन': 'arjun'}
EXTRA = {'m': ['man_m', 'man_y', 'man_o'], 'f': ['woman_m', 'woman_y', 'woman_o']}
OLD = re.compile('दादी|नानी|बूढ़')
MOM = re.compile('आंटी|माँ|मम्मी')


def read(s):
    """음성 모델이 읽을 글: 지문 괄호·따옴표를 빼고 말줄임은 쉼표로."""
    s = L.PAREN.sub('', s).replace('...', ',').replace('…', ',')
    return ' '.join(re.sub(r'["“”‘’]', '', s).split())


def cast(d):
    out, used = {}, {'m': 0, 'f': 0}
    for k, name in d['speakers'].items():
        if k == 'A':
            continue
        v = d.get('cast', {}).get(k) or NAMED.get(name)
        if not v:
            g = d.get('genders', {}).get(k, 'm')
            v = 'woman_o' if OLD.search(name) else EXTRA[g][used[g] % 3]
            used[g] += 1
        out[k] = v
    return out


def segs(t, key, tl):
    s = t.get(key)
    if s:
        return [[e, x, read(x)] for e, x in s]
    return [[t.get('emotion') or (t.get('segs') or [[None]])[0][0], tl, read(tl)]]


def build(ep):
    d = json.load(open(L.EP[ep], encoding='utf-8'))
    T = {}
    for t in d['turns']:
        if not t.get('emotion') and not t.get('segs'):
            return None, f"턴 {t['num']} 감정 없음"
        x = {'segs': segs(t, 'segs', t['tl'])}
        if t.get('tl_f'):
            x['f'] = {'segs': segs(t, 'segs_f', t['tl_f'])}
        T[str(t['num'])] = x
    P = {'ep': ep, 'cast': cast(d), 'turns': T}
    if d.get('speakers_f'):
        P['cast_f'] = {k: NAMED.get(v, v) for k, v in d['speakers_f'].items()}
    return P, None


def main():
    ids = sys.argv[1:] or sorted(L.EP)
    ok = 0; skip = []
    for ep in ids:
        P, e = build(ep)
        if not P:
            skip.append(f'{ep}: {e}'); continue
        json.dump(P, open(f'{L.R}/data/tts/plan/{ep}.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
        ok += 1
    print('계획', ok, '건너뜀', len(skip))
    if sys.argv[1:]:
        print(*skip, sep='\n')


if __name__ == '__main__':
    main()
