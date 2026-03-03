import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/feature_card.dart';
import '../../widgets/auth_form.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  bool _isSignIn = true;

  void _handleTabChange(bool isSignIn) {
    setState(() {
      _isSignIn = isSignIn;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGray,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 1024) {
              return _buildMobileLayout();
            } else {
              return _buildDesktopLayout();
            }
          },
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.medication,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'MediQuick',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkGreen,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/home'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Shop Now'),
                    ),
                  ],
                ),
                const SizedBox(height: 60),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Healthcare at',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.normal,
                        color: AppTheme.textDark,
                        height: 1.2,
                      ),
                    ),
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppTheme.primaryGradient.createShader(
                        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                      ),
                      child: const Text(
                        'Lightning Speed',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Get essential medicines delivered to your doorstep in minutes. '
                  'Fast, reliable, and secure.',
                  style: AppTheme.bodyLarge.copyWith(
                    fontSize: 18,
                    color: AppTheme.textGray,
                  ),
                ),
                const SizedBox(height: 48),
                const Row(
                  children: [
                    Expanded(child: StatCard(value: '30min', label: 'Delivery Time')),
                    SizedBox(width: 20),
                    Expanded(child: StatCard(value: '500+', label: 'Medicines')),
                    SizedBox(width: 20),
                    Expanded(child: StatCard(value: '50K+', label: 'Happy Users')),
                  ],
                ),
                const SizedBox(height: 48),
                const Row(
                  children: [
                    Expanded(
                      child: FeatureCard(
                        icon: Icons.flash_on,
                        title: 'Instant Delivery',
                        subtitle: 'Order now, receive in 30 minutes',
                        gradientColors: [AppTheme.primaryGreen, AppTheme.primaryTeal],
                      ),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: FeatureCard(
                        icon: Icons.verified_user,
                        title: '100% Authentic',
                        subtitle: 'Licensed & verified medicines',
                        gradientColors: [AppTheme.primaryTeal, Color(0xFF06B6D4)],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Row(
                  children: [
                    Expanded(
                      child: FeatureCard(
                        icon: Icons.favorite,
                        title: 'Expert Care',
                        subtitle: '24/7 pharmacist support',
                        gradientColors: [Color(0xFF06B6D4), AppTheme.primaryTeal],
                      ),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: FeatureCard(
                        icon: Icons.star,
                        title: 'Best Prices',
                        subtitle: 'Guaranteed lowest rates',
                        gradientColors: [AppTheme.primaryGreen, AppTheme.lightGreen],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _FooterItem(icon: Icons.lock, text: 'SSL Secured'),
                    SizedBox(width: 32),
                    _FooterItem(icon: Icons.verified_user, text: 'FDA Approved'),
                    SizedBox(width: 32),
                    _FooterItem(icon: Icons.star, text: '4.9/5 Rating'),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [
                  AppTheme.backgroundGray,
                  AppTheme.backgroundGray.withOpacity(0.95),
                ],
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: AuthForm(
                  isSignIn: _isSignIn,
                  onTabChanged: _handleTabChange,
                  onAuthSuccess: () {
                    Navigator.pushReplacementNamed(context, '/home');
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.medication, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'MediQuick',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkGreen,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Shop Now'),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Healthcare at',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.normal,
                  color: AppTheme.textDark,
                  height: 1.2,
                ),
              ),
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppTheme.primaryGradient.createShader(
                  Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                ),
                child: const Text(
                  'Lightning Speed',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Get essential medicines delivered to your doorstep in minutes. '
            'Fast, reliable, and secure.',
            style: AppTheme.bodyLarge.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 40),
          AuthForm(
            isSignIn: _isSignIn,
            onTabChanged: _handleTabChange,
            onAuthSuccess: () {
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),
          const SizedBox(height: 40),
          const Row(
            children: [
              Expanded(child: StatCard(value: '30min', label: 'Delivery Time')),
              SizedBox(width: 12),
              Expanded(child: StatCard(value: '500+', label: 'Medicines')),
              SizedBox(width: 12),
              Expanded(child: StatCard(value: '50K+', label: 'Happy Users')),
            ],
          ),
          const SizedBox(height: 32),
          const FeatureCard(
            icon: Icons.flash_on,
            title: 'Instant Delivery',
            subtitle: 'Order now, receive in 30 minutes',
            gradientColors: [AppTheme.primaryGreen, AppTheme.primaryTeal],
          ),
          const SizedBox(height: 16),
          const FeatureCard(
            icon: Icons.verified_user,
            title: '100% Authentic',
            subtitle: 'Licensed & verified medicines',
            gradientColors: [AppTheme.primaryTeal, Color(0xFF06B6D4)],
          ),
          const SizedBox(height: 16),
          const FeatureCard(
            icon: Icons.favorite,
            title: 'Expert Care',
            subtitle: '24/7 pharmacist support',
            gradientColors: [Color(0xFF06B6D4), AppTheme.primaryTeal],
          ),
          const SizedBox(height: 16),
          const FeatureCard(
            icon: Icons.star,
            title: 'Best Prices',
            subtitle: 'Guaranteed lowest rates',
            gradientColors: [AppTheme.primaryGreen, AppTheme.lightGreen],
          ),
          const SizedBox(height: 32),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _FooterItem(icon: Icons.lock, text: 'SSL Secured'),
              SizedBox(width: 24),
              _FooterItem(icon: Icons.verified_user, text: 'FDA Approved'),
              SizedBox(width: 24),
              _FooterItem(icon: Icons.star, text: '4.9/5'),
            ],
          ),
        ],
      ),
    );
  }
}

class _FooterItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FooterItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryGreen),
        const SizedBox(width: 6),
        Text(text, style: AppTheme.bodySmall.copyWith(fontSize: 12)),
      ],
    );
  }
}
