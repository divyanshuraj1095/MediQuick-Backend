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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isTiny = constraints.maxWidth < 400;

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 24,
            vertical: isMobile ? 12 : 16,
          ),
          decoration: BoxDecoration(
            color: AppTheme.cardWhite,
            boxShadow: AppTheme.authShadow,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Logo and App Name
              Row(
                children: [
                  // Rounded green logo with "M"
                  Container(
                    width: isMobile ? 40 : 48,
                    height: isMobile ? 40 : 48,
                    decoration: BoxDecoration(
                      color: AppTheme.dashboardGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'M',
                        style: TextStyle(
                          fontSize: isMobile ? 20 : 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (!isTiny) const SizedBox(width: 12),
                  if (!isTiny)
                    Text(
                      'MediQuick',
                      style: TextStyle(
                        fontSize: isMobile ? 20 : 24,
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
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  if (onLogout != null) const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onShopNowPressed ?? () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.dashboardGreen,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 24,
                        vertical: isMobile ? 8 : 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Shop Now',
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
