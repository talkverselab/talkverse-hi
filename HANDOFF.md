# HANDOFF — talkverse-hi (힌디어유니버스) · 2026-11-03

## 상태

| 항목 | 상태 |
|---|---|
| Android | CI 빌드 9(`c5b76d8`) · Zealot https://apps.talkverse.uk/Bt9EU/204 · PC 백업 `D:\OneDrive\app project\talkverse-hi\` |
| iOS | TestFlight 빌드 `2611030039` 업로드 성공(번들 `com.talkverse.hindiUniverse`) · IPA 백업 `D:\OneDrive\app project\hindi_universe\ios\` |
| 서명 | `android/app/signing-key.jks` = 폰과 같은 키 SHA-1 `9C:C4:…:47:6B`. Doppler `SIGNKEY_*` + PC `D:\backup\signing_keys\talkverse-hi\` 에 백업. M6 `~/.android/debug.keystore` 는 **다른 키** — CLAUDE.md §1 의 `cp` 금지 |
| 캐릭터 | 2026-11-03 사용자 통과 — `data/review/art/chars_hi_v1.jpg`, 특징 `data/review/uxui/CHARACTERS.md`(프리야·아난야·로한·아르준·학습자 남/여) |
| UX/UI | 2026-11-03 사용자 통과 — 글 `data/review/uxui/sian_hi_01.md`, 그림 `sian_hi_01.jpg`(적용 전 태그 `pre-grok-uxui`) |
| 로그인·결제 | Talkverse ID(client_id `hi`, 딥링크 `talkverse.hi://auth`) + 평생 이용권(iOS `com.talkverse.hindiUniverse.lifetime` / Android `lang_hi`). **잠그는 콘텐츠 없음** |
| 회화 | 옛 초안 그대로(L1 5편×8턴, draft). 회화 작성은 사용자 지시 전까지 금지 |
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

## 사용자 결정 대기
1. **평생 이용권으로 무엇을 잠글지 + 가격** — "나중에"(2026-11-03). 그전에는 잠그지 않는다. 스토어 심사 전에 꼭 정해야 한다.
2. **개발자 포털 App ID `com.talkverse.hindiUniverse` 에 Sign in with Apple 켜기**(사용자 몫). 지금 IPA 에는 `applesignin` 이 없어 iOS 의 Apple 로그인만 동작하지 않는다. 켠 뒤 `bash tools/ios_release.sh` 로 다시 올린다.
3. 스토어 인앱 상품 등록(iOS `com.talkverse.hindiUniverse.lifetime`, Play `lang_hi`) — 사용자 몫.

## 다음 할 일
1. **단어 그림용 리스트 — 올림(2026-11-03, `talkverselab/talkversehanja` `bc6c949` "words/hi: 단어·음식 리스트")**
   - `talkverse_art/words/hi.csv`: 1,500단어, 열 `rank,word,reading,ko,en,pos,level,picturable`(그림 가능 Y 647 · N 853).
   - `hi_food.csv`: 인도 음식 50, rank 9001~9050.
   - **근거(사용자 지시, M6 전달)**: 원본 빈도표를 못 찾아 Opus 판단으로 만든 목록이다. 기준은 인도 자국 드라마·영화 대사의 구어이고, 더빙·외국 작품은 제외했다.
     - 1~150위: 구어 빈도 순으로 직접 정한 순위.
     - 151~1,500위: 하위 에이전트 4개가 붙인 구어 빈도 등급(1~5) 순으로 정렬(같은 등급 안은 처음 순서).
     - **실제로 센 빈도가 아니라 추정**이다. 그래서 덮는 비율은 측정하지 못했다.
   - **R 경계**는 사이트 절벽 페이지의 힌디어 값을 그대로 썼다.
     - R1 1~229 · R2 230~365 · R3 366~944 · R4 945~1,500(앱은 R3 까지만 쓴다).
     - 그 페이지의 덮는 비율(R1≈55%·R2≈60%·R3≈70%·R4≈80%)은 원래 2,500단어 말뭉치를 비례 매핑한 값이다. 이 목록으로 잰 값이 아니다.
   - 독음 표기:
     - 비음 ं 은 대부분 받침 ㅇ 이다. 일부 파트는 뒤 자음에 맞춰 ㅁ/ㄴ(बंद 반드, कंपनी 캄파니, सांभर 삼바르, संदेश 산데시)으로 적어 섞여 있다.
     - ड़→ㄹ(वड़ा 바라)은 표기표대로다.
     - 표기표 §3 에 비음 동화 규칙(ㅂ·ㅍ·ㅁ 앞 ㅁ, ㄷ·ㅌ·ㄴ·ㅅ 앞 ㄴ)을 넣고 검사기로 맞출 것.
   - 캐릭터 시트: `data/review/art/chars_hi_v1.jpg`.
   - **열린 문제**: talkverse.uk 세션이 자국 영화·드라마 대사 **말뭉치로 다시 세어** 레마 단위 절벽(55/60/70/80% 도달 순위)을 내 달라고 요청했다(2026-11-03). 그런 말뭉치는 이 세션에 없다 — 사용자 결정 대기. 말뭉치로 다시 세면 `hi.csv` 순위·level 도 그 값으로 바꾼다.
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
