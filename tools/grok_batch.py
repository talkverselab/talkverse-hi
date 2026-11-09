# -*- coding: utf-8 -*-
"""Grok 회화 재작성 일괄(PC 크롬 9246) — plan 순서대로, 방당 N편, 편마다 한 줄만 보낸다.
  GROK_CDP_PORT=9246 python3 tools/grok_batch.py [--per-room 10] [--only id,id]
- 방의 첫 메시지 = 규칙(tools/prompts/rewrite_grok_hi.md) 첨부 + 「앞으로 파일 이름 한 줄만」 약속 + 첫 편.
- 답 → data/review/grok/out/<id>.md. 이미 있으면 건너뜀(이어받기).
- 검사: 턴 수·화자 순서 같음, expressions 전부 대사에 남음, 초안과 똑같은 줄 ≤ 2. 어긋나면 같은 방에 한 줄로 한 번 다시 요청.
- 답은 3분까지만(사용자 지시 2026-11-10) — 넘으면 grok_text 가 생성을 중지하고 코드 4, 그 편은 실패로 남김(다음 실행 때 다시).
- 한도(종료 코드 3)면 멈춘다. 상태 data/review/grok/batch_state.json(방 주소·방 안 편 수).
"""
import json, os, re, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, 'data/review/grok/src')
OUT = os.path.join(ROOT, 'data/review/grok/out')
ST = os.path.join(ROOT, 'data/review/grok/batch_state.json')
RULES = os.path.join(ROOT, 'tools/prompts/rewrite_grok_hi.md')
TOOL = os.path.join(ROOT, 'tools/grok_text.py')
TMP = os.environ.get('GROK_TMP', '/tmp')


def turns(path):
    return [l.split('|') for l in open(path, encoding='utf-8') if re.match(r'^[A-Z] \|', l)]


def head(path, key):
    for l in open(path, encoding='utf-8'):
        if l.startswith(key + ':'):
            return l.split(':', 1)[1].strip()
    return ''


def check(i):
    s, o = os.path.join(SRC, i + '.txt'), os.path.join(OUT, i + '.md')
    a, b = turns(s), turns(o)
    errs = []
    if [t[0].strip() for t in a] != [t[0].strip() for t in b]:
        errs.append('턴 수·화자 순서(%d→%d)' % (len(a), len(b)))
    text = ' '.join(t[1] for t in b if len(t) > 1)
    for e in [x.strip() for x in head(s, 'expressions').split(';') if x.strip()]:
        if e not in text:
            errs.append('표현 빠짐 ' + e)
    same = len({t[1].strip() for t in a if len(t) > 1} & {t[1].strip() for t in b if len(t) > 1})
    if same > 2:
        errs.append('초안과 같은 줄 %d' % same)
    if not all(len(t) >= 5 and 'emotion=' in t[4] for t in b):
        errs.append('emotion 칸')
    return errs


def send(msg, out, atts, chat):
    cmd = ['python3', TOOL, '-m', msg, out] + atts + (['--chat', chat] if chat else []) + ['--wait', '180']
    r = subprocess.run(cmd, capture_output=True, text=True, env=dict(os.environ, GROK_CDP_PORT='9246'))
    print(r.stdout.strip()[-300:], r.stderr.strip()[-300:], flush=True)
    if r.returncode == 3:
        sys.exit('LIMIT — 한도. 나중에 이어서 실행')
    m = re.search(r'CHAT (https://grok\.com/c/[\w-]+)', r.stdout)
    return r.returncode, (m.group(1) if m else chat)


def main():
    a = sys.argv[1:]
    per = int(a[a.index('--per-room') + 1]) if '--per-room' in a else 10
    ids = [p['id'] for p in json.load(open(os.path.join(ROOT, 'data/review/write/plan_hi.json')))]
    if '--only' in a:
        ids = a[a.index('--only') + 1].split(',')
    st = json.load(open(ST)) if os.path.exists(ST) else {'chat': '', 'n': per}
    os.makedirs(OUT, exist_ok=True)
    for i in ids:
        out = os.path.join(OUT, i + '.md')
        if os.path.exists(out):
            continue
        att = os.path.join(TMP, i + '.txt')
        subprocess.run(['cp', os.path.join(SRC, i + '.txt'), att], check=True)
        if st['n'] >= per or not st['chat']:
            msg = '첨부한 rewrite_grok_hi.md 가 이 방의 규칙이다. 앞으로는 파일 이름 한 줄만 보낸다. 첫 편: %s.txt' % i
            rc, chat = send(msg, out, [RULES, att], '')
            st = {'chat': chat, 'n': 0}
        else:
            rc, chat = send(i + '.txt', out, [att], st['chat'])
        st['n'] += 1
        json.dump(st, open(ST, 'w'))
        if rc != 0 or not os.path.exists(out):
            print('실패', i, rc, flush=True); continue
        errs = check(i)
        if errs:
            print('다시', i, errs, flush=True)
            send('%s.txt 다시: %s' % (i, ', '.join(errs)), out, [], st['chat'])
            errs = check(i)
        print('끝', i, errs or 'OK', flush=True)


if __name__ == '__main__':
    main()
