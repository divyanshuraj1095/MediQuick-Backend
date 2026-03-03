import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Top navigation bar widget
class AppNavbar extends StatelessWidget {
  final VoidCallback? onShopNowPressed;
  final VoidCallback? onLogout;

  const AppNavbar({
    super.key,
    this.onShopNowPressed,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Logo and App Name
          Row(
            children: [
              // Rounded green logo with "M"
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.dashboardGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'M',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
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
          // Right: Shop Now + Logout
          Row(
            children: [
              if (onLogout != null)
                IconButton(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout),
                  tooltip: 'Logout',
                ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onShopNowPressed ?? () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.dashboardGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Shop Now',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
