# 스토어 상품·차별화 — 힌디어유니버스 (2026-11-09)

출시는 **Talkverse 통합 앱 하나**(com.talkverse.app)로 한다(uk 공지). 이 앱은 통합 앱 안의 힌디어 패키지(`hindi_universe`)이자, 개발·시험용 단독 앱(Zealot·TestFlight)이다. 가격 = `~/talkverse/PRICING.md`(사용자 확정 2026-11-09)의 앱 정가 / 앱 할인가. **상품 등록은 사용자가** App Store Connect·Google Play Console 에서 한다.

## 1. 상품

| 상품 ID | 이름(한국어 표시) | 종류 | 기간 | 앱 정가 | 스토어 판매가(할인가) |
|---|---|---|---|---|---|
| `lang_hi_1m` | 힌디어 1개월 | 자동 갱신 구독 | 1개월 | 5,500 | **3,900** |
| `lang_hi_3m` | 힌디어 3개월 | 자동 갱신 구독 | 3개월 | 12,900 | **9,000** |
| `lang_hi_1y` | 힌디어 1년 | 자동 갱신 구독 | 1년 | 28,500 | **19,900** |
| `lang_hi_life` | 힌디어 평생 이용권(서비스 운영 기간 동안) | 비소모성 | — | 69,900 | **49,000** |
| `all_1y` | 종합 패키지 1년 — 모든 언어 | 자동 갱신 구독 | 1년 | 112,900 | **79,000** |
| `all_life` | 종합 패키지 평생 — 모든 언어(서비스 운영 기간 동안) | 비소모성 | — | 469,000 | **329,000** |

- 앱 결제 시트는 정가를 취소선으로, 스토어 가격을 크게 보인다(`lib/embed.dart` 의 `Purchase.configure`, `lib/screens/paywall_screen.dart`). 앱 안에서 사이트 가격을 안내·유도하지 않는다.
- 옛 평생 상품 `com.talkverse.hindiUniverse.lifetime`·`lang_hi` 는 판매 중지, 복원 때 `lang_hi_life` 로 인정한다(`lib/data/purchase.dart` `_legacy`).
- 약관 https://talkverse.uk/terms/ · 개인정보처리방침 https://talkverse.uk/talkverse/hi/privacy/
- 통합 앱에서는 공용 결제가 스토어 스트림을 듣고 이 언어 상품을 `Purchase.onPurchaseUpdates` 로 넘긴다(EMBED_GUIDE 5단계). `all_*` 의 등록·인정 방식은 uk 가 정한다.
- **아직 잠근 기능이 없다** — 무엇을 유료로 할지 사용자 결정 대기.

## 2. 차별화(애플 지침 4.3 대비, `~/talkverse/STORE_DIFFERENTIATION.md`)

### 스토어 설명 첫 줄(안)
> 같은 「ㄱ」이 힌디어에서는 네 소리(क·ख·ग·घ)로 갈리고, 혀를 말아 내는 소리(ट·ड)가 따로 있습니다 — 데바나가리 글자 하나하나를 한국어 소리와 1:1 로 견주며, 영화·드라마에서 자주 들리는 순서대로 배웁니다.

### 힌디어 전용 학습 도구(지금 앱에 있는 것만)
1. **데바나가리와 발음** — 모음 13(짧은·긴 모음 짝, 아누스바라·비사르가), 모음 부호 13(का·कि·की … 할란트), 자음 다섯 줄을 「무기 · 유기 · 유성 · 유성 유기 · 비음」 같은 칸에 배열(목·입천장·혀 말아·이·입술), 반모음·마찰음, 누크타 7(क़·ख़·ग़·ज़·फ़·ड़·ढ़). 글자를 누르면 1초 뒤 재생, IPA, 소리나는 곳, 내는 방식, 한국어 화자 비교(예: ठ = 혀를 만 ㅌ, घ = ㄱ과 ㅎ을 한 소리로).
2. **회화 리더의 글자 풀이** — 문장 속 낱말을 길게 누르면 낱말을 음절 단위로 쪼개 자음·모음 부호·한글 소리를 보여 준다. 짧게 누르면 기본형으로 단어창(활용형 → 기본형). 존대(आप/तुम/तू)·성별형 꼬리표.
3. **절벽 단어** — 힌디어 영화·드라마 대사 80편(65만 토큰)을 기본형으로 센 순위: 28단어로 55%, 39단어 60%, 84단어 70%, 226단어 80%, 2,000단어 94.6%. 20어 단원 타일, 회화에 나온 단어 포함 보기, 한글 독음(기본 꺼짐).
4. **문법 강의·테스트 / 문장 카드 / 문장 말하기 / 청크 검색** — 힌디어 문장으로 만든 연습.

### 출시 전에 채울 것(지금은 없음 — 설명에 쓰지 않는다)
- 회화 150편(R1 83·R2 42·R3 25, 학습자 남녀판)은 Claude 초안 단계 — Grok 재작성·Gemini 검수·사용자 통과 뒤 앱 연결. 지금 앱 회화는 9월 초안 5편.
- 회화 음성: 시험 3편(96줄)만 생성, 앱 DB 에는 없음. 장면 컷 없음.
- 「동사 활용」·「표현」 메뉴는 「준비 중」 — 출시 전에 채우거나 뺀다(지침 2.1). 「성·수」는 메뉴 없이 안내 한 줄.
- 발음 화면의 조음 위치·모음 그림은 임시 — 출시 전에 Grok 그림으로 바꾼다.

### 실측 숫자(출시 때 다시 확인)
- 절벽: R1 28 · R2 39 · R3 84 · R4 226 기본형(누적 55/60/70/80%), 2,000위 94.6%.
- 데바나가리 모듈: 모음 13 · 모음 부호 13 · 자음 33 + 누크타 7.
- 회화: 앱 5편 / 초안 150편·1,509턴(출시 전 숫자로 바꿀 것). 음성 줄: 0(앱 기준).

### 심사 메모 문단(영문, 숫자는 출시 판 기준으로 채움)
> This app is one of a family of language-specific apps by Universal Talking Lab (Talkverse). Each app is built from scratch for one target language for Korean speakers and is NOT a re-skin: the Hindi app has its own Devanagari script & pronunciation module (13 vowels, 13 vowel signs, the five stop series laid out by aspiration and voicing — unaspirated, aspirated, voiced, breathy-voiced, nasal — including retroflex consonants, and 7 nukta letters), its own grammar tools (postpositions, gender agreement and honorific level tags on every sentence), [N] original conversation episodes with recorded audio written for this language, and a vocabulary list measured from a Hindi conversation corpus (28 / 39 / 84 / 226 lemmas cover 55 / 60 / 70 / 80 %). Content, curriculum and UI flows differ between apps; we keep them separate because learners search for and buy one language at a time.

### 스크린샷 순서(고유 화면 먼저)
1. 데바나가리와 발음 — ट 줄(혀 말아) 격자 + 발음 시트(IPA·한국어 비교)
2. 회화 리더 — 낱말 글자 풀이·존대/성별 꼬리표
3. 절벽 단어 — 28/39/84/226 표와 20어 단원 타일
4. 문법 강의 또는 문장 말하기
5. 결제 시트(정가 취소선·할인가) — 마지막. 홈·프로필로 시작하지 않는다.
