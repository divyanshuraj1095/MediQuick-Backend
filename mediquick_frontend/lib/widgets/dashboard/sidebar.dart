import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';

enum NavItem { home, localAdvisor, uploadPrescription, profile }

class Sidebar extends StatefulWidget {
  final NavItem activeItem;
  final ValueChanged<NavItem>? onNavChanged;

  const Sidebar({
    super.key,
    this.activeItem = NavItem.home,
    this.onNavChanged,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo section
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
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
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Navigation items
          _NavTile(
            icon: Icons.home_outlined,
            label: 'Home',
            isActive: widget.activeItem == NavItem.home,
            onTap: () => widget.onNavChanged?.call(NavItem.home),
          ),
          _NavTile(
            icon: Icons.smart_toy_outlined,
            label: 'Local Advisor',
            isActive: widget.activeItem == NavItem.localAdvisor,
            onTap: () => Navigator.pushNamed(context, '/local-advisor'),
          ),
          _NavTile(
            icon: Icons.upload_file,
            label: 'Upload Prescription',
            isActive: widget.activeItem == NavItem.uploadPrescription,
            onTap: () => Navigator.pushNamed(context, '/upload-prescription'),
          ),
          const Spacer(),
          // User profile link
          _NavTile(
            icon: Icons.person_outline,
            label: 'Profile',
            isActive: widget.activeItem == NavItem.profile,
            onTap: () => Navigator.pushReplacementNamed(context, '/profile'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _NavTile({
    required this.icon,
    required this.label,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isActive ? AppTheme.dashboardGreen : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isActive ? Colors.white : AppTheme.textGray,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isActive ? Colors.white : AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// User profile logic moved to profile_page.dart
