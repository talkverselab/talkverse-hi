import 'package:flutter/material.dart';

import 'account.dart';
import 'purchase.dart';
import '../screens/paywall_screen.dart';

/// 평생 이용권 — Talkverse 계정 이용권(lang 'hi', auth.talkverse.uk) OR 이 기기에서 산·복원한 스토어 구매(2026-11-02).
/// 아직 잠그는 콘텐츠는 없다 — 무료/유료 경계는 사용자 결정 대기(HANDOFF.md). 경계가 정해지면 여기에 `locked(...)` 를 둔다.
class Entitlement {
  Entitlement._();
  static const lang = 'hi';
  static const iosProduct = 'com.talkverse.hindiUniverse.lifetime';
  static const androidProduct = 'lang_hi';

  static bool get premium => Account.has(lang) || Purchase.owns(lang);

  static Future<void> showPaywall(BuildContext context) => PaywallScreen.show(context);
}
