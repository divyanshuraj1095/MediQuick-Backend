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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return Column(
          children: [
            SizedBox(height: isMobile ? 32 : 60),
            // Large circular icon
            Container(
              width: isMobile ? 80 : 120,
              height: isMobile ? 80 : 120,
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
              child: Icon(
                Icons.medical_services,
                size: isMobile ? 40 : 60,
                color: Colors.white,
              ),
            ),
            SizedBox(height: isMobile ? 24 : 40),
            // Main Heading
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Your Trusted Medical\nSupply Partner',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isMobile ? 32 : 48,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                  height: 1.2,
                ),
              ),
            ),
            SizedBox(height: isMobile ? 16 : 24),
            // Subtitle
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 40),
              child: Text(
                'Quality medical products delivered fast. From diagnostic equipment to first aid supplies, we have everything you need.',
                textAlign: TextAlign.center,
                style: AppTheme.bodyLarge.copyWith(
                  fontSize: isMobile ? 16 : 18,
                  color: AppTheme.textGray,
                ),
              ),
            ),
            SizedBox(height: isMobile ? 32 : 40),
            // CTA Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 16,
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
            ),
            SizedBox(height: isMobile ? 48 : 80),
          ],
        );
      },
    );
  }
}
