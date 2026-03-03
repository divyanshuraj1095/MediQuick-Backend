import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_navbar.dart';
import '../../widgets/hero_section.dart';
import '../../widgets/home_feature_card.dart';
import '../../services/auth_service.dart';

/// Intermediate home screen after login/signup, before dashboard
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.dashboardBg,
      body: SafeArea(
        child: Column(
          children: [
            // Fixed Navbar
            AppNavbar(
              onShopNowPressed: () {
                Navigator.pushReplacementNamed(context, '/dashboard');
              },
              onLogout: () {
                AuthService.logout().then((_) {
                  if (!context.mounted) return;
                  Navigator.pushReplacementNamed(context, '/');
                });
              },
            ),
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Hero Section
                    HeroSection(
                      onBrowseProductsPressed: () {
                        Navigator.pushReplacementNamed(context, '/dashboard');
                      },
                      onLearnMorePressed: () {
                        Navigator.pushReplacementNamed(context, '/dashboard');
                      },
                    ),
                    // Why Choose MediQuick Section
                    _WhyChooseSection(),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Why Choose MediQuick?" section with feature cards
class _WhyChooseSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive: 4 cards in a row on desktop/tablet, 2x2 on smaller screens
        final isWideScreen = constraints.maxWidth > 768;
        final crossAxisCount = isWideScreen ? 4 : 2;
        final spacing = isWideScreen ? 20.0 : 16.0;
        final padding = isWideScreen ? 60.0 : 24.0;

        return Container(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Column(
            children: [
              // Section Heading
              const Text(
                'Why Choose MediQuick?',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              // Divider line
              Container(
                width: 100,
                height: 3,
                decoration: BoxDecoration(
                  color: AppTheme.dashboardGreen,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 48),
              // Feature Cards Grid
              _buildFeatureGrid(
                context: context,
                constraints: constraints,
                crossAxisCount: crossAxisCount,
                spacing: spacing,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeatureGrid({
    required BuildContext context,
    required BoxConstraints constraints,
    required int crossAxisCount,
    required double spacing,
  }) {
    final features = [
      {
        'icon': Icons.verified_user,
        'title': 'Quality Assured',
        'description': 'All products are certified and meet medical standards',
      },
      {
        'icon': Icons.local_shipping,
        'title': 'Fast Delivery',
        'description': 'Quick and reliable shipping to your doorstep',
      },
      {
        'icon': Icons.access_time,
        'title': '24/7 Support',
        'description': 'Round-the-clock customer service for your needs',
      },
      {
        'icon': Icons.inventory_2,
        'title': 'Wide Selection',
        'description': 'Comprehensive range of medical supplies',
      },
    ];

    if (crossAxisCount == 4) {
      // Desktop: 4 cards in a single row
      return Row(
        children: features
            .asMap()
            .entries
            .map((entry) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: entry.key < features.length - 1 ? spacing : 0,
                    ),
                    child: HomeFeatureCard(
                      icon: entry.value['icon'] as IconData,
                      title: entry.value['title'] as String,
                      description: entry.value['description'] as String,
                    ),
                  ),
                ))
            .toList(),
      );
    } else {
      // Mobile/Tablet: 2x2 grid using Wrap
      final cardWidth = (constraints.maxWidth - (24 * 2) - spacing) / 2;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: features
            .map((feature) => SizedBox(
                  width: cardWidth,
                  child: HomeFeatureCard(
                    icon: feature['icon'] as IconData,
                    title: feature['title'] as String,
                    description: feature['description'] as String,
                  ),
                ))
            .toList(),
      );
    }
  }
}
