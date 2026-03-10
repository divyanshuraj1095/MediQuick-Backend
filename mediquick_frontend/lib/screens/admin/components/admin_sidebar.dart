import 'package:flutter/material.dart';
import '../services/admin_auth_service.dart';
import '../../../theme/app_theme.dart';

class AdminSidebar extends StatefulWidget {
  final String activePage;
  final VoidCallback? onAddGodownsTap;
  final VoidCallback? onAddMedicinesTap;

  const AdminSidebar({
    super.key, 
    this.activePage = 'dashboard',
    this.onAddGodownsTap,
    this.onAddMedicinesTap,
  });

  @override
  State<AdminSidebar> createState() => _AdminSidebarState();
}

class _AdminSidebarState extends State<AdminSidebar> {
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
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MediQuick',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Text(
                      'Admin Panel',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.dashboardGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Navigation items
          _NavTile(
            icon: Icons.home_outlined,
            label: 'Home',
            isActive: widget.activePage == 'dashboard',
            onTap: () {
              if (widget.activePage != 'dashboard') {
                Navigator.of(context).pushReplacementNamed('/admin/dashboard');
              }
            },
          ),
          _NavTile(
            icon: Icons.warehouse_outlined,
            label: 'Add Godowns',
            isActive: widget.activePage == 'add_godowns',
            onTap: widget.onAddGodownsTap ?? () {},
          ),
          _NavTile(
            icon: Icons.medication_outlined,
            label: 'Add Medicines',
            isActive: widget.activePage == 'add_medicines',
            onTap: widget.onAddMedicinesTap ?? () {},
          ),
          
          const Spacer(),
          // User profile / logout
          _AdminProfileCard(
            onLogout: () async {
              await AdminAuthService.adminLogout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/admin/login', (_) => false);
              }
            },
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

class _AdminProfileCard extends StatefulWidget {
  final VoidCallback? onLogout;

  const _AdminProfileCard({this.onLogout});

  @override
  State<_AdminProfileCard> createState() => _AdminProfileCardState();
}

class _AdminProfileCardState extends State<_AdminProfileCard> {
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AdminAuthService.getAdminUser();
    if (mounted) setState(() => _user = user);
  }

  @override
  Widget build(BuildContext context) {
    final name = _user?['name'] ?? 'Admin';
    final email = _user?['email'] ?? '';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'A';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: PopupMenuButton<String>(
        offset: const Offset(0, -120),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onSelected: (value) {
          if (value == 'logout') {
            widget.onLogout?.call();
          }
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.dashboardGreen,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.textDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      email,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textGray),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'logout',
            child: ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text(
                'Logout',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
