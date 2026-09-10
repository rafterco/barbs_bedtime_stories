import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:barbs_bedtime_stories/core/theme/app_colors.dart';
import 'package:barbs_bedtime_stories/core/theme/app_typography.dart';
import 'package:barbs_bedtime_stories/services/ambient_sound_service.dart';

class AmbientSoundMixer extends StatefulWidget {
  const AmbientSoundMixer({super.key});

  @override
  State<AmbientSoundMixer> createState() => _AmbientSoundMixerState();
}

class _AmbientSoundMixerState extends State<AmbientSoundMixer> {
  final AmbientSoundService _service = AmbientSoundService.instance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(
          top: BorderSide(
            color: AppColors.lavender.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
              // Header with Close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 32),
                  const Text(
                    'Ambient Sounds',
                    style: AppTypography.headlineMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.moonlightWhite, size: 22),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Mix up to 3 sounds to create your perfect atmosphere.',
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              
              ValueListenableBuilder<List<AmbientSound>>(
                valueListenable: _service.activeSounds,
                builder: (context, activeSounds, _) {
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: _service.allSounds.length,
                    itemBuilder: (context, index) {
                      final sound = _service.allSounds[index];
                      final isActive = sound.isActive;
                      final isDisabled = !isActive && activeSounds.length >= 3;
                      
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: isDisabled
                            ? null
                            : () {
                                HapticFeedback.selectionClick();
                                _service.toggleSound(sound.id);
                              },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isActive
                                    ? AppColors.warmGold.withValues(alpha: 0.25)
                                    : AppColors.surface,
                                border: Border.all(
                                  color: isActive ? AppColors.warmGold : Colors.white.withValues(alpha: 0.1),
                                  width: isActive ? 2 : 1,
                                ),
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: AppColors.warmGold.withValues(alpha: 0.35),
                                          blurRadius: 10,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                              alignment: Alignment.center,
                              child: Opacity(
                                opacity: isDisabled ? 0.35 : 1.0,
                                child: Text(
                                  sound.emoji,
                                  style: const TextStyle(fontSize: 28),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              sound.name,
                              style: AppTypography.labelSmall.copyWith(
                                color: isActive ? AppColors.warmGold : AppColors.moonlightWhite,
                                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            
            ValueListenableBuilder<List<AmbientSound>>(
              valueListenable: _service.activeSounds,
              builder: (context, activeSounds, _) {
                if (activeSounds.isEmpty) return const SizedBox.shrink();
                return Column(
                  children: [
                    const SizedBox(height: 24),
                    const Divider(color: AppColors.surface),
                    const SizedBox(height: 16),
                    ...activeSounds.map((sound) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            children: [
                              Text(sound.emoji, style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderThemeData(
                                    activeTrackColor: AppColors.warmGold,
                                    inactiveTrackColor: AppColors.surface,
                                    thumbColor: AppColors.warmGold,
                                    overlayColor: AppColors.warmGold.withValues(alpha: 0.2),
                                    trackHeight: 4,
                                  ),
                                  child: Slider(
                                    value: sound.volume,
                                    onChanged: (val) => _service.setVolume(sound.id, val),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        _service.stopAll();
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                      child: const Text('Stop All Sounds'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ),);
  }
}
