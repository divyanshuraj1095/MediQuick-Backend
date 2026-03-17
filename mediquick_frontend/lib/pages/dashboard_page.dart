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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 800;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppTheme.dashboardBg,
          drawer: isDesktop ? null : Drawer(
            child: Sidebar(
              activeItem: _activeNav,
              onNavChanged: (item) {
                setState(() => _activeNav = item);
                if (!isDesktop) {
                  Navigator.pop(context); // Close the drawer
                }
              },
            ),
          ),
          body: Row(
            children: [
              if (isDesktop)
                Sidebar(
                  activeItem: _activeNav,
                  onNavChanged: (item) => setState(() => _activeNav = item),
                ),
              Expanded(
                child: Column(
                  children: [
                    _TopHeader(
                      onRefresh: _refresh,
                      onMenuPressed: isDesktop ? null : () => _scaffoldKey.currentState?.openDrawer(),
                    ),
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
      },
    );
  }
}

// ---------------------------------------------------------------------------

class _TopHeader extends StatefulWidget {
  final VoidCallback? onRefresh;
  final VoidCallback? onMenuPressed;

  const _TopHeader({this.onRefresh, this.onMenuPressed});

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
          if (widget.onMenuPressed != null) ...[
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: widget.onMenuPressed,
              color: AppTheme.textDark,
            ),
            const SizedBox(width: 8),
          ],
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

  void _showMonthlyHistoryDialog(BuildContext context) {
    final history = data.monthlyHistory;
    // Sort months descending (most recent first)
    final sortedKeys = history.keys.toList()
      ..sort((a, b) {
        // Parse 'Jan 2025' style labels for comparison
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
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
                    decoration: BoxDecoration(
                      color: AppTheme.dashboardGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.bar_chart_rounded, color: AppTheme.dashboardGreen, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Monthly Spending History',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textDark)),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, color: AppTheme.textGray),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text('Tap a month to see how much you spent',
                  style: TextStyle(fontSize: 12, color: AppTheme.textGray)),
              const SizedBox(height: 20),
              if (sortedKeys.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: Text('No spending history yet', style: TextStyle(color: AppTheme.textGray))),
                )
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
                      final isCurrentMonth = key == '${["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"][DateTime.now().month - 1]} ${DateTime.now().year}';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(key, style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: isCurrentMonth ? AppTheme.dashboardGreen : AppTheme.textDark,
                                      )),
                                      if (isCurrentMonth) ...[                          
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.dashboardGreen.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text('This month', style: TextStyle(fontSize: 10, color: AppTheme.dashboardGreen, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Text('₹${amount.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
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
