import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';

enum NavItem { home, localAdvisor, uploadPrescription }

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
          // User profile card
          _UserProfileCard(
            onLogout: () async {
              await AuthService.logout();
              if (!context.mounted) return;
              Navigator.pushReplacementNamed(context, '/');
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

class _UserProfileCard extends StatefulWidget {
  final VoidCallback? onLogout;

  const _UserProfileCard({this.onLogout});

  @override
  State<_UserProfileCard> createState() => _UserProfileCardState();
}

class _UserProfileCardState extends State<_UserProfileCard> {
  Map<String, dynamic>? _user;
  bool _isSavingAddress = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthService.getUser();
    if (mounted) setState(() => _user = user);
  }

  Future<void> _showEditAddressDialog() async {
    final currentAddress = _user?['address']?.toString() ?? '';
    final controller = TextEditingController(text: currentAddress);

    final saved = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.location_on, color: AppTheme.dashboardGreen),
            SizedBox(width: 8),
            Text('Edit Delivery Address'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This address will be used as your default delivery location.',
              style: TextStyle(fontSize: 13, color: AppTheme.textGray),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Enter your full delivery address...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: AppTheme.dashboardGreen, width: 2),
                ),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: Icon(Icons.home_outlined,
                      color: AppTheme.dashboardGreen),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textGray)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dashboardGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon: const Icon(Icons.save_outlined, size: 18),
            label: const Text('Save Address'),
          ),
        ],
      ),
    );

    if (saved == null || saved.isEmpty || !mounted) return;

    setState(() => _isSavingAddress = true);
    final result = await AuthService.updateAddress(saved);
    if (!mounted) return;
    setState(() {
      _isSavingAddress = false;
      if (result['success'] == true) {
        _user = {...?_user, 'address': saved};
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['success'] == true
              ? 'Address updated successfully!'
              : result['message'] ?? 'Failed to update address',
        ),
        backgroundColor: result['success'] == true
            ? AppTheme.dashboardGreen
            : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = _user?['name'] ?? 'Loading...';
    final email = _user?['email'] ?? '';
    final address = _user?['address']?.toString() ?? '';
    final initials = _getInitials(name);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: PopupMenuButton<String>(
        offset: const Offset(0, -240),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onSelected: (value) {
          if (value == 'logout') {
            widget.onLogout?.call();
          } else if (value == 'edit_address') {
            _showEditAddressDialog();
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
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.dashboardGreen,
                    child: _isSavingAddress
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ],
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
                    if (address.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 11, color: AppTheme.dashboardGreen),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              address,
                              style: const TextStyle(
                                  fontSize: 11, color: AppTheme.dashboardGreen),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        email,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textGray),
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
          PopupMenuItem(
            value: 'edit_address',
            child: ListTile(
              leading: const Icon(Icons.location_on_outlined,
                  color: AppTheme.dashboardGreen),
              title: const Text('Edit Address'),
              subtitle: address.isNotEmpty
                  ? Text(
                      address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 11, color: AppTheme.textGray),
                    )
                  : const Text('No address set',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange,
                          fontStyle: FontStyle.italic)),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: 'logout',
            child: ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text(
                'Logout',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
