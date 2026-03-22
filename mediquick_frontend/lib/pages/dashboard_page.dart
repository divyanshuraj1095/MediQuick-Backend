import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';
import '../widgets/dashboard/sidebar.dart';
import '../widgets/dashboard/cart_drawer.dart';
import '../widgets/dashboard/medicine_search_bar.dart';
import '../widgets/dashboard/cart_bottom_bar.dart';
import 'package:geolocator/geolocator.dart';
import '../config.dart';
import '../services/dashboard_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final NavItem _activeNav = NavItem.home;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  bool _isLoading = true;
  List<MedicineResult> _allMedicines = [];
  List<MedicineResult> _displayedMedicines = [];
  String _selectedCategory = '';
  String? _noServiceMessage;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'type': '', 'icon': Icons.grid_view},
    {'name': 'Painkillers', 'type': 'PAINKILLER', 'icon': Icons.healing},
    {'name': 'Antibiotics', 'type': 'ANTIBIOTIC', 'icon': Icons.coronavirus},
    {'name': 'Antacids', 'type': 'ANTACID', 'icon': Icons.medical_services},
    {'name': 'Vitamins', 'type': 'VITAMIN', 'icon': Icons.spa},
    {'name': 'Diabetes', 'type': 'DIABETES', 'icon': Icons.bloodtype},
    {'name': 'Heart', 'type': 'BLOOD_PRESSURE', 'icon': Icons.favorite},
  ];

  @override
  void initState() {
    super.initState();
    _fetchMedicines();
  }

  Future<void> _fetchMedicines() async {
    setState(() => _isLoading = true);
    try {
      final user = await AuthService.getUser();
      final queryParams = {'keyword': ''};
      bool hasLocation = false;
      
      if (user != null && user['location'] != null && user['location']['lat'] != null) {
         queryParams['lat'] = user['location']['lat'].toString();
         queryParams['lng'] = user['location']['lng'].toString();
         hasLocation = true;
      } else {
         try {
           bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
           if (serviceEnabled) {
             LocationPermission permission = await Geolocator.checkPermission();
             if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
             if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
                Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
                queryParams['lat'] = position.latitude.toString();
                queryParams['lng'] = position.longitude.toString();
                hasLocation = true;
                AuthService.updateLocation(position.latitude, position.longitude);
             }
           }
         } catch (_) {}
      }

      if (!hasLocation) {
         queryParams['lat'] = '0.0';
         queryParams['lng'] = '0.0';
      }

      final uri = Uri.parse(Config.medicineSearchUrl).replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: {'Content-Type': 'application/json'});
      if (response.statusCode == 200) {
         final data = jsonDecode(response.body);
         
         if (data['noService'] == true) {
             if (mounted) {
                setState(() {
                   _allMedicines = [];
                   _displayedMedicines = [];
                   _noServiceMessage = data['message'];
                   _isLoading = false;
                });
             }
             return;
         }

         if (data['success'] == true && data['medicines'] != null) {
            final list = (data['medicines'] as List).map((m) => MedicineResult.fromJson(m)).toList();
            if (mounted) {
              setState(() {
                 _allMedicines = list;
                 _noServiceMessage = null;
                 _filterMedicines(_selectedCategory);
                 _isLoading = false;
              });
            }
            return;
         }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  void _filterMedicines(String type) {
    setState(() {
      _selectedCategory = type;
      if (type.isEmpty) {
        _displayedMedicines = _allMedicines;
      } else {
        _displayedMedicines = _allMedicines.where((m) => m.type.toUpperCase() == type.toUpperCase()).toList();
      }
    });
  }

  void _refresh() {
    _fetchMedicines();
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
                if (!isDesktop) Navigator.pop(context);
                if (item == NavItem.profile) Navigator.pushReplacementNamed(context, '/profile');
                else if (item == NavItem.localAdvisor) Navigator.pushReplacementNamed(context, '/local-advisor');
                else if (item == NavItem.uploadPrescription) Navigator.pushReplacementNamed(context, '/upload-prescription');
              },
            ),
          ),
          body: SafeArea(
            child: Row(
              children: [
                if (isDesktop)
                  Sidebar(
                    activeItem: _activeNav,
                    onNavChanged: (item) {
                      if (item == NavItem.profile) Navigator.pushReplacementNamed(context, '/profile');
                      else if (item == NavItem.localAdvisor) Navigator.pushReplacementNamed(context, '/local-advisor');
                      else if (item == NavItem.uploadPrescription) Navigator.pushReplacementNamed(context, '/upload-prescription');
                    },
                  ),
                Expanded(
                  child: Column(
                    children: [
                      _TopHeader(
                        onRefresh: _refresh,
                        onMenuPressed: isDesktop ? null : () => _scaffoldKey.currentState?.openDrawer(),
                      ),
                      Expanded(
                        child: _isLoading 
                          ? const Center(child: CircularProgressIndicator(color: AppTheme.dashboardGreen))
                          : SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildCategoriesSection(),
                                  const SizedBox(height: 32),
                                  _buildMedicinesSection(),
                                ],
                              ),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          endDrawer: const Drawer(child: CartDrawer()),
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

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Shop by Category',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 90,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final isSelected = _selectedCategory == cat['type'];
              return GestureDetector(
                onTap: () => _filterMedicines(cat['type'] as String),
                child: Container(
                  width: 85,
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.dashboardGreen : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                    border: Border.all(
                      color: isSelected ? AppTheme.dashboardGreen : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        cat['icon'] as IconData,
                         color: isSelected ? Colors.white : AppTheme.dashboardGreen,
                         size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cat['name'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppTheme.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMedicinesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedCategory.isEmpty ? 'All Medicines' : '${_categories.firstWhere((c) => c['type'] == _selectedCategory)['name']}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            Text(
              '${_displayedMedicines.length} found',
              style: const TextStyle(fontSize: 14, color: AppTheme.textGray),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_noServiceMessage != null)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(_noServiceMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 16)),
            ),
          )
        else if (_displayedMedicines.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text('No medicines found in this category.', style: TextStyle(color: AppTheme.textGray, fontSize: 16)),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.65,
            ),
            itemCount: _displayedMedicines.length,
            itemBuilder: (context, index) {
              final med = _displayedMedicines[index];
              return _MedicineCard(medicine: med, onTap: () => Navigator.pushNamed(context, '/medicine', arguments: med.id));
            },
          ),
      ],
    );
  }
}

