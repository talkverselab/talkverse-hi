# 힌디어 회화 초안 규칙 (2026-11-07)

흐름: Claude 초안 → 검사기 → Grok 재작성 → **Gemini 검수**(사용자 지시) → 사용자 리뷰 → DB. 이 문서는 초안 단계다.
범위: 150편, R3 까지(`data/review/write/plan_hi.json` — 편 id·종류·`twist_type`·상대가 정해져 있다. 바꾸지 말 것).
함께 읽을 것: `~/talkverse/ja/docs/DIALOGUE_WORKFLOW_JA.md` §1(톤), `docs/DIALOGUE_NOTES.md`, `data/review/uxui/CHARACTERS.md`.

## 일상이 먼저(2026-11-09 사용자 지시 — 원칙 페이지 §9, https://talkverse.uk/talkverse/dialogue-rules/)
- 중심은 학습자가 실제로 겪는 일상(가게·식당·길·집·학교·직장·약속·전화)과 그 자리의 흔한 표현이다.
- 반전은 그 안에서 있을 법한 작은 의외성까지만: 말실수·착각·깜빡함·예상 밖 대답·설렘. 카오스도 「현실에서 있을 법한 꼬임」까지.
- 비현실적 사건·과장된 소동·판타지 금지. 반전 때문에 일상 표현이 빠지면 반전을 줄인다(카오스 비율보다 일상이 우선).

## 톤
- 학습자가 외우고 싶은 한 줄이 편마다 있어야 한다. 델리 젊은 사람이 지금 실제로 쓰는 구어(यार, अरे, चलो, बस, क्या बात है, पक्का, सच में, कोई बात नहीं, अच्छा जी, हाँ हाँ …)를 편마다 2개 이상 자연스럽게.
- 교과서체·번역투·설명 대사·다짐이나 감사로 끝내는 마무리 금지. 끝은 펀치라인이나 미지근한 반응.
- 킥(웃음·놀람)을 편마다 1회 이상. 연애·플러팅 편은 심쿵 한 줄(마음을 들키는 말, 말끝 흐리기, 여운)을 킥과 다른 턴에. 다른 주제에도 자주.
- `twist_type`: chaos = 일이 걷잡을 수 없이 커짐, slip = 말실수·오해, reveal = 의외의 사실, emotion = 심쿵·감정, ignore = 읽씹. 계획의 값을 따르고 `twist` 에 그 턴 번호.
- 연애는 썸·플러팅까지(iOS 12+, 성적 묘사 없음). 여성이 먼저 다가가는 편을 더 많이. 클리셰는 일부만.
- 소재가 편끼리 겹치지 않게. 인도 현실 소재를 쓴다(오토릭샤 흥정, 짜이, 메트로, 크리켓, 결혼식, 이모의 중매, UPI 결제, 정전, 몬순, 탈리 …). 실존 브랜드·작품·인물 금지, 자체 작문만. 콜백(앞 편 대사 되살리기)은 `tags` 에 `callback:<편id>`.

## 인물·말투
- A = 학습자, 국적·이름 고정 금지(`{name}`·`{country}`·`{city}` 만). 기본판은 **A 남성**.
- 낯선 사람·가게 = `आप`/`कीजिए`, 친구 = `तुम`, 아주 친하면 `तू` 도 조금. `ko` 도 같은 말투.
- 누크타(ज़·फ़·ड़)·찬드라빈두(हाँ) 표기. 문장 끝은 `।`.

## 길이
- 턴 수: R1 6~8 · R2 8~12 · R3 12~16. 턴은 1~2문장.
- 단어 수: R1 3~8 · R2 4~12 · R3 5~18. 채팅 편은 더 짧아도 된다.
- 어휘: R1 은 쉬운 고빈도 말 위주(`assets/data/freq/hi_words.csv` rank 500 안쪽 중심), R2 는 1,000 안쪽, R3 는 2,000 안쪽. 벗어나면 편당 1~2개, note 에 뜻.

## 성별
- 학습자 여성판에서 말이 달라지는 턴에는 `tl_f`(그 줄의 여성판 전문)와 `ko_f`(한국어가 달라질 때만)를 넣는다. A 자신의 말(रहा→रही, गया→गई, करूँगा→करूँगी)과, 상대가 A 에게 하는 말(चलोगे→चलोगी, थके हो→थकी हो)이 해당한다. 안 달라지면 넣지 않는다.
- `love` 편은 `"speakers_f":{"B":"अर्जुन"}` 을 넣는다: 학습자 여성판의 상대는 아르준이다. B 의 성별 어미도 `tl_f` 에서 함께 바꾼다(한 줄의 `tl_f` = 여성 학습자판에서 그 턴 전체).
- 성별 일치가 핵심인 턴은 `note` 끝에 (남성)/(여성).

## 감정(2026-11-07 사용자 지시 — 음성을 고려해 함께 쓴다)
- 턴마다 `emotion` 을 넣는다. 값: neutral polite stiff cheerful amused teasing excited surprised shout tsukkomi annoyed sad worried flustered shy gentle.
- 한 턴에서 감정이 바뀌면 `segs` = `[[감정, 본문], …]` 로 나눈다(이어 붙이면 `tl`). neutral 만 쓰지 말 것: 점원·안내는 polite, 받아치기는 tsukkomi, 심쿵 턴은 gentle·shy.
- 여성판이 다른 턴에서 감정이 나뉘면 `segs_f`. 음성 계획은 손으로 쓰지 않고 `tools/tts/make_plan.py` 로 만든다.
- 11-07 초안 150편 중 예시 3편 외에는 이 칸이 없다. Grok 재작성본을 넣을 때 함께 채운다.

## 출력 — `assets/data/dialogues/<R>/<island>/<id>.json`
```json
{"id":"r1_friends_a1","region":"R1","island":"friends","kind":"short","draft":true,
 "title":"한국어 제목","emoji":"☕","scene":"장면 한 줄(한국어)","where":"장소",
 "speakers":{"A":"{name}","B":"प्रिया"},"genders":{"B":"f"},"register":"casual",
 "twist":5,"twist_type":"chaos","flags":[],"purpose":["making_friends"],"domain":["friends"],
 "goal":"학습 목표(한국어)","expressions":["यार","पक्का"],
 "turns":[{"num":1,"speaker":"B","tl":"힌디어","rd":"","ko":"한국어","emotion":"cheerful","note":"X = 뜻","tags":["expr:यार"]}]}
```
- `register`: polite·casual·chat·mixed. 채팅 편 턴에는 `"ui":"bubble"`, `"at":"21:03"`, 이모지 `"stamp":"😂"` 1~2개, 읽씹은 `"read":false`.
- 단역이 필요하면 `speakers` 에 C·D 추가, `genders` 도.
- `rd` 는 비워 두고 `python3 tools/check_dialogues.py --fix-rd <파일…>` 로 채운다. 오류가 0 이 될 때까지 고친다. 변환이 틀린 턴만 손으로 고치고 `rd_manual: true`.
- 공개 저장소다. 자막·작품·출처 이름 금지.
