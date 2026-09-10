import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:barbs_bedtime_stories/core/theme/app_colors.dart';
import 'package:barbs_bedtime_stories/core/theme/app_typography.dart';
import 'package:barbs_bedtime_stories/data/models/app_config.dart';
import 'package:barbs_bedtime_stories/data/providers.dart';
import 'package:barbs_bedtime_stories/services/audio_player_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const String currentAppVersion = '1.3.16 (build 29)';
  bool _autoPlay = true;

  @override
  void initState() {
    super.initState();
    _autoPlay = AudioPlayerService.instance.autoPlayEnabled.value;
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(appConfigProvider);

    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        backgroundColor: AppColors.deepNavy,
        elevation: 0,
        title: const Text('Settings', style: AppTypography.headlineLarge),
        centerTitle: false,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 60),
        children: [
          _buildSectionHeader('ABOUT THE APP'),
          _buildListTile(
            title: 'About the App',
            subtitle: 'Our philosophy, features & craft',
            icon: Icons.auto_stories_rounded,
            onTap: () {
              HapticFeedback.lightImpact();
              _showAboutAppSheet(context, configAsync.value);
            },
          ),

          const Divider(color: AppColors.surfaceLight, thickness: 1, height: 32),

          _buildSectionHeader('PLAYBACK PREFERENCES'),
          _buildSwitchTile(
            title: 'Continuous Playback',
            subtitle: 'Play next story automatically when current ends',
            icon: Icons.playlist_play_rounded,
            value: _autoPlay,
            onChanged: (val) {
              HapticFeedback.selectionClick();
              setState(() => _autoPlay = val);
              AudioPlayerService.instance.autoPlayEnabled.value = val;
            },
          ),

          const Divider(color: AppColors.surfaceLight, thickness: 1, height: 32),

          _buildSectionHeader('SUPPORT & FEEDBACK'),
          _buildListTile(
            title: 'Contact us',
            subtitle: configAsync.value?.contactEmail ?? 'colinrafter82@gmail.com',
            icon: Icons.email_outlined,
            onTap: () async {
              HapticFeedback.lightImpact();
              final targetEmail =
                  configAsync.value?.contactEmail ?? 'colinrafter82@gmail.com';
              final emailUri = Uri(
                scheme: 'mailto',
                path: targetEmail,
                queryParameters: {
                  'subject': "Barbara's Bedtime Stories - Support",
                },
              );
              try {
                final launched = await launchUrl(
                  emailUri,
                  mode: LaunchMode.externalApplication,
                );
                if (!launched) {
                  await launchUrl(emailUri);
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Reach us directly at $targetEmail'),
                      backgroundColor: AppColors.surfaceLight,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
          ),
          _buildListTile(
            title: 'Rate the app',
            subtitle: defaultTargetPlatform == TargetPlatform.iOS
                ? 'Share your review on the App Store'
                : 'Share your review on the Google Play Store',
            icon: Icons.star_rounded,
            onTap: () => _rateApp(context),
          ),

          const Divider(color: AppColors.surfaceLight, thickness: 1, height: 32),

          _buildSectionHeader('LEGAL'),
          _buildListTile(
            title: 'Privacy Policy',
            icon: Icons.privacy_tip_outlined,
            onTap: () {
              HapticFeedback.lightImpact();
              _showLegalSheet(
                context,
                title: 'Privacy Policy',
                url: 'https://barbs-bedtime-stories-landing.vercel.app/privacy.html',
                content: _privacyPolicyText,
              );
            },
          ),
          _buildListTile(
            title: 'Terms of Service',
            icon: Icons.description_outlined,
            onTap: () {
              HapticFeedback.lightImpact();
              _showLegalSheet(
                context,
                title: 'Terms of Service',
                url: 'https://barbs-bedtime-stories-landing.vercel.app/terms.html',
                content: _termsOfServiceText,
              );
            },
          ),
          _buildListTile(
            title: 'EULA (License Agreement)',
            icon: Icons.gavel_outlined,
            onTap: () {
              HapticFeedback.lightImpact();
              _showLegalSheet(
                context,
                title: 'End User License Agreement',
                url: 'https://barbs-bedtime-stories-landing.vercel.app/eula.html',
                content: _eulaText,
              );
            },
          ),

          const SizedBox(height: 60),
          
          // Branding & Version Footnote at the bottom
          Center(
            child: Column(
              children: [
                const Icon(
                  Icons.nightlight_round,
                  color: AppColors.warmGold,
                  size: 28,
                ),
                const SizedBox(height: 10),
                Text(
                  'Sweet Dreams',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.lavender.withValues(alpha: 0.9),
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Barbara's Sleep Stories · v$currentAppVersion",
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.lavender.withValues(alpha: 0.45),
                    fontSize: 11.5,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _rateApp(BuildContext context) async {
    HapticFeedback.lightImpact();
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;

    if (isIos) {
      final reviewUri = Uri.parse(
        'https://apps.apple.com/us/app/barbaras-sleep-stories/id6445966741?action=write-review',
      );
      try {
        final launched = await launchUrl(
          reviewUri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched) {
          await launchUrl(
            Uri.parse('https://apps.apple.com/us/app/barbaras-sleep-stories/id6445966741'),
            mode: LaunchMode.externalApplication,
          );
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thank you for rating Barbara\'s Sleep Stories! ⭐'),
              backgroundColor: AppColors.surfaceLight,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else {
      final marketUri = Uri.parse('market://details?id=com.rafterco.barbs_bedtime_stories');
      final webPlayStoreUri = Uri.parse(
        'https://play.google.com/store/apps/details?id=com.rafterco.barbs_bedtime_stories',
      );

      try {
        final launched = await launchUrl(
          marketUri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched) {
          await launchUrl(webPlayStoreUri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {
        try {
          await launchUrl(webPlayStoreUri, mode: LaunchMode.externalApplication);
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Thank you for rating Barbara\'s Sleep Stories! ⭐'),
                backgroundColor: AppColors.surfaceLight,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title,
        style: AppTypography.sectionLabel.copyWith(color: AppColors.lavender),
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    String? subtitle,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(icon, color: AppColors.textPrimary, size: 26),
      title: Text(title, style: AppTypography.bodyLarge),
      subtitle: subtitle != null
          ? Text(subtitle, style: AppTypography.bodySmall)
          : null,
      trailing: onTap != null
          ? const Icon(Icons.chevron_right, color: AppColors.textMuted)
          : null,
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      secondary: Icon(icon, color: AppColors.textPrimary, size: 26),
      title: Text(title, style: AppTypography.bodyLarge),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.lavender.withValues(alpha: 0.75),
              ),
            )
          : null,
      activeColor: AppColors.warmGold,
      activeTrackColor: AppColors.warmGold.withValues(alpha: 0.3),
      inactiveThumbColor: AppColors.textMuted,
      inactiveTrackColor: AppColors.surfaceLight,
      value: value,
      onChanged: onChanged,
    );
  }

  void _showAboutAppSheet(BuildContext context, [AppConfig? config]) {
    final mission = config?.aboutAppMission.trim().isNotEmpty == true
        ? config!.aboutAppMission.trim()
        : 'Good sleep is essential to our well-being, helping support memory, learning, mood, concentration, and our ability to manage the demands of everyday life. Yet for many of us, slowing down enough to fall asleep can be surprisingly difficult. A calming bedtime routine and relaxing activities can help create the transition from wakefulness to rest. This app offers adults a gentle way to step away from the busyness of the day through engaging, soothing stories written especially for bedtime. Settle in, let the story take you somewhere else, and give your busy mind a quiet place to go before sleep.';
    final storyRequests = config?.aboutAppStoryRequests.trim().isNotEmpty == true
        ? config!.aboutAppStoryRequests.trim()
        : "Have a favourite childhood tale or a tranquil bedtime theme you'd like Barbara to record? We would love to hear from you.";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.80,
          decoration: const BoxDecoration(
            color: Color(0xFF130E2E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: Color(0x33E8C97A), width: 1.5),
            ),
          ),
          child: Column(
            children: [
              // Top drag bar & header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.surfaceLight, width: 1),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text('🌙 ', style: TextStyle(fontSize: 20)),
                            Text(
                              'About the App',
                              style: AppTypography.headlineSmall.copyWith(
                                color: AppColors.warmGold,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Content Area
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // App Hero Banner
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                gradient: const RadialGradient(
                                  colors: [Color(0xFF261D52), Color(0xFF0F0B24)],
                                ),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: AppColors.warmGold.withValues(alpha: 0.4),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.warmGold.withValues(alpha: 0.15),
                                    blurRadius: 18,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.nightlight_round,
                                color: AppColors.warmGold,
                                size: 38,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Barbara\'s Sleep Stories',
                              style: AppTypography.headlineMedium.copyWith(
                                color: AppColors.moonlightWhite,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Version $currentAppVersion • Designed for Peaceful Rest',
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.lavender,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Mission Statement Box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E173D),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.warmGold.withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          mission,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.warmGold,
                            fontStyle: FontStyle.italic,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Core Principles Header
                      Text(
                        'Our Core Principles & Craft',
                        style: AppTypography.headlineSmall.copyWith(
                          color: AppColors.moonlightWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Feature Cards
                      _buildAboutFeatureTile(
                        icon: Icons.mic_rounded,
                        title: 'Authentic Human Narration',
                        description: 'Every story is gently narrated by Barbara with natural warmth and comforting cadence. No synthetic AI voices or robotic inflections.',
                      ),
                      const SizedBox(height: 12),
                      _buildAboutFeatureTile(
                        icon: Icons.waves_rounded,
                        title: 'Custom Ambient Soundscapes',
                        description: 'Multi-layer audio mixer allowing you to blend gentle rain, crackling fireplace, ocean tides, or summer night sounds beneath the story.',
                      ),
                      const SizedBox(height: 12),
                      _buildAboutFeatureTile(
                        icon: Icons.timer_outlined,
                        title: 'Gentle Fade-Out Sleep Timers',
                        description: 'Audio fades gradually to silence as the timer expires, ensuring your sleep cycle remains uninterrupted.',
                      ),
                      const SizedBox(height: 12),
                      _buildAboutFeatureTile(
                        icon: Icons.screen_lock_portrait_rounded,
                        title: 'Screen-Off Background Play',
                        description: 'Lock your screen and keep your bedroom dark while listening through lock-screen and headphone controls.',
                      ),
                      const SizedBox(height: 12),
                      _buildAboutFeatureTile(
                        icon: Icons.block_rounded,
                        title: '100% Ad-Free Guarantee',
                        description: 'We believe bedtime is sacred. There are no sudden interstitial video ads, trackers, or commercial popups.',
                      ),

                      const SizedBox(height: 24),

                      // Developer & Story Requests
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Story Requests & Feedback',
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.moonlightWhite,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              storyRequests,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(
                                  Icons.email_outlined,
                                  color: AppColors.warmGold,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'colinrafter82@gmail.com',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.warmGold,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAboutFeatureTile({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF191334),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.warmGold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.warmGold, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.moonlightWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLegalSheet(
    BuildContext context, {
    required String title,
    required String url,
    required String content,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.80,
          decoration: const BoxDecoration(
            color: Color(0xFF130E2E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: Color(0x33E8C97A), width: 1.5),
            ),
          ),
          child: Column(
            children: [
              // Top drag bar & header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppColors.surfaceLight, width: 1),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: AppTypography.headlineMedium.copyWith(
                              color: AppColors.warmGold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.lavender),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Scrollable Document Body
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                  child: Text(
                    content,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.6,
                    ),
                  ),
                ),
              ),

              // Bottom Action Bar with Web Link
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0D0A1C),
                    border: Border(
                      top: BorderSide(color: AppColors.surfaceLight, width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.lavender),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.open_in_browser_rounded, size: 18, color: AppColors.lavender),
                          label: const Text(
                            'Open on Web',
                            style: TextStyle(color: AppColors.lavender, fontWeight: FontWeight.w600),
                          ),
                          onPressed: () async {
                            final uri = Uri.parse(url);
                            try {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            } catch (_) {}
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.warmGold,
                            foregroundColor: AppColors.deepNavy,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Done',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

const String _privacyPolicyText = '''
BARBARA'S SLEEP STORIES — PRIVACY POLICY
Last Updated: September 2, 2026

1. INTRODUCTION
Welcome to Barbara's Sleep Stories. We are committed to protecting your privacy and providing a serene, safe environment for relaxation and sleep.

2. ZERO PERSONAL DATA COLLECTION
We do not collect, store, sell, or rent your personal identifiable information (such as your name, email address, physical location, or contacts) to any third parties.

3. LOCAL DEVICE STORAGE
To ensure a personalized bedtime experience, the app stores your preferences locally on your device:
• Favorited stories and playlists
• Downloaded audio tracks for offline playback
• Sleep timer preferences and ambient mixer volume levels

4. CLOUD STREAMING & STORAGE
Our audio narrations, artwork, and ambient soundscapes are hosted on Google Firebase Cloud Storage. Standard HTTPS requests stream content to your device without collecting identifying user telemetry.

5. PERMISSIONS
• Audio Foreground Playback: Allows soothing stories and ambient layers to continue playing when your screen is locked.
• Notifications: Used to provide lock-screen and background media playback controls.
• Internet: Required to stream narrations and download offline content.

6. CONTACT US
If you have questions about this policy:
Email: colinrafter82@gmail.com
Website: https://barbs-bedtime-stories-landing.vercel.app/privacy.html
''';

const String _termsOfServiceText = '''
BARBARA'S SLEEP STORIES — TERMS OF SERVICE
Last Updated: September 2, 2026

1. ACCEPTANCE OF TERMS
By downloading, installing, or using Barbara's Sleep Stories, you agree to be bound by these Terms of Service.

2. PURPOSE & NON-MEDICAL DISCLAIMER
Barbara's Sleep Stories is designed for personal relaxation, stress relief, and sleep support. The content provided is for wellness and relaxation purposes only and does NOT constitute medical advice, diagnosis, or treatment for chronic sleep disorders or insomnia.

3. INTELLECTUAL PROPERTY
All audio recordings, vocal narrations, story scripts, artwork, and trademarks are the exclusive property of Barbara's Sleep Stories and its licensors. You may not reproduce, redistribute, broadcast, or commercially exploit any content from the app.

4. USER CONDUCT
You agree to use the app solely for lawful, personal, non-commercial purposes.

5. LIMITATION OF LIABILITY
Barbara's Sleep Stories and its creators shall not be liable for any direct, indirect, incidental, or consequential damages arising from your use of the application.

6. CONTACT
Questions regarding these terms:
Email: colinrafter82@gmail.com
Website: https://barbs-bedtime-stories-landing.vercel.app/terms.html
''';

const String _eulaText = '''
END USER LICENSE AGREEMENT (EULA)
Last Updated: September 2, 2026

1. GRANT OF LICENSE
Barbara's Sleep Stories grants you a revocable, non-exclusive, non-transferable, limited license to download, install, and use the Application solely for your personal, non-commercial bedtime and relaxation use.

2. RESTRICTIONS
You agree not to:
• Decompile, reverse engineer, disassemble, or decrypt the Application.
• Extract, capture, or distribute audio narration tracks, sound effects, or cover artwork.
• Resell, rent, lease, or commercially exploit the Application.

3. THIRD-PARTY APP STORES
You acknowledge that this agreement is between you and Barbara's Sleep Stories only, and not with Apple Inc. or Google LLC.

4. TERMINATION
This license is effective until terminated. Your rights under this license will terminate automatically if you fail to comply with any terms.

5. CONTACT
Inquiries regarding this EULA:
Email: colinrafter82@gmail.com
Website: https://barbs-bedtime-stories-landing.vercel.app/eula.html
''';
