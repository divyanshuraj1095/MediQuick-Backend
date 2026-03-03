import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Hero section widget with icon, heading, subtitle, and CTA buttons
class HeroSection extends StatelessWidget {
  final VoidCallback? onBrowseProductsPressed;
  final VoidCallback? onLearnMorePressed;

  const HeroSection({
    super.key,
    this.onBrowseProductsPressed,
    this.onLearnMorePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 60),
        // Large circular icon
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppTheme.dashboardGreen,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.dashboardGreen.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.medical_services,
            size: 60,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 40),
        // Main Heading
        const Text(
          'Your Trusted Medical\nSupply Partner',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 24),
        // Subtitle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Quality medical products delivered fast. From diagnostic equipment to first aid supplies, we have everything you need.',
            textAlign: TextAlign.center,
            style: AppTheme.bodyLarge.copyWith(
              fontSize: 18,
              color: AppTheme.textGray,
            ),
          ),
        ),
        const SizedBox(height: 40),
        // CTA Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Primary Button: Browse Products
            Container(
              decoration: BoxDecoration(
                color: AppTheme.dashboardGreen,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.dashboardGreen.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onBrowseProductsPressed ?? () {},
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    child: const Text(
                      'Browse Products',
                      style: AppTheme.buttonText,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Secondary Button: Learn More
            OutlinedButton(
              onPressed: onLearnMorePressed ?? () {},
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                side: const BorderSide(
                  color: AppTheme.dashboardGreen,
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Learn More',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.dashboardGreen,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}
