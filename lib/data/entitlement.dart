import 'package:flutter/material.dart';

import 'account.dart';
import 'purchase.dart';
import '../screens/paywall_screen.dart';
import '../services/curriculum_service.dart';
import '../services/dialogue_service.dart';

/// 이용권 — Talkverse 계정 이용권(lang 'hi', auth.talkverse.uk) OR 이 기기에서 산·복원한 스토어 구매(lang_hi_* · all_*).
/// 무료/유료 범위 = ~/talkverse/PAYWALL_SPEC.md §2(uk 의 정함, 사용자 「1 2 모두 진행」 11-23): 무료 = 커리큘럼·회화 1단계, 문법 1~2스텝, 언어감각 1급.
/// 잠긴 곳은 숨기지 않고 자물쇠 → 결제 화면.
class Entitlement {
  Entitlement._();
  static const lang = 'hi';

  static bool get premium => Account.has(lang) || Purchase.owns(lang);

  static bool stageOpen(String key) => premium || CurriculumService.instance.stageFree(key);
  static bool dialogueOpen(Dialogue d) => premium || CurriculumService.instance.dialogueFree(d);

  /// 문법 스텝 n(1부터)·언어감각 급 순번 n(1부터).
  static bool grammarStepOpen(int n) => premium || n <= CurriculumService.instance.freeSteps;
  static bool senseLevelOpen(int n) => premium || n <= CurriculumService.instance.freeSenseLevels;

  static Future<void> showPaywall(BuildContext context) => PaywallScreen.show(context);
}

/// 잠긴 항목 끝에 붙는 자물쇠.
class LockMark extends StatelessWidget {
  const LockMark({super.key});
  @override
  Widget build(BuildContext context) => const Icon(Icons.lock_outline, size: 18, color: Color(0xFF8A94A6));
}
