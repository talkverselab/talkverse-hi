import 'package:flutter/material.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../data/db/app_database.dart';
import '../embed.dart' show appDb;
import '../services/dialogue_service.dart';
import '../services/ko_reading.dart';

/// 단어장(DB `words`, 1,500)에서 기본형으로 찾기 — 문장 레마 칩용(일본어앱 2026-11-04 `WordService.byLemmas` 와 같은 역할).
Future<Map<String, WordRow>> wordsByLemmas(Iterable<String> bases) async {
  final keys = bases.toSet().where((b) => b.isNotEmpty).toList();
  if (keys.isEmpty) return const {};
  final rows = await (appDb.select(appDb.words)..where((w) => w.word.isIn(keys))).get();
  final out = <String, WordRow>{};
  for (final r in rows..sort((a, b) => a.rank.compareTo(b.rank))) {
    out.putIfAbsent(r.word, () => r);
  }
  return out;
}

/// 문장의 내용어(레마) 칩 — 단어장에 있는 말은 누르면 단어 시트, 없는 말은 회색.
/// 같은 기본형은 한 번만. 단어장에 없는 레마 목록은 uk 세션이 채운다(`data/review/write/missing_lemmas.csv`).
class LemmaChips extends StatelessWidget {
  final DialogueTurn turn;
  final bool compact;
  const LemmaChips({super.key, required this.turn, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final seen = <String>{};
    final lemmas = [for (final l in turn.lemmas) if (seen.add(l.base)) l];
    if (lemmas.isEmpty) return const SizedBox.shrink();
    return FutureBuilder<Map<String, WordRow>>(
      key: ValueKey('${turn.num}:${turn.tl}'),
      future: wordsByLemmas(lemmas.map((l) => l.base)),
      builder: (context, snap) {
        final found = snap.data ?? const {};
        return Wrap(spacing: 6, runSpacing: 6, children: [
          for (final l in lemmas)
            _Chip(
              label: l.base,
              gloss: found[l.base]?.meaningKo,
              compact: compact,
              onTap: found[l.base] == null ? null : () => showWordSheet(context, found[l.base]!),
            ),
        ]);
      },
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String? gloss;
  final bool compact;
  final VoidCallback? onTap;
  const _Chip({required this.label, this.gloss, this.compact = false, this.onTap});
  @override
  Widget build(BuildContext context) {
    final on = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 7 : 9, vertical: compact ? 3 : 4),
        decoration: BoxDecoration(
          color: on ? AppColors.washi : AppColors.washiDeep,
          border: Border.all(color: on ? AppColors.beni.withValues(alpha: 0.7) : AppColors.line),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: TextStyle(fontSize: compact ? 12.5 : 14, fontWeight: FontWeight.w800, color: on ? AppColors.sumi : AppColors.muted)),
          if (gloss != null && gloss!.isNotEmpty) ...[
            const SizedBox(width: 5),
            Text(gloss!.split(RegExp(r'[,;·/]')).first.trim(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: compact ? 10 : 11, color: AppColors.sumiLight)),
          ],
        ]),
      ),
    );
  }
}

/// 단어 시트 — 단어·독음·뜻·품사·절벽 구간.
Future<void> showWordSheet(BuildContext context, WordRow w) => showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.washi,
      builder: (c) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(w.word, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.sumi, height: 1.4)),
              const SizedBox(width: 10),
              if (w.cefr != null) Padding(padding: const EdgeInsets.only(bottom: 6), child: KoReadingText(w.cefr!, style: const TextStyle(fontSize: 15, color: AppColors.muted))),
              const Spacer(),
              if (w.region != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.beni.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(w.region!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.beni)),
                ),
            ]),
            const SizedBox(height: 6),
            Text(w.meaningKo ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.sumi)),
            const SizedBox(height: 6),
            Text(trf('빈도 {0}위 · {1}', [w.rank, w.pos ?? '']), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ]),
        ),
      ),
    );
