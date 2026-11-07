#!/usr/bin/python3
"""감정 계획 검사(힌디어). python3 tools/tts/check_plan.py [편id...] — 문제 있는 편만 출력하고 끝에 합계."""
import json, os, re, sys
import ttslib as L
V, EP = L.V, L.EP
norm = lambda s: re.sub(r'[^ऀ-ॣ०-ॿ{}a-z]', '', L.PAREN.sub('', s))
ids = sys.argv[1:] or L.planned()
bad = miss = 0
for ep in ids:
    f = f'{L.R}/data/tts/plan/{ep}.json'
    if not os.path.exists(f):
        miss += 1; print('없음', ep); continue
    errs = []
    P = json.load(open(f, encoding='utf-8')); d = json.load(open(EP[ep], encoding='utf-8'))
    for k in d['speakers']:
        if k != 'A' and P.get('cast', {}).get(k) not in V['voices']:
            errs.append(f'cast {k}')
    for k, v in P.get('cast_f', {}).items():
        if v not in V['voices']: errs.append(f'cast_f {k}')
    for t in d['turns']:
        T = P.get('turns', {}).get(str(t['num']))
        if not T or not T.get('segs'):
            errs.append(f"턴 {t['num']} 없음"); continue
        if t.get('tl_f') and not (T.get('f') or {}).get('segs'):
            errs.append(f"턴 {t['num']} 여성판 segs 없음")
        for X, want in ((T, t['tl']), (T.get('f'), t.get('tl_f'))):
            if not X or not want: continue
            got = ''.join(s[1] for s in X['segs'])
            if norm(got) != norm(want): errs.append(f"턴 {t['num']} 본문 다름: {got} / {want}")
            for s in X['segs']:
                if s[0] not in V['emotions']: errs.append(f"턴 {t['num']} 감정 {s[0]}")
    if errs:
        bad += 1; print(ep, *errs[:8], sep='\n  ')
print('검사', len(ids), '문제', bad, '없음', miss)
