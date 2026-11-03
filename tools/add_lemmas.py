#!/usr/bin/env python3
"""회화 턴에 문장 내용어(레마) 넣기 — 일본어앱 tools/add_lemmas.py 의 힌디어판(2026-11-04).

턴마다 `lemmas: [[표면형, 기본형, 한글 읽기]]` 를 넣는다(명사·동사·형용사·부사만, 후치사·조동사·대명사 제외).
기본형은 누크타 제거·찬드라빈두→아누스바라로 정규화해 단어장(assets/data/freq/hi_words.csv) 표기와 맞춘다.
단어장에 없는 기본형은 빈도순으로 data/review/write/missing_lemmas.csv 에 쓴다(uk 세션이 단어·그림을 만든다).

사용(스크래치 venv 에 stanza 설치 후):
  <venv>/bin/python -I tools/add_lemmas.py <stanza 모델 폴더>
회화를 build_content.py 로 다시 만들면 이 스크립트도 다시 돌린다.
"""
import csv, collections, json, re, sys, unicodedata
from pathlib import Path
import stanza

ROOT = Path(__file__).resolve().parent.parent
DIALOGUES = sorted((ROOT / 'assets/data/dialogues').glob('L*.json'))
WORDS = ROOT / 'assets/data/freq/hi_words.csv'
MISSING = ROOT / 'data/review/write/missing_lemmas.csv'
CONTENT = {'NOUN', 'VERB', 'ADJ', 'ADV'}
NAMES = {'मिनजुन', 'प्रिया'}  # 고정 인물 이름 — 내용어 칩에서 뺀다
# 동사 활용 어미(긴 것부터) — 분석기가 기본형을 잘못 만들면(लूंगना 등) 어간 + ना 를 단어장에서 찾는다
ENDINGS = sorted(['ूंगा', 'ूंगी', 'ेंगे', 'ेंगी', 'ेगा', 'ेगी', 'ोगे', 'ोगी', 'ऊंगा', 'ऊंगी', 'ता', 'ती', 'ते', 'ा', 'ी', 'े', 'ो', 'ना', 'नी', 'ने', 'िए', 'िये', 'इए'], key=len, reverse=True)


def verb_base(surface, words):
    s = norm(surface)
    for e in ENDINGS:
        if s.endswith(e) and len(s) > len(e):
            cand = s[: -len(e)] + 'ना'
            if cand in words:
                return cand
    if s + 'ना' in words:
        return s + 'ना'
    # लूँगी → लेना, दूँगा → देना (어간 모음 ए 가 미래형에서 ऊ 로 바뀜)
    for e in ('ूंगा', 'ूंगी', 'ूं'):
        if s.endswith(e) and s[: -len(e)] + 'ेना' in words:
            return s[: -len(e)] + 'ेना'
    return None


def norm(s):
    s = unicodedata.normalize('NFD', unicodedata.normalize('NFC', s)).replace('़', '')
    return unicodedata.normalize('NFC', s).replace('ँ', 'ं')


def main():
    md = sys.argv[1]
    nlp = stanza.Pipeline('hi', processors='tokenize,pos,lemma', tokenize_no_ssplit=True, verbose=False, model_dir=md, use_gpu=False)
    words = {r['word']: r for r in csv.DictReader(open(WORDS, encoding='utf-8'))}
    miss = collections.Counter()
    for path in DIALOGUES:
        data = json.loads(path.read_text(encoding='utf-8'))
        for ep in data.get('episodes', []):
            for t in ep.get('turns', []):
                text = t.get('es', '').replace('{name}', '')
                text = re.sub(r'[।॥!?,.;:…"“”‘’()\-]', ' ', text)  # 문장 부호가 낱말에 붙어 기본형이 깨지지 않게
                out, seen = [], set()
                for s in nlp(text).sentences:
                    for w in s.words:
                        if w.upos not in CONTENT or norm(w.text) in NAMES:
                            continue
                        base = norm(w.lemma or w.text)
                        if base not in words:  # 분석기 기본형이 단어장에 없으면 동사 어간으로 다시 찾는다
                            base = verb_base(w.text, words) or (norm(w.text) if norm(w.text) in words else base)
                        # 진행형 「सीख रहा」처럼 뒤에 रह/सक/चुक 가 오면 앞말은 동사 어간
                        nxt = s.words[w.id] if w.id < len(s.words) else None
                        if nxt is not None and norm(nxt.text)[:2] in ('रह', 'सक', 'चु') and norm(w.text) + 'ना' in words:
                            base = norm(w.text) + 'ना'
                        if base in seen:
                            continue
                        seen.add(base)
                        hit = words.get(base)
                        out.append([w.text, base, hit['reading'] if hit else ''])
                        if not hit:
                            miss[base] += 1
                t['lemmas'] = out
        path.write_text(json.dumps(data, ensure_ascii=False, indent=1) + '\n', encoding='utf-8')
    MISSING.parent.mkdir(parents=True, exist_ok=True)
    with open(MISSING, 'w', encoding='utf-8', newline='') as f:
        wr = csv.writer(f)
        wr.writerow(['lemma', 'count'])
        wr.writerows(miss.most_common())
    print('missing', len(miss))


if __name__ == '__main__':
    main()
