import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../main.dart';
import '../config.dart';
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
        final isMobile = constraints.maxWidth < 800;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppTheme.dashboardBg,
          appBar: isMobile
              ? AppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  iconTheme: const IconThemeData(color: AppTheme.textDark),
                  title: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.medical_services, color: AppTheme.dashboardGreen),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'MediQuick',
                          style: TextStyle(
                            color: AppTheme.textDark,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Center(child: _LocationPicker()),
                    ),
                  ],
                )
              : null,
          drawer: isMobile
              ? Drawer(
                  child: Sidebar(
                    activeItem: _activeNav,
                    onNavChanged: (item) {
                      setState(() => _activeNav = item);
                      Navigator.pop(context); // Close drawer after selection
                    },
                  ),
                )
              : null,
          endDrawer: const Drawer(
            child: CartDrawer(),
          ),
          body: Row(
            children: [
              if (!isMobile)
                Sidebar(
                  activeItem: _activeNav,
                  onNavChanged: (item) => setState(() => _activeNav = item),
                ),
              Expanded(
                child: Column(
                  children: [
                    if (!isMobile) _TopHeader(onRefresh: _refresh),
                    if (isMobile)
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: MedicineSearchBar(
                          onMedicineSelected: (medicine) {
                            Navigator.pushNamed(context, '/medicine', arguments: medicine.id);
                          },
                        ),
                      ),
                    Expanded(
                      child: _activeNav == NavItem.profile
                          ? _UserProfileView(future: _dashboardFuture, isMobile: isMobile)
                          : _activeNav == NavItem.home
                              ? const _HomeMedicinesView()
                              : const Center(child: Text('Page not found')),
                    ),
                  ],
                ),
              ),
            ],
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

class _UserProfileView extends StatelessWidget {
  final Future<DashboardData> future;
  final bool isMobile;

  const _UserProfileView({required this.future, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardData>(
      future: future,
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
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WelcomeSection(),
              SizedBox(height: isMobile ? 16 : 24),
              _StatCardsRow(data: data),
              SizedBox(height: isMobile ? 16 : 24),
              if (isMobile)
                Column(
                  children: [
                    RecentOrdersCard(
                      items: data.recentOrders,
                      onViewAll: () {},
                    ),
                    const SizedBox(height: 16),
                    _CategoryOverviewCard(
                      categoryCounts: data.categoryCounts,
                    ),
                  ],
                )
              else
                Row(
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
                ),
            ],
          ),
        );
      },
    );
  }
}

class _HomeMedicinesView extends StatefulWidget {
  const _HomeMedicinesView();

  @override
  State<_HomeMedicinesView> createState() => _HomeMedicinesViewState();
}

