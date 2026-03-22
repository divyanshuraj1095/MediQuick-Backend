import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/dashboard_service.dart';
import '../widgets/dashboard/sidebar.dart';
import '../widgets/dashboard/dashboard_stat_card.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late Future<DashboardData> _dashboardFuture;
  Map<String, dynamic>? _user;
  bool _isSavingAddress = false;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = DashboardService.fetchDashboardData();
    _loadUser();
  }
  
  Future<void> _loadUser() async {
    final user = await AuthService.getUser();
    if (mounted) setState(() => _user = user);
  }

  void _refresh() {
    setState(() {
      _dashboardFuture = DashboardService.fetchDashboardData();
      _loadUser();
    });
  }

  Future<void> _handleLogout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/');
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 800;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppTheme.dashboardBg,
          drawer: isDesktop ? null : Drawer(
            child: Sidebar(
              activeItem: NavItem.profile,
              onNavChanged: (item) {
                if (!isDesktop) Navigator.pop(context);
                if (item == NavItem.home) {
                  Navigator.pushReplacementNamed(context, '/dashboard');
                } else if (item == NavItem.localAdvisor) {
                   Navigator.pushReplacementNamed(context, '/local-advisor');
                } else if (item == NavItem.uploadPrescription) {
                   Navigator.pushReplacementNamed(context, '/upload-prescription');
                }
              },
            ),
          ),
          body: Row(
            children: [
              if (isDesktop)
                Sidebar(
                  activeItem: NavItem.profile,
                  onNavChanged: (item) {
                    if (item == NavItem.home) {
                      Navigator.pushReplacementNamed(context, '/dashboard');
                    } else if (item == NavItem.localAdvisor) {
                       Navigator.pushReplacementNamed(context, '/local-advisor');
                    } else if (item == NavItem.uploadPrescription) {
                       Navigator.pushReplacementNamed(context, '/upload-prescription');
                    }
                  },
                ),
              Expanded(
                child: Column(
                  children: [
                    _TopHeader(
                      title: 'My Profile',
                      onMenuPressed: isDesktop ? null : () => _scaffoldKey.currentState?.openDrawer(),
                    ),
                    Expanded(
                      child: FutureBuilder<DashboardData>(
                        future: _dashboardFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: AppTheme.dashboardGreen));
                          }
                          final data = snapshot.data ?? DashboardData.empty();

                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _WelcomeSection(user: _user),
                                const SizedBox(height: 24),
                                _ProfileDetailsSection(
                                  user: _user,
                                  isSavingAddress: _isSavingAddress,
                                  onEditAddress: _showEditAddressDialog,
                                  onLogout: _handleLogout,
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Your Medical Activity',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _StatCardsRow(data: data),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TopHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onMenuPressed;

  const _TopHeader({required this.title, this.onMenuPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (onMenuPressed != null) ...[
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: onMenuPressed,
              color: AppTheme.textDark,
            ),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
        ],
      ),
    );
  }
}

class _WelcomeSection extends StatelessWidget {
  final Map<String, dynamic>? user;
  
  const _WelcomeSection({this.user});

  @override
  Widget build(BuildContext context) {
    final name = user?['name'] ?? 'there';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back, $name',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Here are your profile details and medical activity summary.",
          style: TextStyle(
            fontSize: 16,
            color: AppTheme.textGray,
          ),
        ),
      ],
    );
  }
}

class _ProfileDetailsSection extends StatelessWidget {
  final Map<String, dynamic>? user;
  final bool isSavingAddress;
  final VoidCallback onEditAddress;
  final VoidCallback onLogout;

