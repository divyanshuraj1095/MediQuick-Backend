import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';
import '../services/dashboard_service.dart';
import '../widgets/dashboard/sidebar.dart';
import '../widgets/dashboard/dashboard_stat_card.dart';
import '../widgets/dashboard/recent_orders_card.dart';
import '../widgets/dashboard/cart_drawer.dart';
import '../widgets/dashboard/medicine_search_bar.dart';
import '../widgets/dashboard/cart_bottom_bar.dart';
import 'package:geolocator/geolocator.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  NavItem _activeNav = NavItem.home;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late Future<DashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = DashboardService.fetchDashboardData();
  }

  void _refresh() {
    setState(() {
      _dashboardFuture = DashboardService.fetchDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppTheme.dashboardBg,
      body: Row(
        children: [
          Sidebar(
            activeItem: _activeNav,
            onNavChanged: (item) => setState(() => _activeNav = item),
          ),
          Expanded(
            child: Column(
              children: [
                _TopHeader(onRefresh: _refresh),
                Expanded(
                  child: FutureBuilder<DashboardData>(
                    future: _dashboardFuture,
                    builder: (context, snapshot) {
                      // Loading state
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: AppTheme.dashboardGreen,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Loading your dashboard...',
                                style: TextStyle(
                                  color: AppTheme.textGray,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Error / empty state fallback
                      final data = snapshot.data ?? DashboardData.empty();

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _WelcomeSection(),
                            const SizedBox(height: 24),
                            _StatCardsRow(data: data),
                            const SizedBox(height: 24),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isNarrow = constraints.maxWidth < 800;
                                if (isNarrow) {
                                  return Column(
                                    children: [
                                      RecentOrdersCard(
                                        items: data.recentOrders,
                                        onViewAll: () {},
                                      ),
                                      const SizedBox(height: 24),
                                      _CategoryOverviewCard(
                                        categoryCounts: data.categoryCounts,
                                      ),
                                    ],
                                  );
                                }
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: RecentOrdersCard(
                                        items: data.recentOrders,
                                        onViewAll: () {},
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      flex: 2,
                                      child: _CategoryOverviewCard(
                                        categoryCounts: data.categoryCounts,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
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
      endDrawer: const Drawer(
        child: CartDrawer(),
      ),
      floatingActionButton: Consumer<CartService>(
        builder: (context, cart, _) => FloatingActionButton(
          onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          backgroundColor: AppTheme.dashboardGreen,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.shopping_cart, color: Colors.white),
              if (cart.totalItems > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${cart.totalItems}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CartBottomBar(),
    );
  }
}

// ---------------------------------------------------------------------------

class _TopHeader extends StatefulWidget {
  final VoidCallback? onRefresh;

  const _TopHeader({this.onRefresh});

  @override
  State<_TopHeader> createState() => _TopHeaderState();
}

class _TopHeaderState extends State<_TopHeader> {
  String _address = 'Location';
  bool _isLoadingAddress = false;

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    final user = await AuthService.getUser();
    if (user != null) {
      if (mounted) {
        setState(() {
          if (user['location'] != null && user['location']['lat'] != null) {
            _address = '${user['location']['lat'].toStringAsFixed(4)}, ${user['location']['lng'].toStringAsFixed(4)}';
          } else if (user['address'] != null && user['address'].toString().isNotEmpty) {
            _address = user['address'];
          }
        });
      }
    }
  }

  Future<void> _updateAddress(String newAddress) async {
    if (newAddress.trim().isEmpty) return;
    setState(() => _isLoadingAddress = true);
    
    final result = await AuthService.updateAddress(newAddress.trim());
    
    if (mounted) {
      setState(() => _isLoadingAddress = false);
      if (result['success'] == true) {
        setState(() => _address = newAddress.trim());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address updated successfully'), backgroundColor: AppTheme.dashboardGreen),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to update address'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showManualAddressDialog() {
    final controller = TextEditingController(text: _address == 'Location' ? '' : _address);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Delivery Address'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Enter complete address...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textGray)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateAddress(controller.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dashboardGreen),
            child: const Text('Save Address'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCurrentLocation() async {
    if (!mounted) return;
    setState(() => _isLoadingAddress = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location mapping services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied, we cannot request permissions.');
      }

      // Permissions granted, get coords
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      // Send to Auth API
      final res = await AuthService.updateLocation(position.latitude, position.longitude);
      
      if (!mounted) return;
      if (res['success'] == true) {
        setState(() {
          _address = '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GPS Location updated successfully'), backgroundColor: AppTheme.dashboardGreen),
        );
      } else {
        throw Exception(res['message'] ?? 'Failed to update GPS location securely');
      }

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingAddress = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Truncate address for display if too long
    String displayAddress = _address;
    if (displayAddress.length > 20) {
      displayAddress = '${displayAddress.substring(0, 17)}...';
    }

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
          // ── Search Bar (flexible, takes all available space) ──
          Expanded(
            child: MedicineSearchBar(
              onMedicineSelected: (medicine) {
                Navigator.pushNamed(context, '/medicine', arguments: medicine.id);
              },
            ),
          ),
          const SizedBox(width: 12),
          // ── Refresh ──
          IconButton(
            onPressed: widget.onRefresh,
            tooltip: 'Refresh dashboard',
            icon: const Icon(Icons.refresh),
            color: AppTheme.dashboardGreen,
          ),
          const SizedBox(width: 4),
          // ── Location picker ──
          PopupMenuButton<String>(
            offset: const Offset(0, 48),
            onSelected: (value) {
              if (value == 'manual') {
                _showManualAddressDialog();
              } else if (value == 'current') {
                _handleCurrentLocation();
              }
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderGray),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isLoadingAddress)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.dashboardGreen),
                    )
                  else
                    const Icon(Icons.location_on_outlined, color: AppTheme.dashboardGreen, size: 18),
                  const SizedBox(width: 6),
                  Text(displayAddress, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, size: 18),
                ],
              ),
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'current',
                child: ListTile(
                  leading: Icon(Icons.my_location),
                  title: Text('Use Current Location'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'manual',
                child: ListTile(
                  leading: Icon(Icons.edit_location_alt),
                  title: Text('Set Manually'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _WelcomeSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: AuthService.getUser(),
      builder: (context, snapshot) {
        final name = snapshot.data?['name'] ?? 'there';
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
              "Here's your medicine activity overview",
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textGray,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------

class _StatCardsRow extends StatelessWidget {
  final DashboardData data;

  const _StatCardsRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final spendingStr = '₹${data.monthlySpending.toStringAsFixed(0)}';
    final mostOrderedSubtitle = data.mostOrderedCount > 0
        ? '${data.mostOrderedCount} units ordered'
        : 'No orders yet';

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
      DashboardStatCard(
        icon: Icons.currency_rupee,
        title: 'Monthly Spending',
        value: spendingStr,
        subtitle: 'This month in ₹',
      ),
      DashboardStatCard(
        icon: Icons.inventory_2,
        title: 'Order Status',
        value: data.totalOrders > 0 ? 'Active' : 'No Orders',
        subtitle: 'Track your orders',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 900;
        if (isNarrow) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: cards[0]),
                  const SizedBox(width: 16),
                  Expanded(child: cards[1]),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: cards[2]),
                  const SizedBox(width: 16),
                  Expanded(child: cards[3]),
                ],
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 16),
            Expanded(child: cards[1]),
            const SizedBox(width: 16),
            Expanded(child: cards[2]),
            const SizedBox(width: 16),
            Expanded(child: cards[3]),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------

class _CategoryOverviewCard extends StatelessWidget {
  final Map<String, int> categoryCounts;

  const _CategoryOverviewCard({required this.categoryCounts});

  @override
  Widget build(BuildContext context) {
    final labels = ['Pain Relief', 'Antibiotics', 'Vitamins', 'Personal Care'];
    final maxVal = categoryCounts.values.isEmpty
        ? 10.0
        : (categoryCounts.values.reduce((a, b) => a > b ? a : b).toDouble() + 5)
            .clamp(10.0, double.infinity);

    final barGroups = List.generate(labels.length, (i) {
      final count = (categoryCounts[labels[i]] ?? 0).toDouble();
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: count,
            color: AppTheme.dashboardGreen,
            width: 24,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      );
    });

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Units ordered by medicine type',
            style: TextStyle(fontSize: 12, color: AppTheme.textGray),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxVal,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final idx = group.x.toInt().clamp(0, labels.length - 1);
                      return BarTooltipItem(
                        '${labels[idx]}\n${rod.toY.toInt()} units',
                        const TextStyle(color: Colors.white, fontSize: 12),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt().clamp(0, labels.length - 1);
                        final shortLabels = ['Pain\nRelief', 'Anti-\nbiotics', 'Vitamins', 'Personal\nCare'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            shortLabels[idx],
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 9, color: AppTheme.textGray),
                          ),
                        );
                      },
                      reservedSize: 36,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10, color: AppTheme.textGray),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxVal / 4).clamp(1, double.infinity),
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppTheme.borderGray.withOpacity(0.5),
                    strokeWidth: 1,
                  ),
                ),
                barGroups: barGroups,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