class _HomeMedicinesViewState extends State<_HomeMedicinesView> {
  bool _isLoading = true;
  List<MedicineResult> _medicines = [];
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  Future<void> _loadMedicines() async {
    try {
      final response = await http.get(Uri.parse(Config.allMedicinesUrl));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final list = data['medicines'] as List;
          setState(() {
            _medicines = list.map((m) => MedicineResult.fromJson(m)).toList();
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  List<String> get _categories {
    final cats = _medicines.map((m) => m.type).toSet().toList();
    cats.sort();
    return ['All', ...cats];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.dashboardGreen),
      );
    }
    if (_medicines.isEmpty) {
      return const Center(child: Text('No medicines available.'));
    }

    final filteredMedicines = _selectedCategory == 'All'
        ? _medicines
        : _medicines.where((m) => m.type == _selectedCategory).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Text(
            'All Medicines',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark),
          ),
        ),
        // Category Filter Row
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = category == _selectedCategory;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedCategory = category);
                    }
                  },
                  selectedColor: AppTheme.dashboardGreen,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textDark,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: isSelected ? AppTheme.dashboardGreen : AppTheme.borderGray,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: filteredMedicines.isEmpty
              ? const Center(
                  child: Text(
                    'No medicines found in this category.',
                    style: TextStyle(color: AppTheme.textGray),
                  ),
                )
              : GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisSpacing: 24,
              crossAxisSpacing: 24,
              childAspectRatio: 0.7,
            ),
            itemCount: filteredMedicines.length,
            itemBuilder: (context, index) {
              final med = filteredMedicines[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppTheme.authBorderRadius,
                  boxShadow: AppTheme.authShadow,
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        color: Colors.grey.shade100,
                        child: med.image.isNotEmpty
                            ? Image.network(med.image, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 64, color: AppTheme.textGray))
                            : const Icon(Icons.medication, size: 64, color: AppTheme.textGray),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            med.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            med.type, // Map UI to Type
                            style: const TextStyle(color: AppTheme.textGray, fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                med.formattedPrice,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.dashboardGreen, fontSize: 16),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.dashboardGreen.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.add_shopping_cart, color: AppTheme.dashboardGreen, size: 20),
                                  padding: const EdgeInsets.all(8),
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    context.read<CartService>().addItem(
                                          id: med.id,
                                          name: med.name,
                                          price: med.price,
                                          image: med.image,
                                          quantity: 1,
                                          requiresPrescription: med.prescriptionRequired,
                                        );
                                    scaffoldMessengerKey.currentState?.showSnackBar(
                                      SnackBar(
                                        content: Text('${med.name} added to cart'),
                                        backgroundColor: AppTheme.dashboardGreen,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
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
    if (user != null && user['address'] != null && user['address'].toString().isNotEmpty) {
      if (mounted) {
        setState(() {
          _address = user['address'];
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
          // ── Search Bar (flexible, takes all available space) ──
          Expanded(
            child: MedicineSearchBar(
              onMedicineSelected: (medicine) {
                Navigator.pushNamed(context, '/medicine', arguments: medicine.id);
              },
            ),
          ),
          const SizedBox(width: 16),
          // ── Location picker ──
          const _LocationPicker(),
        ],
      ),
    );
  }
}

// ─── Location Picker Widget ───────────────────────────────────────────────────

class _LocationPicker extends StatefulWidget {
  const _LocationPicker();

  @override
  State<_LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<_LocationPicker> {
  String _address = 'Location';
  bool _isLoadingAddress = false;

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    final user = await AuthService.getUser();
    if (user != null && user['address'] != null && user['address'].toString().isNotEmpty) {
      if (mounted) {
        setState(() {
          _address = user['address'];
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isLoadingAddress = true);
    
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
           messenger.showSnackBar(
             const SnackBar(content: Text('Location services are disabled. Please enable them.'), backgroundColor: Colors.red),
           );
           setState(() => _isLoadingAddress = false);
        }
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
             messenger.showSnackBar(
               const SnackBar(content: Text('Location permissions are denied.'), backgroundColor: Colors.red),
             );
             setState(() => _isLoadingAddress = false);
          }
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
           messenger.showSnackBar(
             const SnackBar(content: Text('Location permissions are permanently denied, we cannot request permissions.'), backgroundColor: Colors.red),
           );
           setState(() => _isLoadingAddress = false);
        }
        return;
      }

      // Request the current location with a timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      
      // Reverse Geocoding securely
      List<Placemark> placemarks = [];
      try {
        placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      } catch (e) {
        // Fallback for Web/Desktop if reverse geocoding is unsupported
        await _updateAddress('${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}');
        return;
      }
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        
        List<String> addressParts = [];
        if (place.subLocality != null && place.subLocality!.isNotEmpty) addressParts.add(place.subLocality!);
        if (place.locality != null && place.locality!.isNotEmpty) addressParts.add(place.locality!);
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) addressParts.add(place.administrativeArea!);
        
        // Sometimes only the name/street is available
        if (addressParts.isEmpty && place.street != null && place.street!.isNotEmpty) {
          addressParts.add(place.street!);
        }
        if (addressParts.isEmpty && place.name != null && place.name!.isNotEmpty) {
          addressParts.add(place.name!);
        }
        
        String fetchedAddress = addressParts.isNotEmpty 
            ? addressParts.join(', ') 
            : '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        
        await _updateAddress(fetchedAddress);
      } else {
        throw Exception("Could not find address from coordinates");
      }
      
    } catch (e) {
      if (mounted) {
         messenger.showSnackBar(
           SnackBar(content: Text('Failed to get location: ${e.toString()}'), backgroundColor: Colors.red),
         );
         setState(() => _isLoadingAddress = false);
      }
    }
  }

  Future<void> _updateAddress(String newAddress) async {
    final messenger = ScaffoldMessenger.of(context);
    if (newAddress.trim().isEmpty) return;
    setState(() => _isLoadingAddress = true);
    
    final result = await AuthService.updateAddress(newAddress.trim());
    
    if (mounted) {
      setState(() => _isLoadingAddress = false);
      if (result['success'] == true) {
        setState(() => _address = newAddress.trim());
        messenger.showSnackBar(
          const SnackBar(content: Text('Address updated successfully'), backgroundColor: AppTheme.dashboardGreen),
        );
      } else {
        messenger.showSnackBar(
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

  @override
  Widget build(BuildContext context) {
    String displayAddress = _address;
    if (displayAddress.length > 20) {
      displayAddress = '${displayAddress.substring(0, 17)}...';
    }

    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      onSelected: (value) {
        if (value == 'manual') {
          _showManualAddressDialog();
        } else if (value == 'current') {
          _getCurrentLocation();
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
            Text(displayAddress, style: const TextStyle(fontSize: 13, color: AppTheme.textDark)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 18, color: AppTheme.textDark),
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
