# -*- coding: utf-8 -*-
"""grok_batch 검사에서 걸린 편을 새 방에서 다시 쓰게 한다(2026-11-18).
  GROK_CDP_PORT=9246 python3 tools/grok_fix.py id,id,...  [--per-room 4]
- 긴 방에서 빠른 모드가 대사를 초안 그대로 두는 일이 많아, 방을 짧게 쓰고 그대로 둔 줄 번호를 짚어 준다.
- 앞 답은 out/<id>.prev.md 로 남긴다. 문장은 Claude 가 고치지 않는다 — 다시 쓰는 것은 Grok.
"""
import json, os, re, shutil, subprocess, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import grok_batch as gb

def same_nums(i):
    a, b = gb.turns(os.path.join(gb.SRC, i + '.txt')), gb.turns(os.path.join(gb.OUT, i + '.md'))
    src = {t[1].strip() for t in a if len(t) > 1}
    return [n + 1 for n, t in enumerate(b) if len(t) > 1 and t[1].strip() in src]

def main():
    a = sys.argv[1:]
    per = int(a[a.index('--per-room') + 1]) if '--per-room' in a else 4
    ids = a[0].split(',')
    chat, n = '', per
    for i in ids:
        out = os.path.join(gb.OUT, i + '.md')
        att = os.path.join(gb.TMP, i + '.txt')
        shutil.copy(os.path.join(gb.SRC, i + '.txt'), att)
        errs = gb.check(i) if os.path.exists(out) else ['답 없음']
        if not errs:
            print('끝', i, 'OK(이미)', flush=True); continue
        if os.path.exists(out):
            shutil.copy(out, os.path.join(gb.OUT, i + '.prev.md'))
        nums = same_nums(i) if os.path.exists(out) else []
        for attempt in range(2):
            why = ', '.join(errs)
            if nums:
                why += ' — 초안 문장을 그대로 둔 줄 %d개(%s번). 규칙 1: 모든 대사 줄을 초안과 다른 새 문장으로 써라' % (len(nums), ','.join(map(str, nums)))
            body = '%s.txt — 초안이다. 전체를 새로 써서 형식 그대로 보내라. (%s)' % (i, why)
            if n >= per or not chat:
                msg = '첨부한 rewrite_grok_hi.md 가 이 방의 규칙이다. 앞으로는 파일 이름 한 줄만 보낸다. ' + body
                rc, chat = gb.send(msg, out, [gb.RULES, att], ''); n = 0
            else:
                rc, chat = gb.send(body, out, [att], chat)
            n += 1
            if rc != 0 or not os.path.exists(out):
                print('실패', i, rc, flush=True); break
            errs = gb.check(i)
            if not errs:
                break
            nums = same_nums(i)
        print('끝', i, errs or 'OK', flush=True)

if __name__ == '__main__':
    main()
