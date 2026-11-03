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
1. **절벽 구간·단어 그림 리스트 — 말뭉치로 재산정해 올림(2026-11-03, `talkverselab/talkversehanja` `ebf3b7d` "words/hi: 단어·음식 리스트")**
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
   - **R 경계(누적 덮는 비율)**: R1 1~32(55%) · R2 33~44(60%) · R3 45~97(70%) · R4 98~255(80%).
     - 1,500 레마 92.8% · 2,500 레마 95.4%. 256위부터는 level `R5`.
     - 앱 회화 어휘 상한은 R3(97위)까지다. 미얀마어처럼 조사·조동사가 앞을 차지해 R3 가 좁다.
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
