import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Feature card widget for the home screen
/// White background with small green icon container
class HomeFeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const HomeFeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon container with light green background
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.dashboardBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 24,
              color: AppTheme.dashboardGreen,
            ),
          ),
          const SizedBox(height: 16),
          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          // Description
          Text(
            description,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textGray,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