  const _ProfileDetailsSection({
    this.user,
    required this.isSavingAddress,
    required this.onEditAddress,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final email = user?['email'] ?? 'Loading...';
    final address = user?['address']?.toString() ?? '';
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Account Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.email_outlined, color: AppTheme.dashboardGreen),
            title: const Text('Email Address'),
            subtitle: Text(email),
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.location_on_outlined, color: AppTheme.dashboardGreen),
            title: const Text('Delivery Address'),
            subtitle: isSavingAddress 
                ? const Text('Saving...', style: TextStyle(color: AppTheme.dashboardGreen, fontStyle: FontStyle.italic))
                : Text(address.isNotEmpty ? address : 'No address set. Tap to add.'),
            contentPadding: EdgeInsets.zero,
            trailing: IconButton(
              icon: const Icon(Icons.edit, color: AppTheme.textGray, size: 20),
              onPressed: onEditAddress,
            ),
            onTap: onEditAddress,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Log Out'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red.shade700,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _StatCardsRow extends StatelessWidget {
  final DashboardData data;

  const _StatCardsRow({required this.data});

  void _showMonthlyHistoryDialog(BuildContext context) {
    final history = data.monthlyHistory;
    // Sort months descending (most recent first)
    final sortedKeys = history.keys.toList()
      ..sort((a, b) {
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final aParts = a.split(' ');
        final bParts = b.split(' ');
        final aYear = int.tryParse(aParts.length > 1 ? aParts[1] : '0') ?? 0;
        final bYear = int.tryParse(bParts.length > 1 ? bParts[1] : '0') ?? 0;
        final aMonth = months.indexOf(aParts[0]);
        final bMonth = months.indexOf(bParts[0]);
        if (aYear != bYear) return bYear.compareTo(aYear);
        return bMonth.compareTo(aMonth);
      });

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppTheme.dashboardGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.bar_chart_rounded, color: AppTheme.dashboardGreen, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Monthly Spending History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textDark))),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, color: AppTheme.textGray)),
                ],
              ),
              const SizedBox(height: 20),
              if (sortedKeys.isEmpty)
                const Center(child: Text('No spending history yet', style: TextStyle(color: AppTheme.textGray)))
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: sortedKeys.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final key = sortedKeys[i];
                      final amount = history[key]!;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                            Text('₹${amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spendingStr = '₹${data.monthlySpending.toStringAsFixed(0)}';
    final mostOrderedSubtitle = data.mostOrderedCount > 0 ? '${data.mostOrderedCount} units ordered' : 'No orders yet';

    final cards = [
      DashboardStatCard(
        icon: Icons.shopping_cart,
        title: 'Total Orders',
        value: '${data.totalOrders}',
        subtitle: data.totalOrders == 1 ? '1 order placed' : '${data.totalOrders} orders placed',
      ),
      DashboardStatCard(
        icon: Icons.trending_up,
        title: 'Most Ordered',
        value: data.mostOrdered,
        subtitle: mostOrderedSubtitle,
      ),
      GestureDetector(
        onTap: () => _showMonthlyHistoryDialog(context),
        child: DashboardStatCard(
          icon: Icons.currency_rupee,
          title: 'Monthly Spending',
          value: spendingStr,
          subtitle: 'Tap to see history',
        ),
      ),
      DashboardStatCard(
        icon: Icons.inventory_2,
        title: 'Order Status',
        value: data.totalOrders > 0 ? 'Active' : 'No Orders',
        subtitle: 'Tap any order to track',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;
        final isVeryNarrow = constraints.maxWidth < 500;

        if (isVeryNarrow) {
          return Column(
            children: [
              SizedBox(width: double.infinity, child: cards[0]),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: cards[1]),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: cards[2]),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: cards[3]),
            ],
          );
        } else if (isNarrow) {
          return Column(
            children: [
              Row(children: [Expanded(child: cards[0]), const SizedBox(width: 16), Expanded(child: cards[1])]),
              const SizedBox(height: 16),
              Row(children: [Expanded(child: cards[2]), const SizedBox(width: 16), Expanded(child: cards[3])]),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: cards[0]), const SizedBox(width: 16),
            Expanded(child: cards[1]), const SizedBox(width: 16),
            Expanded(child: cards[2]), const SizedBox(width: 16),
            Expanded(child: cards[3]),
          ],
        );
      },
    );
  }
}
