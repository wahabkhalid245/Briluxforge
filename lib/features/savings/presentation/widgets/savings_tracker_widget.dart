// FILE: lib/features/savings/presentation/widgets/savings_tracker_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:briluxforge/core/theme/app_colors.dart';
import 'package:briluxforge/core/theme/app_tokens.dart';
import 'package:briluxforge/core/widgets/app_card.dart';
import 'package:briluxforge/features/savings/data/models/savings_model.dart';
import 'package:briluxforge/features/savings/presentation/widgets/savings_breakdown_modal.dart';
import 'package:briluxforge/features/savings/providers/savings_provider.dart';

class SavingsTrackerWidget extends ConsumerWidget {
  const SavingsTrackerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<SavingsSnapshot> savingsAsync =
        ref.watch(savingsNotifierProvider);

    final SavingsSnapshot snapshot = savingsAsync.when(
      data: (s) => s,
      loading: () => SavingsSnapshot.zero,
      error: (_, __) => SavingsSnapshot.zero,
    );

    return _SavingsCard(snapshot: snapshot);
  }
}

class _SavingsCard extends StatelessWidget {
  const _SavingsCard({required this.snapshot});

  final SavingsSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double monthsOfClaudePro = snapshot.totalSaved / 20;
    final bool showMonths = snapshot.totalSaved >= 20;

    return AppCard(
      onTap: () => showSavingsBreakdownModal(context, snapshot),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.savings_outlined,
                size: 14,
                color: AppColors.savingsGreen,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Savings Tracker',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.savingsGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.chevron_right,
                size: 14,
                color: AppColors.textTertiary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _AnimatedSavingsAmount(
            amount: snapshot.totalSaved,
            theme: theme,
          ),
          const SizedBox(height: AppSpacing.xxs),
          if (snapshot.savingsMultiple > 0)
            Text(
              '${snapshot.savingsMultiple.toStringAsFixed(1)}× cheaper than '
              '${snapshot.benchmarkDisplayName}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textTertiary,
              ),
            )
          else
            Text(
              'vs. ${snapshot.benchmarkDisplayName}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          if (showMonths) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              "That's ~${monthsOfClaudePro.floor()} months of Claude Pro ✨",
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.savingsGreenDim,
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Animated amount counter ───────────────────────────────────────────────────

class _AnimatedSavingsAmount extends StatefulWidget {
  const _AnimatedSavingsAmount({
    required this.amount,
    required this.theme,
  });

  final double amount;
  final ThemeData theme;

  @override
  State<_AnimatedSavingsAmount> createState() => _AnimatedSavingsAmountState();
}

class _AnimatedSavingsAmountState extends State<_AnimatedSavingsAmount> {
  double _previousAmount = 0;

  @override
  void didUpdateWidget(_AnimatedSavingsAmount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.amount != widget.amount) {
      _previousAmount = oldWidget.amount;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: _previousAmount, end: widget.amount),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOut,
      builder: (_, double value, __) => Text(
        "You've saved \$${value.toStringAsFixed(2)}",
        style: widget.theme.textTheme.titleSmall?.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
