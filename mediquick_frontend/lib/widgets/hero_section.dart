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
        final iconSize = isMobile ? 80.0 : 120.0;
        final headingSize = isMobile ? 32.0 : 48.0;
        final subtitlePadding = isMobile ? 20.0 : 40.0;

        return Column(
          children: [
            SizedBox(height: isMobile ? 40 : 60),
            // Large circular icon
            Container(
              width: iconSize,
              height: iconSize,
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
                size: iconSize / 2,
                color: Colors.white,
              ),
            ),
            SizedBox(height: isMobile ? 24 : 40),
            // Main Heading
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16.0 : 0),
              child: Text(
                'Your Trusted Medical\nSupply Partner',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: headingSize,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Subtitle
            Padding(
              padding: EdgeInsets.symmetric(horizontal: subtitlePadding),
              child: Text(
                'Quality medical products delivered fast. From diagnostic equipment to first aid supplies, we have everything you need.',
                textAlign: TextAlign.center,
                style: AppTheme.bodyLarge.copyWith(
                  fontSize: isMobile ? 16 : 18,
                  color: AppTheme.textGray,
                ),
              ),
            ),
            const SizedBox(height: 40),
            // CTA Buttons
            if (isMobile)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPrimaryButton(),
                    const SizedBox(height: 16),
                    _buildSecondaryButton(),
                  ],
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildPrimaryButton(),
                  const SizedBox(width: 16),
                  _buildSecondaryButton(),
                ],
              ),
            SizedBox(height: isMobile ? 40 : 80),
          ],
        );
      },
    );
  }

  Widget _buildPrimaryButton() {
    return Container(
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
            child: const Center(
              child: Text(
                'Browse Products',
                style: AppTheme.buttonText,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton() {
    return OutlinedButton(
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
    );
  }
}
