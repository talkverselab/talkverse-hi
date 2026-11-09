#!/usr/bin/env python3
"""회화 편 JSON → Grok 원고(한 편 = 텍스트 한 장). python3 tools/grok_src.py [편id...]  (없으면 150편 전부) → data/review/grok/src/<id>.txt
줄 형식: `화자 | 힌디어 | 한국어 | note | emotion=…` (감정이 바뀌면 `emotion=a+b`). 학습자 여성판이 다른 줄은 바로 아래 `  ♀ | 힌디어 | 한국어(다를 때만)`.
규칙은 tools/prompts/rewrite_grok_hi.md(방 첫 메시지에 첨부), 그다음부터는 파일 이름 한 줄만 보낸다(사용자 지시 2026-11-09 프롬프트 최소화)."""
import glob, json, os, sys
R = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EP = {os.path.basename(p)[:-5]: p for p in glob.glob(f'{R}/assets/data/dialogues/R*/*/*.json')}


def emo(t):
    if t.get('segs'):
        return '+'.join(s[0] for s in t['segs'])
    return t.get('emotion', '')


def one(ep):
    d = json.load(open(EP[ep], encoding='utf-8'))
    L = [f"=== {d['id']}", f"level: {d['region']}", f"kind: {d['kind']}", f"title: {d['title']}", f"emoji: {d.get('emoji', '')}",
         f"scene: {d['scene']}", 'speakers: ' + ' · '.join(f'{k}={v}' for k, v in d['speakers'].items()),
         f"register: {d['register']}", f"twist: {d['twist']} {d['twist_type']}", f"goal: {d.get('goal', '')}",
         'expressions: ' + '; '.join(d.get('expressions', []))]
    if d.get('speakers_f'):
        L.append('speakers_f: ' + ' · '.join(f'{k}={v}' for k, v in d['speakers_f'].items()))
    for t in d['turns']:
        extra = ''.join(f' | {k}={t[k]}' for k in ('at', 'stamp') if t.get(k))
        L.append(f"{t['speaker']} | {t['tl']} | {t['ko']} | {t.get('note', '')} | emotion={emo(t)}{extra}")
        if t.get('tl_f'):
            L.append(f"  ♀ | {t['tl_f']} | {t.get('ko_f', '')}")
    return '\n'.join(L) + '\n'


if __name__ == '__main__':
    ids = sys.argv[1:] or sorted(EP)
    os.makedirs(f'{R}/data/review/grok/src', exist_ok=True)
    for ep in ids:
        open(f'{R}/data/review/grok/src/{ep}.txt', 'w', encoding='utf-8').write(one(ep))
    print(len(ids), '편')
