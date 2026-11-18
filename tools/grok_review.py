# -*- coding: utf-8 -*-
"""Gemini 검수 지적을 Grok 에 넘겨 그 편을 다시 쓰게 한다(2026-11-18). Claude 는 문장을 고치지 않는다.
  GROK_CDP_PORT=9246 python3 tools/grok_review.py [id,id,...] [--per-room 4]
- 지적이 0개인 편은 건너뛴다. 이미 반영한 편(out/<id>.g0.md 있음)도 건너뛴다.
- 지금 답(out/<id>.md)을 <id>.txt 로 첨부하고 지적 원문을 그대로 붙인다. 앞 답은 out/<id>.g0.md.
- 다시 쓴 뒤 grok_batch.check(턴 수·화자·표현·초안과 같은 줄)로 검사.
"""
import glob, os, re, shutil, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import grok_batch as gb
GEM = os.path.join(gb.ROOT, 'data/review/gemini')


def findings(i):
    p = os.path.join(GEM, i + '.md')
    if not os.path.exists(p):
        return None
    t = open(p, encoding='utf-8').read()
    t = t.split('Gemini의 응답', 1)[-1].strip()
    counts = re.findall(r'—\s*(\d+)\s*개', t)
    if counts and all(c == '0' for c in counts):
        return ''
    return re.sub(r'\n{2,}', '\n', t)


def main():
    a = sys.argv[1:]
    per = int(a[a.index('--per-room') + 1]) if '--per-room' in a else 4
    ids = a[0].split(',') if a and not a[0].startswith('--') else sorted(
        os.path.basename(f)[:-3] for f in glob.glob(os.path.join(GEM, '*.md')))
    chat, n = '', per
    for i in ids:
        out = os.path.join(gb.OUT, i + '.md'); g0 = os.path.join(gb.OUT, i + '.g0.md')
        f = findings(i)
        if f is None or os.path.exists(g0):
            continue
        if f == '':
            print('끝', i, '지적 없음', flush=True); continue
        shutil.copy(out, g0)
        att = os.path.join(gb.TMP, i + '.txt'); shutil.copy(g0, att)
        body = ('%s.txt — 네가 쓴 대사다. 원어민 검수 지적을 반영해 해당 줄을 고치고, 편 전체를 형식 그대로 보내라. '
                '지적이 틀렸다고 보면 그 줄은 그대로 둬도 된다. 줄 수·화자 순서·expressions 유지. 지적:\n%s' % (i, f))
        if n >= per or not chat:
            rc, chat = gb.send('첨부한 rewrite_grok_hi.md 가 이 방의 규칙이다. ' + body, out, [gb.RULES, att], ''); n = 0
        else:
            rc, chat = gb.send(body, out, [att], chat)
        n += 1
        if rc != 0:
            shutil.copy(g0, out); os.remove(g0); print('실패', i, rc, flush=True); continue
        errs = gb.check(i)
        if errs:
            print('다시', i, errs, flush=True)
            gb.send('%s.txt 다시: %s' % (i, ', '.join(errs)), out, [], chat); n += 1
            errs = gb.check(i)
        print('끝', i, errs or 'OK', flush=True)


if __name__ == '__main__':
    main()
