import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:barbs_bedtime_stories/core/theme/app_colors.dart';
import 'package:barbs_bedtime_stories/core/theme/app_typography.dart';
import 'package:barbs_bedtime_stories/data/providers.dart';

class SleepTimerSheet extends ConsumerStatefulWidget {
  const SleepTimerSheet({super.key});

  @override
  ConsumerState<SleepTimerSheet> createState() => _SleepTimerSheetState();
}

class _SleepTimerSheetState extends ConsumerState<SleepTimerSheet> {
  int _selectedValue = 0; // Default to Off

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(appConfigProvider);
    final timerMinutes =
        configAsync.value?.sleepTimerDefaults ?? [15, 30, 45, 60];

    final options = <Map<String, dynamic>>[
      for (final mins in timerMinutes)
        {'label': '$mins minutes', 'value': mins},
      {'label': 'End of Story', 'value': -1},
      {'label': 'Off', 'value': 0},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, color: AppColors.warmGold),
                const SizedBox(width: 12),
                const Text(
                  'Sleep Timer',
                  style: AppTypography.headlineMedium,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => context.pop(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...options.map((option) {
            final value = option['value'] as int;
            final isSelected = value == _selectedValue;
            
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              title: Text(
                option['label'] as String,
                style: AppTypography.bodyLarge.copyWith(
                  color: isSelected ? AppColors.warmGold : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.radio_button_checked, color: AppColors.warmGold)
                  : const Icon(Icons.radio_button_unchecked, color: AppColors.textSecondary),
              onTap: () {
                setState(() {
                  _selectedValue = value;
                });
                context.pop(value);
              },
            );
          }),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
