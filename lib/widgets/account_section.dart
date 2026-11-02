import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../data/account.dart';
import '../data/entitlement.dart';
import '../data/purchase.dart';
import '../screens/login_screen.dart';

/// 프로필 화면의 '계정' 칸 — 한자 앱 me_screen 의 계정·구매 복원 칸을 옮김(2026-11-02).
/// 로그인 전: 로그인 타일 / 로그인 후: 이름·이메일·로그아웃·계정 삭제(스토어 심사 요구). 아래에 평생 이용권·구매 복원.
class AccountSection extends StatelessWidget {
  const AccountSection({super.key});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _card(ValueListenableBuilder<Map<String, dynamic>?>(
          valueListenable: Account.user,
          builder: (context, u, _) => u == null
              ? ListTile(
                  leading: const Icon(Icons.account_circle_outlined, color: AppColors.rojo),
                  title: Text(tr('로그인')),
                  subtitle: Text(tr('Talkverse 계정 하나로 모든 앱에서'), style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => LoginScreen.open(context),
                )
              : Column(children: [
                  ListTile(
                    leading: const Icon(Icons.account_circle, color: AppColors.rojo),
                    title: Text((u['display_name'] as String?) ?? tr('이름 없음')),
                    subtitle: u['email'] == null ? null : Text(u['email'] as String, style: const TextStyle(fontSize: 12)),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout, color: AppColors.gualdaDeep),
                    title: Text(tr('로그아웃')),
                    onTap: () => Account.signOut(),
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_remove_outlined, color: AppColors.gualdaDeep),
                    title: Text(tr('계정 삭제')),
                    onTap: () => _confirmDelete(context),
                  ),
                ]),
        )),
        const SizedBox(height: 8),
        _card(AnimatedBuilder(
          animation: Listenable.merge([Account.entitlements, Purchase.owned]),
          builder: (context, _) => ListTile(
            leading: const Icon(Icons.workspace_premium_outlined, color: AppColors.rojo),
            title: Text(tr('평생 이용권')),
            subtitle: Text(Entitlement.premium ? tr('이용 중') : tr('한 번 결제 · 구독 아님'), style: const TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Entitlement.showPaywall(context),
          ),
        )),
        const SizedBox(height: 8),
        _card(ListTile(
          leading: const Icon(Icons.restore, color: AppColors.rojo),
          title: Text(tr('구매 복원')),
          subtitle: ValueListenableBuilder<String?>(
            valueListenable: Purchase.status,
            builder: (_, st, _) => Text(
                switch (st) {
                  'pending' => tr('확인 중…'),
                  'restored' => tr('복원했습니다'),
                  'nothing' => tr('복원할 구매가 없습니다'),
                  _ => tr('이전에 산 평생 이용권을 이 기기에서 다시 엽니다'),
                },
                style: const TextStyle(fontSize: 12)),
          ),
          onTap: () => Purchase.restore(),
        )),
      ]);

  Widget _card(Widget child) => Container(
        decoration: BoxDecoration(
          color: AppColors.cal,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.gualda),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(type: MaterialType.transparency, child: child),
      );

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(tr('계정을 삭제할까요?')),
        content: Text(tr('Talkverse 계정과 이름·이메일·로그인 정보가 지워지고 모든 기기에서 로그아웃됩니다. 이 기기의 학습 기록은 그대로 남습니다. 되돌릴 수 없습니다.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(tr('취소'))),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(tr('삭제'), style: const TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Account.deleteAccount();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(tr('삭제하지 못했습니다. 네트워크를 확인하고 다시 시도해 주세요.'))));
      }
    }
  }
}