class _MedicineCard extends StatelessWidget {
  final MedicineResult medicine;
  final VoidCallback onTap;

  const _MedicineCard({required this.medicine, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Container(
                  width: double.infinity,
                  color: AppTheme.dashboardBg,
                  child: medicine.image.isNotEmpty
                    ? Image.network(medicine.image, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.medication, size: 48, color: AppTheme.dashboardGreen))
                    : const Icon(Icons.medication, size: 48, color: AppTheme.dashboardGreen),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medicine.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.dashboardGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          medicine.type,
                          style: const TextStyle(fontSize: 10, color: AppTheme.dashboardGreen, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    medicine.formattedPrice,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.dashboardGreen),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        String displayAddress = _address;
        final maxChars = isMobile ? 8 : 17;
        if (displayAddress.length > maxChars) {
          displayAddress = '${displayAddress.substring(0, maxChars)}...';
        }

        Widget menuAndLocation = Row(
          children: [
            if (widget.onMenuPressed != null) ...[
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed: widget.onMenuPressed,
                color: AppTheme.textDark,
              ),
            ],
            if (isMobile) const Spacer(),
            if (!isMobile) ...[
              const SizedBox(width: 8),
              Expanded(
                child: MedicineSearchBar(
                  onMedicineSelected: (medicine) {
                    Navigator.pushNamed(context, '/medicine', arguments: medicine.id);
                  },
                ),
              ),
              const SizedBox(width: 12),
            ],
            IconButton(
              onPressed: widget.onRefresh,
              tooltip: 'Refresh dashboard',
              icon: const Icon(Icons.refresh),
              color: AppTheme.dashboardGreen,
            ),
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
        );

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    menuAndLocation,
                    const SizedBox(height: 12),
                    MedicineSearchBar(
                      onMedicineSelected: (medicine) {
                        Navigator.pushNamed(context, '/medicine', arguments: medicine.id);
                      },
                    ),
                  ],
                )
              : menuAndLocation,
        );
      },
    );
  }
}
