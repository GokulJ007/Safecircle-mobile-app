import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

/// Banner showing whether the user currently has an active journey.
class SafetyStatusCard extends StatelessWidget {
  final bool hasActiveJourney;
  final VoidCallback onPrimaryAction;
  final String inactiveTitle;
  final String inactiveSubtitle;
  final String inactiveButtonLabel;
  final String activeTitle;
  final String activeSubtitle;
  final String activeButtonLabel;

  const SafetyStatusCard({
    super.key,
    required this.hasActiveJourney,
    required this.onPrimaryAction,
    this.inactiveTitle = 'No active journey',
    this.inactiveSubtitle = 'Start a journey to share it with your trusted circle',
    this.inactiveButtonLabel = 'Start Journey',
    this.activeTitle = 'Journey in progress',
    this.activeSubtitle = 'Live tracking is active and your circle can see your route',
    this.activeButtonLabel = 'View Journey',
  });

  @override
  Widget build(BuildContext context) {
    if (hasActiveJourney) {
      return _buildCard(
        context,
        gradientColors: [AppColors.warningOrange, const Color(0xFFE0851A)],
        icon: Icons.navigation_rounded,
        title: activeTitle,
        subtitle: activeSubtitle,
        buttonLabel: activeButtonLabel,
        statusLabel: 'Live',
      );
    }

    return _buildCard(
      context,
      gradientColors: AppColors.splashGradient,
      icon: Icons.verified_user_rounded,
      title: inactiveTitle,
      subtitle: inactiveSubtitle,
      buttonLabel: inactiveButtonLabel,
      statusLabel: 'Mock data',
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required List<Color> gradientColors,
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required String statusLabel,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.92)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                  ),
                  child: Text(
                    statusLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.shield_outlined,
                  color: Colors.white,
                  size: 18,
                ),
                Text(
                  'Mock frontend only',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onPrimaryAction,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  buttonLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}