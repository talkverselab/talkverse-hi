#!/usr/bin/env python3
"""Grok 재작성본(data/review/grok/out/<id>.md)마다 Gemini 검수 프롬프트를 만들고 목록(<프롬프트>\t<저장>)을 쓴다. 이미 검수한 편은 뺀다.
  python3 tools/gemini_prompts_hi.py <프롬프트 폴더> <목록.tsv> [편id ...]
그다음 /usr/bin/python3 tools/gemini_batch.py <목록.tsv> (M4 Gemini 크롬 9226 — ssh -L 터널, vi·hu 와 같이 씀)."""
import glob, os, re, sys
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
T = open(os.path.join(ROOT, 'tools/prompts/review_gemini_hi.md'), encoding='utf-8').read().split('```')[1].strip('\n')
OUT = os.path.join(ROOT, 'data/review/gemini')


def parse(path):
    head, lines, n = {}, [], 0
    for l in open(path, encoding='utf-8'):
        l = l.rstrip('\n')
        m = re.match(r'^([a-z]+): (.*)$', l)
        if m and not lines:
            head[m.group(1)] = m.group(2)
        elif re.match(r'^[A-Z] \|', l):
            c = [x.strip() for x in l.split('|')]
            n += 1
            lines.append(f'{n} {c[0]}: {c[1]} / {c[2] if len(c) > 2 else ""}')
        elif re.match(r'^\s+♀ \|', l):
            c = [x.strip() for x in l.split('|')]
            lines.append(f'   ♀: {c[1]}' + (f' / {c[2]}' if len(c) > 2 and c[2] else ''))
    return head, lines


def main():
    pdir, lst, only = sys.argv[1], sys.argv[2], set(sys.argv[3:])
    os.makedirs(pdir, exist_ok=True); os.makedirs(OUT, exist_ok=True)
    rows = []
    for f in sorted(glob.glob(os.path.join(ROOT, 'data/review/grok/out/*.md'))):
        i = os.path.basename(f)[:-3]
        if '.' in i or (only and i not in only): continue  # .prev·.g0 는 앞 답
        dst = os.path.join(OUT, i + '.md')
        if os.path.exists(dst): continue
        h, lines = parse(f)
        if not lines: continue
        roles = h.get('speakers', '').replace('{name}', '학습자({name})')
        p = T.format(id=i, roles=roles, scene=h.get('scene', ''), register=h.get('register', ''), twist=h.get('twist', ''), lines='\n'.join(lines))
        pf = os.path.join(pdir, i + '.txt'); open(pf, 'w', encoding='utf-8').write(p + '\n')
        rows.append(f'{pf}\t{dst}')
    open(lst, 'w', encoding='utf-8').write('\n'.join(rows) + ('\n' if rows else ''))
    print(len(rows), '건')


if __name__ == '__main__':
    main()
