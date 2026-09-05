import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Profile / Settings Screen matching the approved visual design system
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AnubhavGradients.warmBackground,
      ),
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile & Settings',
                style: AnubhavTextStyles.headlineLarge,
              ),
              const SizedBox(height: 12),

              // ─── User Profile Card ───────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AnubhavColors.cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AnubhavColors.cardBorder),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x147A1F1F),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AnubhavColors.tealSurface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AnubhavColors.teal, width: 2),
                      ),
                      child: const Center(
                        child: Text(
                          'VG',
                          style: TextStyle(
                            color: AnubhavColors.teal,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vaibhav Gupta',
                            style: AnubhavTextStyles.titleLarge,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Preferred: Hindi (हिन्दी)',
                            style: AnubhavTextStyles.bodySmall.copyWith(
                              color: AnubhavColors.teal,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Member since September 2026',
                            style: AnubhavTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.edit_outlined, color: AnubhavColors.textTertiary, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ─── Hardware & Calibration ──────────────────────────────────────
              Text(
                'VR Hardware & Devices',
                style: AnubhavTextStyles.titleLarge,
              ),
              const SizedBox(height: 12),

              _buildSettingsCard([
                _buildSettingsRow(
                  icon: Icons.view_in_ar_rounded,
                  title: 'VR Headset Status',
                  subtitle: 'Meta Quest 3 • Connected',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F8F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Ready',
                      style: AnubhavTextStyles.bodySmall.copyWith(
                        color: AnubhavColors.positive,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                _buildDivider(),
                _buildSettingsRow(
                  icon: Icons.mic_external_on_rounded,
                  title: 'Microphone & Audio Input',
                  subtitle: 'Built-in Quest 3 Array (16kHz PCM)',
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AnubhavColors.textTertiary),
                ),
              ]),
              const SizedBox(height: 24),

              // ─── Preferences ─────────────────────────────────────────────────
              Text(
                'Preferences & Feedback',
                style: AnubhavTextStyles.titleLarge,
              ),
              const SizedBox(height: 12),

              _buildSettingsCard([
                _buildSettingsRow(
                  icon: Icons.notifications_none_rounded,
                  title: 'Practice Reminders',
                  subtitle: 'Daily streak alerts at 9:00 AM',
                  trailing: Switch.adaptive(
                    value: true,
                    activeTrackColor: AnubhavColors.teal,
                    onChanged: (_) {},
                  ),
                ),
                _buildDivider(),
                _buildSettingsRow(
                  icon: Icons.language_rounded,
                  title: 'Coaching Voice Model',
                  subtitle: 'Sarvam Bulbul (Expressive Female)',
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AnubhavColors.textTertiary),
                ),
                _buildDivider(),
                _buildSettingsRow(
                  icon: Icons.psychology_outlined,
                  title: 'Emotion Sensing Engine',
                  subtitle: 'Hume AI EVI + DSP Prosody Fallback',
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AnubhavColors.textTertiary),
                ),
                _buildDivider(),
                _buildSettingsRow(
                  icon: Icons.play_circle_outline_rounded,
                  title: 'Preview Landing Screen',
                  subtitle: 'Replay 3-second splash experience',
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AnubhavColors.textTertiary),
                  onTap: () {
                    Navigator.pushNamed(context, '/landing');
                  },
                ),
              ]),
              const SizedBox(height: 24),

              // ─── Privacy & Disclaimer ────────────────────────────────────────
              Text(
                'Data & Ethics',
                style: AnubhavTextStyles.titleLarge,
              ),
              const SizedBox(height: 12),

              _buildSettingsCard([
                _buildSettingsRow(
                  icon: Icons.shield_outlined,
                  title: 'Model-Derived Proxy Notice',
                  subtitle: 'Metrics are coaching proxies, not medical assessments.',
                  trailing: const Icon(Icons.info_outline_rounded, size: 16, color: AnubhavColors.teal),
                ),
              ]),
              const SizedBox(height: 32),

              // ─── Sign Out Button ─────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/onboarding');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AnubhavColors.negative,
                    side: const BorderSide(color: Color(0xFFFCDAD7)),
                    backgroundColor: AnubhavColors.cardBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Sign Out',
                        style: AnubhavTextStyles.titleMedium.copyWith(
                          color: AnubhavColors.negative,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AnubhavColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AnubhavColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F7A1F1F),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AnubhavColors.tealSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AnubhavColors.teal, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AnubhavTextStyles.titleMedium.copyWith(fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: AnubhavTextStyles.bodySmall),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: row,
        ),
      );
    }
    return row;
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 18,
      endIndent: 18,
      color: AnubhavColors.divider,
    );
  }
}
