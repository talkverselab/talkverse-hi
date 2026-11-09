# HANDOFF — talkverse-hi (힌디어유니버스) · 2026-11-09

## 다음에 할 일 (2026-11-09 세션 종료)

현재: 안드로이드 빌드 15(`aa51e0a`, Zealot https://apps.talkverse.uk/Bt9EU/423)과 iOS TestFlight 2611091212 가 같은 내용. 작업 트리의 수정 표시는 빌드 도구 잡음뿐(아래 「주의」).

11-09 한 일(uk 전달 사용자 지시):
- 가격 확정 `5a07353`(uk 작성) 푸시 — 상품 lang_hi_1m·3m·1y·life·all_1y·all_life, 결제 시트 정가 취소선.
- 통합 앱 연결점 `aa51e0a`(EMBED_GUIDE 8단계): `lib/embed.dart`(embedInit·embedApp), `core/embed_env.dart`(storePrefix `hi_`, assetPath, dataDir), `core/prefs.dart`(설정 키 접두, 단독 앱은 옛 키 한 번 이동), DB `hi_hindi_universe`(옛 `hindi_universe` 한 번 이동), 통합 앱이면 clientId `talkverse`·로그아웃은 tv_ 키만·결제 스트림은 공용(`Purchase.ownStream`·`onPurchaseUpdates`), 프로필에 「다른 언어 배우기」. 통합 앱 연결은 uk 가 한다(패키지 `hindi_universe`, 콜백 `talkverse.hi://auth`).
- 스토어 차별화 `docs/STORE_PRODUCTS.md`(설명 첫 줄·전용 도구·실측 숫자·심사 메모·스크린샷 순서). 출시 전 채울 것도 거기 적음.
- ⚠ 통합 앱 연결 코드는 위젯 테스트 15개·analyze 통과, **아이패드 스크린샷은 메모리 부족으로 중단되어 다시 못 돌렸다** — 다음 세션 첫 일: `python3 tools/pane_shots.py <UDID> <폴더>` 로 14장 확인(폰에서 업데이트 뒤 기존 학습 기록이 남는지도).

1. **사용자 답 대기 — 굴절어 전략(`~/talkverse/INFLECTED_LANG_STRATEGY.md`) 4개 항목**(11-08 알림):
   - A4 존댓말: 힌디어는 낯선 사이에 आप 가 기본 → R1 에 통문장으로 두는 ②안 제안.
   - B15 레벨별 한 편: 사용자 지시로 이미 150편 → 유지 제안.
   - A1 레벨 = 문법 단계: 지금 R(빈도 절벽) 유지 + 문법 단계는 태그 제안.
   - A11 단어 상한: 2,000(94.6%) 유지 제안.
   - 답을 받으면 `docs/DIALOGUE_RULES_hi.md` 에 결정과 A-빈칸 표를 적는다.
2. **음성 생성은 새벽 01:00~07:00 KST 에만**(2026-11-09 사용자 지시, 전역 CLAUDE.md). **음성 시험 3편 사용자 청취 대기**(리뷰 페이지 맨 위, https://talkverse.uk/talkverse/review/hi/). 150편 전체는 Grok·Gemini 뒤에, PC 는 uk 의 "지금 시작" 뒤에만. 그 전에 `tools/tts/qa.py` 에 숫자 표기 맞춤(दो सौ ↔ 200)을 넣는다.
3. **Grok 회화 재작성**: 11월 9일 13:30 재개(uk 공지), 사용자 지시 뒤 시작. 편 1개씩 「전문가」·모든 줄 새로 쓰기, 그다음 **Gemini 검수**(사용자 지시 — 힌디어 필요). 재작성본을 넣을 때 턴마다 `emotion`(+`segs`)을 채우고 `tools/tts/make_plan.py` 로 음성 계획을 만든다. 자신 없는 표현 목록 `data/review/write/draft_doubts_hi.md`.
   - **Grok 쓰는 법 바뀜(2026-11-09 공지 `~/logs/rc/RELAY_grok_20261109.md`)**: 한자 세션은 더 이상 대행하지 않는다. 자기 크롬을 켜고 M4 에서 `ssh macmini4 /usr/bin/python3 ~/talkverse-uk/tools/grok_cookie_sync.py 9231 <자기 포트>` 로 쿠키를 맞춘 뒤 직접 보낸다. 도구는 M6 `~/Hanja/tools/grok_req.py`·`grok_cdp.py` 를 이 저장소로 복사. uk 의 방(9231)은 건드리지 않는다.
   - **Grok 은 PC 에서(2026-11-09 사용자 지시 "소수언어들에게 pc에서 그록 켜서 집필 그림 작업 하라고 해", uk 전달)** — 위의 M6/M4 크롬 방식 대신: PC(`ssh Administrator@100.127.143.37`)에서 크롬을 `--remote-debugging-port` 로 띄움(작업 스케줄러로 — SSH 직접 실행은 세션과 함께 죽음) → M4 에서 `ssh -N -L <M4포트>:127.0.0.1:<PC포트> Administrator@100.127.143.37` → M4 `/usr/bin/python3 ~/talkverse-uk/tools/grok_cookie_sync.py 9231 <M4포트>`(uk 9231 과 같은 계정, 값은 안 남음). 쓰는 포트는 `~/talkverse-uk/docs/GROK_CHROME_PORTS.md` 에 적는다. 한도는 공유 — 회차를 작게.
   - **Grok 프롬프트 최소화(2026-11-09 사용자 지시, uk 전달)**: 규칙은 저장소 문서에 한 번만 쓴다. 방 첫 메시지에서 「앞으로 파일 이름 한 줄만 보낸다」고 약속하고, 이후 채팅은 한 줄만 보낸다. 그림이 처음과 달라지면 최초로 통과한 그림을 기준으로 한다(이미 만든 그림은 그대로).
   - 감정 열은 이미 규칙에 들어가 있다(`tools/prompts/dialogue_hi.md` §감정 — 턴마다 `emotion`, 바뀌면 `segs`).
   - **일상 안에서 점검(2026-11-09 사용자 지시, 「반전을 줄이라」는 취소됨)**: 반전·러브·플러팅은 비율 그대로 두고, 초안 150편 중 일상과 동떨어진 비현실적 설정만 실제 일상 장면·표현 흐름 안으로 옮긴다. Grok 재작성 전에. 규칙 `tools/prompts/dialogue_hi.md` §일상 안에서 터지게.
4. 리뷰 통과 뒤: `DialogueService` 를 R 구조로, pubspec 에 R 폴더, `tools/add_lemmas.py` 를 `tl` 칸에 맞춤.
5. 사용자 몫(그대로): 유료 범위·가격, App ID 의 Sign in with Apple, 스토어 인앱 상품 등록. 조음 그림은 출시 전에 Grok 그림으로 교체.


## 2026-11-07 회화 초안 150편

- 사용자 지시로 회화 작성 제한 해제. **힌디어 흐름 = Claude 초안 → Grok 재작성 → Gemini 검수 → 사용자 리뷰 → DB**(Gemini 는 사용자가 힌디어에도 필요하다고 지시, uk 전달보다 우선).
- 초안 끝: `assets/data/dialogues/R1|R2|R3/<주제>/<편id>.json` 150편·1,509턴(R1 83·R2 42·R3 25, 카오스 50편 33%), 검사기 오류 0. 계획 `data/review/write/plan_hi.json`, 규칙 `tools/prompts/dialogue_hi.md`, 검사 `tools/check_dialogues.py --fix-rd`, 독음 `tools/rd_hi.py`, 자신 없는 표현 `data/review/write/draft_doubts_hi.md`.
- 앱은 아직 `L1.json` 만 읽는다(pubspec 은 `assets/data/dialogues/` 바로 아래만 묶는다). 리뷰 통과 뒤 `DialogueService` 를 R 구조로 바꾸고 pubspec 에 폴더를 넣고 `tools/add_lemmas.py` 를 새 칸(`tl`)에 맞춘다.
- 여성 학습자판은 턴의 `tl_f`·`rd_f`·`ko_f`(255턴), 사랑 편의 여성판 상대는 `speakers_f`(아르준). 다음은 Grok(11-10 까지 주간 한도)·음성(uk 순서)·리뷰 페이지.

## 2026-11-08 데바나가리와 발음 · 수정 2건

- 홈 「기초」 첫 줄 「데바나가리와 발음」(`lib/screens/devanagari_chart_screen.dart`, `lib/widgets/devanagari_sound_sheet.dart`, 데이터 `lib/services/devanagari_phonetics.dart`): 묶음 칩 9개 · 자음은 무기/유기/유성/유성 유기/비음 칸 · 로마자 토글 · 글자 탭 = 1초 뒤 자동 재생·IPA·소리나는 곳·내는 방식·한국어 비교.
- 조음 위치·모음 그림(`assets/images/ipa/`, 일본어앱에서 복사)은 **임시** — 출처 표기 없음, 출시 전에 Grok 그림으로 바꾼다(사용자 지시).
- 고침: 절벽 단어 타일이 데바나가리 높이에 넘치던 것(타일 높이 고정·칸 수는 실제 칸 너비), 레일 「앱 소개」가 오른쪽 칸이 아니라 전체 화면으로 열리던 것. 아이패드 스크린샷 14장 넘침 0.

## 음성 시험(2026-11-08)

- 예시 3편(`r1_survival_s1`·`r1_friends_a1`·`r1_love_a1`)을 MOSS 로 생성해 R2 에 올렸다. D1 에는 넣지 않았다(사용자가 듣고 판단한 뒤). 도구 `tools/tts/`(터키어앱판 이식), 작업 폴더 `~/tts_work/hi`, 말 속도 기준 10.5 글자/초, whisper 는 `~/tts_work/it/venv`.
- 받아쓰기 44조각 중 31 합격, 13 미달. 미달 대부분은 숫자 표기(दो सौ → 200)·철자 차이라 측정 쪽이고, 실제로 들어 볼 것은 `r1_love_a1` 턴2 चाय(चाहिए 로 들림), af 음량이 낮은 조각(-20dB)이다. 전편 전에 `qa.py` 에 숫자 표기 맞춤을 넣을 것.
- 감정 계획은 `tools/tts/make_plan.py`(회화의 `emotion`·`segs`). 나머지 147편은 Grok 재작성 때 감정 칸을 채운다.

## 2026-11-07 단어·메뉴 개편(일본어앱 `docs/MENU_WORDS_2026-11-07.md` §1·3~6, §2 는 해당 없음)

- 앱을 고치면 Zealot·TestFlight 를 항상 함께 올린다(사용자 지시).
- **iOS 는 이 개편분이 아직 안 올라갔다.** Xcode 27.2 와 CoreSimulator 불일치로 허브가 iOS 작업을 멈춰 둠(`~/logs/rc/RELAY_xcode_20261107.md`). CoreSimulator 1174.21 이상이 되면 `bash tools/ios_release.sh`. 시뮬레이터 화면 확인(`integration_test`, 12장)도 그때 — 지금은 `test/menu_words_test.dart`(기기 없는 위젯 시험)만 통과.
- 단어장: 2,000위까지 확장(1,909행 = 2,000위 안 1,902 + 회화 단어 7, DB 번호 5). 말뭉치를 다시 세어 경계·기존 순위가 그대로임을 확인(R1 28·R2 39·R3 84·R4 226, 2,000위 누적 94.6%). 1,566~2,000위의 뜻·독음은 이 세션이 쓴 초안이고 `picturable` 은 전부 N — 검수 전. 그림 저장소 `hi.csv` 는 그대로(1,511).
- 「앱 업데이트」 타일 제거 → 폰 업데이트는 Zealot 으로. CLAUDE.md §2 의 앱 안 업데이트 설명은 아직 옛 내용이고, `update_screen.dart` 코드는 남아 있다.
- 일본어앱의 「학습 기록 초기화」·프로필 안 성과 칸은 힌디어앱에 없던 것이라 넣지 않았다(성과는 「진행」 탭). 단어 검색칸은 일본어앱과 같이 없앴다.

## 상태

| 항목 | 상태 |
|---|---|
| Android | CI 빌드 15(`aa51e0a`) · Zealot https://apps.talkverse.uk/Bt9EU/423 · PC 백업 `D:\OneDrive\app project\talkverse-hi\` |
| iOS | TestFlight 빌드 `2611091212`(`aa51e0a`, Android 15 와 같은 내용) 업로드 성공(번들 `com.talkverse.hindiUniverse`) · IPA 백업 `D:\OneDrive\app project\hindi_universe\ios\` |
| 서명 | `android/app/signing-key.jks` = 폰과 같은 키 SHA-1 `9C:C4:…:47:6B`. Doppler `SIGNKEY_*` + PC `D:\backup\signing_keys\talkverse-hi\` 에 백업. M6 `~/.android/debug.keystore` 는 **다른 키** — CLAUDE.md §1 의 `cp` 금지 |
| 캐릭터 | 2026-11-03 사용자 통과 — `data/review/art/chars_hi_v1.jpg`, 특징 `data/review/uxui/CHARACTERS.md`(프리야·아난야·로한·아르준·학습자 남/여) |
| UX/UI | 2026-11-03 사용자 통과 — 글 `data/review/uxui/sian_hi_01.md`, 그림 `sian_hi_01.jpg`(적용 전 태그 `pre-grok-uxui`) |
| 로그인·결제 | Talkverse ID(client_id `hi`, 딥링크 `talkverse.hi://auth`) + 평생 이용권(iOS `com.talkverse.hindiUniverse.lifetime` / Android `lang_hi`). **잠그는 콘텐츠 없음** |
| 회화 | 앱은 옛 초안(L1 5편×8턴). 새 초안 150편은 저장소에 있고 앱에는 아직 안 들어감(아래 참조) |
| Supabase | 사용 없음(`docs/CLOUDFLARE_MIGRATION.md`) |
| 저작권 | 교재 이름·변환 스크립트를 파일·이력에서 삭제(2026-11-02 filter-repo + 강제 push) |

## 이번에 만든 것(2026-11-02~03)
- 아이패드 두 화면(레일 + 왼쪽 칸 | 오른쪽 칸) + 만화책 읽기형 회화 리더 + 그림 카드 + 성과 데스크 + 학습자 이름·성별. 프랑스어앱 `95f181a` 를 따라 옮겼다.
- UX 시안 01:
  - 회화 리더에서 낱말을 누르면 **글자 풀이**(`lib/services/devanagari.dart` — 유니코드 분해 + 독음 표기표).
  - **말투 꼬리표**(존댓말 आप / 반말 तुम / 아주 가까움 तू, 남성형·여성형).
  - **홈 메뉴 3묶음**.
- 스크린샷 흐름: `python3 tools/pane_shots.py <UDID> <스크래치> integration_test/dialogue_pane_test.dart`.
  - 이 앱 전용 시뮬레이터는 `hi-shots iPad Air 11`(`D1313F9E-…`)이고, 끝나면 shutdown.
  - 2026-11-03 실행 결과 10장, 넘침 0.
- 회화 원칙의 힌디어 특이점: `docs/DIALOGUE_NOTES.md`(변이·성별판·독음 표기표·턴 길이 — 초안).

## 2026-11-04 일본어앱 9962316 변경 옮김(`6992414`·`9bd96b9`, Zealot 빌드 11 https://apps.talkverse.uk/Bt9EU/254)
- 회화 그림 위 말풍선을 없앴다. 「오늘의 컷」은 그림 아래 띠로, 재생 화면은 아래 문장 칸으로 대사를 보인다.
- 그림 카드 앞면에 한국어 뜻을 크게 보인다.
- **문장 레마 칩**:
  - `tools/add_lemmas.py` 가 턴마다 `lemmas` 를 넣는다(스크래치 venv 의 stanza 힌디어 모델).
  - 회화를 `build_content.py` 로 다시 만들면 이 스크립트도 다시 돌린다.
  - 단어장에 없는 레마는 `data/review/write/missing_lemmas.csv` 에 모아 uk 세션에 넘긴다.
- **단어장** `assets/data/freq/hi_words.csv`:
  - 1,511개 = 절벽 1,500 + uk 가 추가한 11개(3001~3011). DB `words` 에 들어가 「빈도 단어」 메뉴에도 보인다.
  - 칸 대응: region = 구간, cefr = 한글 독음.
- **DB 업데이트 번호** `assets/data/version.json`(지금 db=4):
  - 단어장을 바꾸면 이 번호만 올린다.
  - 회화 턴은 학습 기록 보존을 위해 처음 한 번만 넣는다.
- 그림 기기 내려받기(`lib/services/content_sync.dart`·`lib/screens/sync_screen.dart`)와 `artProvider` 를 붙였다.
- 장면 컷 조회(`ArtService.sceneCut`)는 학습자가 여자면 `<편id>_f` 컷을 먼저 찾는다.
- `{name}` 대사가 있는 회화를 열 때 이름이 비어 있으면 이름·성별 창을 띄운다. 지금 회화는 민준 고정이라 해당 없음.
- **보류**: 조연 캐릭터 시트(Grok 대기 지시).

## 사용자 결정 대기
1. **평생 이용권으로 무엇을 잠글지 + 가격** — "나중에"(2026-11-03). 그전에는 잠그지 않는다. 스토어 심사 전에 꼭 정해야 한다.
2. **개발자 포털 App ID `com.talkverse.hindiUniverse` 에 Sign in with Apple 켜기**(사용자 몫). 지금 IPA 에는 `applesignin` 이 없어 iOS 의 Apple 로그인만 동작하지 않는다. 켠 뒤 `bash tools/ios_release.sh` 로 다시 올린다.
3. 스토어 인앱 상품 등록(iOS `com.talkverse.hindiUniverse.lifetime`, Play `lang_hi`) — 사용자 몫.

## 다음 할 일
1. **절벽 구간·단어 그림 리스트 — 말뭉치로 재산정해 올림(2026-11-03, `talkverselab/talkversehanja` 최종 `4cf3f29` "words/hi: 단어·음식 리스트")**
   - **말뭉치**: PC `D:\datasets` 의 공개 영화·드라마 자막(힌디어).
     - 공개 저장소·사이트에는 말뭉치 이름을 쓰지 않는다.
   - **자국 원작만 고르려던 시도**: 작품 번호를 공개 영화 정보의 「원어 = 힌디어」 목록과 대조했다.
     - 92편이 나왔지만 88편은 모음 부호·띄어쓰기가 빠진 **깨진 글자**였다(예: आ गयन ज़ंदवपस).
     - 깨끗한 것은 4편(약 5만 토큰)뿐이라 쓸 수 없었다.
   - **사용자 결정(2026-11-03)**: 깨끗한 자막 전부로 센다.
     - 대상: 80편(자국 원작 4 · 인도 타 언어 원작 8 · 외국 작품 번역 68), 약 62만 토큰. 번역체가 섞인 빈도다.
     - 깨끗함의 기준: 일반 힌디어 낱말 비율 85% 이상.
   - **처리**:
     - 누크타 제거·찬드라빈두 → 아누스바라로 정규화한 뒤 형태소 분석기로 **레마 단위**로 셌다(verb = -ना 형). 레마 13,342개.
     - 고유명사로 태깅된 것 중 일반어가 아닌 인물·지명은 뺐다.
     - 분석기가 만든 가짜 레마(हैंना·चलोना 등)·이름 57개는 목록에서 뺐다. 순위는 말뭉치 순위 그대로라 빈칸이 있다. 1,500을 채우려고 1,503~1,566위를 더했다.
   - **R 경계 — 일본어 방식 새 산정(2026-11-03 사용자 지시, `4cf3f29`)**: R1 1~28(55%) · R2 29~39(60%) · R3 40~84(70%) · R4 85~226(80%, 참고).
     - 1,500개 93.2% · 2,500개 95.7%, 650,841 토큰. 227위부터는 level `R5`.
     - 세는 방식:
       - 후치사(ने·को·से·में·का)를 각각 한 토큰으로 센다. 대명사 융합형도 나눈다(मुझे=मैं+को, मेरा=मैं+का, तुमने=तुम+ने 등 31,638개).
       - 조동사(है·था·रहा)도 각각 한 토큰, 동사는 기본형.
     - 직전 레마 값(32·44·97)·사이트 옛 값(R1 229)은 폐기했다.
     - 앱 회화 어휘 상한은 R3(84위)까지다. 조사·조동사가 앞을 차지해 R3 가 좁다.
   - `hi.csv` 1,500행(그림 가능 Y 616), `hi_food.csv` 50행(9001~9050).
     - 앞서 올린 Opus 추정 목록(bc6c949)은 이것으로 대체했다.
   - 처리 스크립트·중간 파일은 세션 스크래치에만 있다(맥에 백업 두지 않음). 다시 하려면 이 절의 순서를 따른다.
   - 캐릭터 시트: `data/review/art/chars_hi_v1.jpg`.
2. 단어 그림·장면 컷이 들어오면 앱이 자동으로 보인다(`/art/hi`, 지금 0장). 회화 작업이 풀리면 `LANG_APP_REPLICATE_PROMPT.md` §12 순서를 따른다(R 구간 재구성 → Grok 재작성 → Gemini 검수 몇 편 시험 → 리뷰 → 장면 컷).
3. 템플릿 잔재 정리(남은 것):
   - 대상어 칸 이름 `es`
   - `dialogues/_meta.json`(콘텐츠 대기 0턴으로 낡음)
   - `freq/lang_es_top.csv` 파일명
   - `CLAUDE_UPDATES.md` 내용(2026-09 기준)
4. 공용 키트 동기화: `lib/core/l10n_dict.dart` 에 새 문구(계정·이용권·글자 풀이)를 넣었다. 키트 원본 `_update_kit/l10n/l10n_dict.dart` 에는 아직 없다.

## 주의
- 작업 트리의 수정 표시 수십 개는 CRLF 줄 끝·빌드 도구 잡음(`analysis_options.yaml`, `android/gradle.properties`, `ios/Flutter/*.xcconfig`, xcscheme, xcworkspace, linux/macos/windows 생성 파일, `ios/Podfile*`, `swiftpm/`)이다.
  - 커밋은 바꾼 파일만 경로 지정. `git add -A` 금지.
- `.md`·`tools/**`·`ios/**` 만 바뀐 푸시는 Android 빌드를 안 돌린다. 앱 코드 푸시는 CI 빌드 + 폰 업데이트 알림을 일으킨다.
- Zealot 앱이름 `힌디어유니버스` 는 고정이다. Zealot 에는 CI 가 만든 APK 를 올린다(CLAUDE.md §8).
- 아이콘은 talkverse.uk 세션 담당 — 직접 고치지 않는다.
- M6 과부하 공지가 오면 빌드·시뮬레이터를 즉시 멈춘다.
- **Grok·Gemini 를 직접 쓸 때(2026-11-03 공지)**:
  - 로그인 원본은 M4 `~/chrome-grok`. 쿠키 복사는 M4 안에서 `~/chrome-grok-hi/` 로 한다.
  - 자기 포트로 띄우고, M6 에서는 `ssh -fN -L` 로 터널을 연다. 첨부는 M4 `/tmp/grok_att/hi/` 에 둔다.
  - 상세는 `/Users/talkverse/talkverse/GROK_M4_LOGIN.md`, 구현 예는 `~/talkverse/ko/tools/grok_base.py`.
  - 사용자 지시 없이 미리 켜지 않는다. 한 번에 한 작업만 하고, 연 탭과 Chrome 은 끝나면 닫는다.
- **회화를 쓰게 되면(공통 원칙 §9)**:
  - 반전 비율: 카오스 30% 이상. 연애·플러팅 편마다 심쿵 한 줄, 여성 주도 편을 더 많이.
  - 편마다 `twist_type`(chaos·slip·reveal·emotion·ignore)을 단다. 새 편은 왕초보·초급 위주.
  - 그림은 A·B 쌍 1컷, 말풍선·글자 없이. 인물 기준 그림을 첨부한다.
- **소수언어 앱 범위(2026-11-03 사용자 지시, talkverse.uk 전달)** — 힌디어 포함. 회화를 쓰게 되면 이 범위로 한다.
  - 회화는 **150편**, 레벨은 **R3 까지만**(R4 는 만들지 않는다). 절벽 기준 약 1,500단어 규모.
  - 검수에 **Gemini 단계를 넣는다**(Grok 재작성 뒤).
  - 반전 비율은 150편 기준이다: 카오스 45편 이상.
  - 단어 그림 리스트(다음 할 일 1)도 R3(≤944 순위)까지로 줄일지 talkverse.uk 세션에 확인한다.
- **Grok 은 사용자 지시가 있을 때만(2026-11-03 공지)**. M4 Grok 은 새 계정이다(원본 `~/chrome-grok`, 포트 9222). 새 계정에는 프로젝트·챗·GitHub 커넥터가 없다. 예전 계정은 11/9 까지 한도. 시작할 때는 다음 순서를 따른다.
  1. M4 안에서 `~/chrome-grok` 쿠키를 다시 복사한다.
  2. 샘플 1~2개로 먼저 시험한다.
  3. PushNotification 으로 사용자 통과를 받는다.
  4. 통과 뒤 본작업을 한다.
- **Grok 요청문 작성법(2026-11-03 중국어앱 공유)**: `/Users/talkverse/talkverse/GROK_PROMPT_GUIDE.md`. 틀 파일은 `~/talkverse/zh/tools/`(`prompts/rewrite_grok.md`·`rewrite_request.py`·`scene_prompts.py`·`grok_*.py`)를 복사해 언어 코드만 바꾼다.
  - 전문가 모델을 쓰고, 편마다 새 대화방을 연다.
  - 재작성 요청에는 「판정 말고 재작성 · 모든 줄 새로」를 넣는다.
  - 받은 재작성은 그대로 쓰지 말고 리뷰한다.
  - 장면 컷은 한 요청에 컷 하나. 캐릭터 시트·시안을 첨부하고 접촉 시트로 리뷰한다.
