#!/usr/bin/env python3
"""힌디어 회화 검사기. python3 tools/check_dialogues.py [--fix-rd] [파일…] (파일 없으면 R1~R3 전부)
오류는 고칠 때까지 남고, 경고는 참고. 끝에 묶음 비율(카오스 30% 이상)을 낸다."""
import collections, json, re, sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
from rd_hi import convert

ROOT = Path(__file__).resolve().parent.parent
BASE = ROOT / 'assets/data/dialogues'
TURNS = {'R1': (6, 8), 'R2': (8, 12), 'R3': (12, 16)}
WORDS = {'R1': (3, 8), 'R2': (4, 12), 'R3': (5, 18)}
TYPES = {'chaos', 'slip', 'reveal', 'emotion', 'ignore'}
NEED = ['id', 'region', 'island', 'kind', 'title', 'emoji', 'scene', 'speakers', 'register', 'twist', 'twist_type', 'goal', 'expressions', 'turns']
DEV = re.compile(r'[ऀ-ॿ]')


def wc(s):
    s = re.sub(r'\([^)]*\)', ' ', s)
    return len([w for w in re.split(r'[\s।॥!?,.;:…"“”‘’—-]+', s) if w and not re.fullmatch(r'[^\w{}]+', w)])


def check(path, fix):
    d = json.loads(path.read_text(encoding='utf-8'))
    err, warn = [], []
    for k in NEED:
        if k not in d: err.append(f'칸 없음 {k}')
    if err: return d, err, warn
    r, turns = d['region'], d['turns']
    lo, hi = TURNS[r]
    if not lo <= len(turns) <= hi: err.append(f'턴 수 {len(turns)} (기준 {lo}~{hi})')
    if d['twist_type'] not in TYPES: err.append('twist_type')
    if not 1 <= d['twist'] <= len(turns): err.append('twist 턴 번호')
    if d['speakers'].get('A') != '{name}': err.append('A 는 {name}')
    if len(d['expressions']) < 2: err.append('표현 2개 이상')
    a, b = (WORDS[r])
    prev = None
    changed = False
    for i, t in enumerate(turns, 1):
        n = f"턴{t.get('num')}"
        if t.get('num') != i: err.append(f'{n} 번호')
        for k in ('speaker', 'tl', 'ko', 'note'):
            if not t.get(k): err.append(f'{n} {k} 없음')
        tl = t.get('tl', '')
        if t.get('speaker') not in d['speakers']: err.append(f'{n} 화자 {t.get("speaker")}')
        if not DEV.search(tl): err.append(f'{n} 데바나가리 없음')
        w = wc(tl)
        chat = d['kind'] == 'chat'
        if w > b or (w < (1 if chat else a) and i != d['twist'] and i != len(turns)):
            (warn if chat or w == a - 1 else err).append(f'{n} 단어 수 {w} (기준 {a}~{b})')
        if t.get('speaker') == prev: warn.append(f'{n} 같은 화자 연속')
        prev = t.get('speaker')
        if 'tl_f' in t and t['tl_f'] == tl: err.append(f'{n} tl_f 가 tl 과 같음')
        if fix and not t.get('rd_manual'):
            for src, dst in (('tl', 'rd'), ('tl_f', 'rd_f')):
                if src in t:
                    v = convert(t[src])
                    if t.get(dst) != v: t[dst] = v; changed = True
        if not t.get('rd') : err.append(f'{n} rd 없음')
        elif DEV.search(t['rd']): err.append(f'{n} rd 에 데바나가리')
    if d['island'] == 'love' and 'speakers_f' not in d: err.append('love 편은 speakers_f')
    if fix and changed:
        path.write_text(json.dumps(d, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    return d, err, warn


def main():
    args = [a for a in sys.argv[1:] if a != '--fix-rd']
    fix = '--fix-rd' in sys.argv
    files = [Path(a) for a in args] or sorted(BASE.glob('R[123]/*/*.json'))
    bad = 0; tw = collections.Counter(); by = collections.Counter()
    for f in files:
        d, e, w = check(f, fix)
        tw[d.get('twist_type')] += 1; by[d.get('region')] += 1
        if e: bad += 1
        for x in e: print(f'오류 {f.name}: {x}')
        for x in w: print(f'경고 {f.name}: {x}')
    n = len(files)
    print(f'{n}편 · 오류 편 {bad} · {dict(by)} · 반전 {dict(tw)} · 카오스 {tw["chaos"] / max(n, 1):.0%}')
    sys.exit(1 if bad else 0)


if __name__ == '__main__':
    main()
