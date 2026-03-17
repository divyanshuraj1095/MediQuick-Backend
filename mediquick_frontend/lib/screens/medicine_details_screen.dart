import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../config.dart';
import '../theme/app_theme.dart';
import '../services/cart_service.dart';

class MedicineDetailsScreen extends StatefulWidget {
  const MedicineDetailsScreen({super.key});

  @override
  State<MedicineDetailsScreen> createState() => _MedicineDetailsScreenState();
}

class _MedicineDetailsScreenState extends State<MedicineDetailsScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  Map<String, dynamic>? _medicineData;
  int _quantity = 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isLoading && _medicineData == null && !_hasError) {
      final String? medicineId = ModalRoute.of(context)!.settings.arguments as String?;
      if (medicineId != null) {
        _fetchMedicineDetails(medicineId);
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _fetchMedicineDetails(String id) async {
    try {
      final response = await http.get(
        Uri.parse(Config.medicineDetailsUrl(id)),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['medicine'] != null) {
          setState(() {
            _medicineData = data['medicine'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _hasError = true;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  void _increaseQuantity() => setState(() => _quantity++);
  void _decreaseQuantity() => setState(() => _quantity > 1 ? _quantity-- : null);

  void _addToCart() {
    if (_medicineData == null) return;
    
    final med = _medicineData!;
    final cartService = context.read<CartService>();
    final rxRequired = med['prescriptionRequired'] ?? false;
    
    cartService.addItem(
      id: med['_id'] ?? '',
      name: med['name'] ?? 'Unknown',
      price: (med['price'] ?? 0).toDouble(),
      image: med['image'] ?? '',
      quantity: _quantity,
      requiresPrescription: rxRequired == true,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $_quantity ${med['name']} to cart'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.dashboardGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatPrice(double price) {
    final rupees = price.toStringAsFixed(2);
    final parts = rupees.split('.');
    final intPart = parts[0];
    final decPart = parts[1];

    if (intPart.length <= 3) return '₹$rupees';

    final last3 = intPart.substring(intPart.length - 3);
    var remaining = intPart.substring(0, intPart.length - 3);
    final groups = <String>[];
    while (remaining.length > 2) {
      groups.insert(0, remaining.substring(remaining.length - 2));
      remaining = remaining.substring(0, remaining.length - 2);
    }
    if (remaining.isNotEmpty) groups.insert(0, remaining);
    final formatted = '${groups.join(',')},$last3.$decPart';
    return '₹$formatted';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.dashboardBg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppTheme.textDark),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.dashboardGreen),
        ),
      );
    }

    if (_hasError || _medicineData == null) {
      return Scaffold(
        backgroundColor: AppTheme.dashboardBg,
        appBar: AppBar(
          title: const Text('Error', style: TextStyle(color: AppTheme.textDark)),
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: AppTheme.textDark),
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Could not load medicine details', style: TextStyle(color: AppTheme.textDark)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dashboardGreen),
                child: const Text('Go Back'),
              )
            ],
          ),
        ),
      );
    }

    final med = _medicineData!;
    final name = med['name'] ?? 'Unknown Medicine';
    final manufacturer = med['manufacturer'] ?? 'Unknown Manufacturer';
    final description = med['description'] ?? 'No description available.';
    final composition = (med['composition'] as List<dynamic>?)?.join(', ') ?? 'N/A';
    final price = (med['price'] ?? 0).toDouble();
    final mrp = (med['mrp'] ?? price).toDouble();
    final discount = (med['discount'] ?? 0).toDouble();
    final inStock = med['inStock'] ?? true;
    final rxRequired = med['prescriptionRequired'] ?? false;
    final imageUrl = med['image'] ?? '';

    return Scaffold(
      backgroundColor: AppTheme.dashboardBg,
      appBar: AppBar(
        title: const Text('Details', style: TextStyle(color: AppTheme.textDark)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => Navigator.pushNamed(context, '/cart'),
          )
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Price', style: TextStyle(color: AppTheme.textGray, fontSize: 12)),
                  Text(
                    _formatPrice(price * _quantity),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textDark),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: ElevatedButton(
                  onPressed: inStock ? _addToCart : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.dashboardGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    inStock ? 'Add to Cart' : 'Out of Stock',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;

          final imageSection = Container(
            width: double.infinity,
            height: isWide ? 400 : 250,
            color: Colors.white,
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.medication, size: 80, color: AppTheme.dashboardGreen),
                  )
                : const Icon(Icons.medication, size: 80, color: AppTheme.dashboardGreen),
          );

          final detailsSection = Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (rxRequired) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.assignment, size: 14, color: Colors.orange),
                        SizedBox(width: 4),
                        Text(
                          'Prescription Required',
                          style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  name,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
                const SizedBox(height: 4),
                Text(
                  'by $manufacturer',
                  style: const TextStyle(fontSize: 14, color: AppTheme.textGray),
                ),
                const SizedBox(height: 16),
                
                // Price Tag
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatPrice(price),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.dashboardGreen),
                    ),
                    const SizedBox(width: 8),
                    if (mrp > price) ...[
                      Text(
                        _formatPrice(mrp),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textLightGray,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$discount% OFF',
                          style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      )
                    ]
                  ],
                ),
                const SizedBox(height: 24),
                
                // Quantity
                const Text('Quantity', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildQuantityBtn(Icons.remove, _decreaseQuantity),
                    Container(
                      width: 48,
                      alignment: Alignment.center,
                      child: Text(
                        _quantity.toString(),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    _buildQuantityBtn(Icons.add, _increaseQuantity),
                  ],
                ),
                
                const SizedBox(height: 24),
                const Divider(color: AppTheme.borderGray),
                const SizedBox(height: 16),
                
                // Composition
                const Text('Composition', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                const SizedBox(height: 8),
                Text(composition, style: const TextStyle(fontSize: 14, color: AppTheme.textGray)),
                
                const SizedBox(height: 24),
                
                // Description
                const Text('Description', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(fontSize: 14, color: AppTheme.textGray, height: 1.5),
                ),
                
                const SizedBox(height: 48), // Bottom padding
              ],
            ),
          );

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: SingleChildScrollView(child: imageSection)),
                Expanded(child: SingleChildScrollView(child: detailsSection)),
              ],
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                imageSection,
                detailsSection,
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuantityBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.backgroundGray,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderGray),
        ),
        child: Icon(icon, size: 20, color: AppTheme.textDark),
      ),
    );
  }
}
