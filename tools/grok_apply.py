# -*- coding: utf-8 -*-
"""검수 끝난 Grok 원고(data/review/grok/out/<id>.md)를 앱 회화 JSON 으로 옮긴다(2026-11-22).
  python3 tools/grok_apply.py            # ios_pick_hi.json 의 66편
대사(tl·tl_f)·번역(ko·ko_f)·note·emotion·at·stamp·title·scene 은 Grok 원고 그대로. Claude 는 문장을 고치지 않는다.
나머지 머리 칸(speakers·genders·twist·flags…)은 초안 JSON 에서. rd 는 check_dialogues --fix-rd 로 다시 채운다.
R0 는 R1 초안에서 골라 id·region 을 r0 로 바꿔 R0/<섬>/ 에 쓴다. 고르지 않은 초안은 data/review/drafts/ 로 옮긴다.
"""
import glob, json, os, re, shutil, sys
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DLG = os.path.join(ROOT, 'assets/data/dialogues')
OUT = os.path.join(ROOT, 'data/review/grok/out')
DRAFTS = os.path.join(ROOT, 'data/review/drafts')


def parse(path):
    head, turns = {}, []
    for l in open(path, encoding='utf-8'):
        l = l.rstrip('\n')
        m = re.match(r'^([a-z_]+): (.*)$', l)
        if m and not turns:
            head[m.group(1)] = m.group(2).strip()
        elif re.match(r'^[A-Z] \|', l):
            c = [x.strip() for x in l.split('|')]
            t = {'speaker': c[0], 'tl': c[1], 'ko': c[2], 'note': c[3]}
            for x in c[4:]:
                k, _, v = x.partition('=')
                t[k.strip()] = v.strip()
            turns.append(t)
        elif re.match(r'^\s+♀ \|', l) and turns:
            c = [x.strip() for x in l.split('|')]
            turns[-1]['tl_f'] = c[1]
            if len(c) > 2 and c[2]:
                turns[-1]['ko_f'] = c[2]
    return head, turns


def build(draft, head, gt):
    d = dict(draft)
    d.pop('draft', None)
    d['reviewed'] = 'grok+gemini 2026-11-18'
    for k in ('title', 'scene'):
        if head.get(k):
            d[k] = head[k]
    old = draft['turns']
    assert len(old) == len(gt), (draft['id'], len(old), len(gt))
    turns = []
    for n, (o, g) in enumerate(zip(old, gt), 1):
        assert o['speaker'] == g['speaker'], (draft['id'], n)
        t = {'num': n, 'speaker': g['speaker'], 'tl': g['tl']}
        if g.get('tl_f'):
            t['tl_f'] = g['tl_f']
        t['ko'] = g['ko']
        if g.get('ko_f'):
            t['ko_f'] = g['ko_f']
        t['note'] = g['note']
        tags = [x for x in o.get('tags', []) if not x.startswith('expr:') or x[5:] in g['tl']]
        tags += ['expr:' + e for e in d.get('expressions', []) if e in g['tl'] and 'expr:' + e not in tags]
        if tags:
            t['tags'] = tags
        em = [x for x in g.get('emotion', '').split('+') if x]
        if em:
            t['emotion'] = em[0]
            if len(em) > 1:
                t['segs'] = [[x] for x in em]
        for k in ('at', 'stamp'):
            if g.get(k):
                t[k] = g[k]
        if o.get('rd_manual') and o.get('tl') == g['tl']:  # 손으로 단 독음은 대사가 그대로일 때만 유지
            t['rd'] = o['rd']; t['rd_manual'] = True
        turns.append(t)
    d['turns'] = turns
    return d


def main():
    pick = json.load(open(os.path.join(ROOT, 'data/review/write/ios_pick_hi.json')))
    src = {os.path.basename(p)[:-5]: p for p in glob.glob(f'{DLG}/R*/*/*.json')}
    keep, wrote = set(), []
    for lv in ('R0', 'R1', 'R2', 'R3', 'R4'):
        for i in pick[lv]:
            i = i.split()[0]
            draft = json.load(open(src[i], encoding='utf-8'))
            head, gt = parse(os.path.join(OUT, i + '.md'))
            d = build(draft, head, gt)
            if lv == 'R0':
                d['id'] = 'r0' + i[2:]; d['region'] = 'R0'
            dst = os.path.join(DLG, lv, d['island'], d['id'] + '.json')
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            open(dst, 'w', encoding='utf-8').write(json.dumps(d, ensure_ascii=False, indent=1) + '\n')
            keep.add(os.path.abspath(dst)); wrote.append(dst)
    moved = 0
    for i, p in src.items():
        if os.path.abspath(p) in keep:
            continue
        rel = os.path.relpath(p, DLG)
        dst = os.path.join(DRAFTS, rel)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        r = os.system(f'git -C "{ROOT}" mv "{p}" "{dst}" 2>/dev/null') if '--git' in sys.argv else 1
        if r:
            shutil.move(p, dst)
        moved += 1
    for dpath in sorted(glob.glob(f'{DLG}/R*/*'), reverse=True):
        if os.path.isdir(dpath) and not os.listdir(dpath):
            os.rmdir(dpath)
    print('씀', len(wrote), '· 초안 옮김', moved)


if __name__ == '__main__':
    main()
