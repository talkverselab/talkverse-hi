#!/usr/bin/env python3
"""언어감각 외울 대화(Grok 답 data/review/grok/sense_out/<급>.md)를 Gemini 검수 프롬프트로 만든다(2026-11-22).
  python3 tools/gemini_sense_hi.py   → data/review/gemini/sense/<급>.prompt.md + 목록 data/review/gemini/sense/list.tsv
  /usr/bin/python3 tools/gemini_batch.py data/review/gemini/sense/list.tsv   → data/review/gemini/sense/<급>.md
지적만 받는다(고쳐 쓰기는 Grok 몫)."""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
import sense_course_hi as S  # noqa: E402

OUT = ROOT / 'data/review/gemini/sense'
HEAD = ("[sense-{lid}] 아래는 한국인 학습자가 통째로 외울 짧은 힌디어 대화입니다(델리 젊은 층 일상 구어 기준, 학습자 「나」는 남자). "
        "이 급에서 익힐 문법: {title} — {target}. 각 줄은 「줄번호 화자: 힌디어 / 한국어 번역」입니다.\n"
        "당신은 힌디어 원어민 검수자입니다. **문장을 고쳐 쓰지 말고 지적만** 해 주세요. 항목마다 개수를 먼저 쓰고, 해당 줄 번호와 이유를 짧게:\n"
        "① 문법 오류(성·수 일치, 후치사와 사격형, ने 구문, 동사 활용) — 개수·줄·틀린 부분→맞는 형태.\n"
        "② 델리 사람이 실제로 이렇게 말하지 않는 줄(교과서체·번역투·어색한 표현·철자) — 개수·줄·이유.\n"
        "③ 존대(आप/तुम/तू)·호칭이 인물 관계에 맞지 않는 줄 — 개수·줄·이유.\n"
        "④ 한국어 번역이 뜻·어감과 어긋나는 줄 — 개수·줄·이유.\n"
        "⑤ 이 급의 문법이 잘못된 예로 쓰였거나 학습자가 오해할 줄 — 개수·줄·이유.\n"
        "없으면 \"0개\". 답은 한국어로, 간결하게.\n\n")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    rows = []
    for lid, title, sub, lines, foot, points in S.LEVELS:
        g = S.grok_lines(lid, len(lines))
        if not g:
            print('Grok 답 없음/어긋남 — 건너뜀', lid)
            continue
        body = '\n'.join(f"{i} {x['who']}: {S.plain(x['tl'])} / {S.plain(x['ko'])}" for i, x in enumerate(g, 1))
        p = OUT / f'{lid}.prompt.md'
        p.write_text(HEAD.format(lid=lid, title=title, target=' / '.join(foot)) + body + '\n', encoding='utf-8')
        if not (OUT / f'{lid}.md').exists():
            rows.append(f'{p.relative_to(ROOT)}\t{(OUT / (lid + ".md")).relative_to(ROOT)}')
    (OUT / 'list.tsv').write_text('\n'.join(rows) + ('\n' if rows else ''), encoding='utf-8')
    print(f'프롬프트 {len(rows)}건 → {(OUT / "list.tsv").relative_to(ROOT)}')


if __name__ == '__main__':
    main()
