import 'package:flutter/material.dart';
import '../services/admin_auth_service.dart';
import '../../../theme/app_theme.dart';

class AdminHeader extends StatefulWidget {
  final String title;

  const AdminHeader({super.key, required this.title});

  @override
  State<AdminHeader> createState() => _AdminHeaderState();
}

class _AdminHeaderState extends State<AdminHeader> {
  String _adminName = 'Admin';

  @override
  void initState() {
    super.initState();
    _loadAdminName();
  }

  Future<void> _loadAdminName() async {
    final user = await AdminAuthService.getAdminUser();
    if (user != null && mounted) {
      setState(() {
        _adminName = user['name'] ?? 'Admin';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const Spacer(),
          // Admin chip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.admin_panel_settings,
                    color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  _adminName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
