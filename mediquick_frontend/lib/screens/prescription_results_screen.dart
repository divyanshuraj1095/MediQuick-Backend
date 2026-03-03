import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cart_service.dart';
import '../theme/app_theme.dart';
import '../widgets/dashboard/cart_bottom_bar.dart';

class PrescriptionResultsScreen extends StatefulWidget {
  final Map<String, dynamic> responseData;

  const PrescriptionResultsScreen({super.key, required this.responseData});

  @override
  State<PrescriptionResultsScreen> createState() =>
      _PrescriptionResultsScreenState();
}

class _PrescriptionResultsScreenState
    extends State<PrescriptionResultsScreen> {
  @override
  Widget build(BuildContext context) {
    final bool verified = widget.responseData['verified'] ?? false;
    final List extractedList = widget.responseData['extractedList'] ?? [];
    final List searchResults = widget.responseData['searchResults'] ?? [];

    return Scaffold(
      backgroundColor: AppTheme.dashboardBg,
      appBar: AppBar(
        title: const Text('Prescription Results',
            style: TextStyle(
                color: AppTheme.textDark, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
        actions: [
          // Cart count badge
          Consumer<CartService>(
            builder: (context, cart, _) {
              if (cart.totalItems == 0) return const SizedBox();
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Stack(
                  alignment: Alignment.topRight,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart_outlined,
                          color: AppTheme.textDark),
                      onPressed: () => Navigator.pushNamed(context, '/cart'),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                            color: AppTheme.dashboardGreen,
                            shape: BoxShape.circle),
                        child: Text('${cart.totalItems}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: verified
          ? _buildResultsList(extractedList, searchResults)
          : _buildUnverifiedState(),
      bottomNavigationBar: const CartBottomBar(),
    );
  }

  Widget _buildUnverifiedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.warning_amber_rounded,
                  size: 64, color: Colors.orange.shade500),
            ),
            const SizedBox(height: 24),
            const Text(
              'Prescription Needs Manual Verification',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark),
            ),
            const SizedBox(height: 12),
            const Text(
              'We could not extract any medicines from this file. Please ensure the image is clear and well-lit, then try again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppTheme.textGray, height: 1.5),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Row(children: [
                Icon(Icons.hourglass_top_rounded,
                    color: Colors.orange, size: 16),
                SizedBox(width: 8),
                Text('Awaiting pharmacist approval',
                    style: TextStyle(
                        color: Colors.orange, fontWeight: FontWeight.w600)),
              ]),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Try Again',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.dashboardGreen,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(List extracted, List searchResults) {
    if (extracted.isEmpty) {
      return const Center(
        child: Text('No medicines could be identified.',
            style: TextStyle(color: AppTheme.textGray)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: extracted.length,
      itemBuilder: (context, index) {
        final medItem = extracted[index] as Map<String, dynamic>;
        final String extractedName = medItem['name'] as String? ?? 'Unknown';
        final String dosage = medItem['dosage'] as String? ?? '';
        final int extractedQty =
            (medItem['quantity'] is int)
                ? medItem['quantity'] as int
                : int.tryParse(medItem['quantity'].toString()) ?? 1;
        final int confidence = medItem['confidence'] as int? ?? 0;

        Map<String, dynamic>? bestMatch;
        if (index < searchResults.length) {
          final sr = searchResults[index] as Map<String, dynamic>;
          final meds = sr['medicines'] as List?;
          if (meds != null && meds.isNotEmpty) {
            bestMatch = meds[0] as Map<String, dynamic>;
          }
        }

        return _MedicineResultCard(
          extractedName: extractedName,
          dosage: dosage,
          extractedQty: extractedQty,
          confidence: confidence,
          bestMatch: bestMatch,
        );
      },
    );
  }
}

class _MedicineResultCard extends StatelessWidget {
  final String extractedName;
  final String dosage;
  final int extractedQty;
  final int confidence;
  final Map<String, dynamic>? bestMatch;

  const _MedicineResultCard({
    required this.extractedName,
    required this.dosage,
    required this.extractedQty,
    required this.confidence,
    required this.bestMatch,
  });

  Color get _confidenceColor {
    if (confidence >= 80) return Colors.green.shade600;
    if (confidence >= 50) return Colors.orange.shade600;
    return Colors.red.shade500;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          // Extracted text header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.document_scanner_outlined,
                    size: 16, color: AppTheme.textGray),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dosage.isNotEmpty
                        ? '$extractedName — $dosage'
                        : extractedName,
                    style: const TextStyle(
                        color: AppTheme.textGray,
                        fontSize: 12,
                        fontStyle: FontStyle.italic),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                // Confidence chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _confidenceColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _confidenceColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    '$confidence% match',
                    style: TextStyle(
                        color: _confidenceColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Product content
          Padding(
            padding: const EdgeInsets.all(16),
            child: bestMatch != null
                ? _buildMatchedProduct(context, bestMatch!, extractedQty)
                : _buildNoMatchFound(context),
          ),
        ],
      ),
    );
  }

  Widget _buildNoMatchFound(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.search_off, color: Colors.red.shade400, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No matching product found',
                      style: TextStyle(
                          color: AppTheme.textDark,
                          fontWeight: FontWeight.w600)),
                  SizedBox(height: 2),
                  Text('Try searching manually for this medicine',
                      style: TextStyle(color: AppTheme.textGray, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context, '/home', (route) => false);
            },
            icon: const Icon(Icons.search, size: 18),
            label: Text('Search for "$extractedName"'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.dashboardGreen,
              side: const BorderSide(color: AppTheme.dashboardGreen),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMatchedProduct(
      BuildContext context, Map<String, dynamic> product, int initialQty) {
    final String id = product['_id'] as String? ?? '';
    final String name = product['name'] as String? ?? 'Unknown';
    final num priceNum = product['price'] as num? ?? 0;
    final int stock = product['stock'] as int? ?? 0;

    String imageUrl = 'https://via.placeholder.com/100x100?text=💊';
    final images = product['images'] as List?;
    if (images != null && images.isNotEmpty) {
      final firstImage = images[0] as Map<String, dynamic>?;
      if (firstImage != null && firstImage['url'] != null) {
        imageUrl = firstImage['url'] as String;
      }
    }

    return Consumer<CartService>(
      builder: (context, cart, _) {
        final cartItem = cart.items.where((i) => i.id == id).firstOrNull;
        final currentQty = cartItem?.quantity ?? 0;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                imageUrl,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 72,
                  height: 72,
                  color: Colors.grey.shade100,
                  child: const Icon(Icons.medication_rounded,
                      color: Colors.grey, size: 32),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Product info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppTheme.textDark),
                      maxLines: 2),
                  const SizedBox(height: 4),
                  Text(
                    '₹${priceNum.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.dashboardGreen,
                        fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: stock > 0
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          stock > 0 ? '✓ In Stock ($stock)' : '✗ Out of Stock',
                          style: TextStyle(
                              color: stock > 0
                                  ? Colors.green.shade700
                                  : Colors.red.shade700,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Add/Qty controls
            if (stock > 0)
              currentQty > 0
                  ? Column(
                      children: [
                        SizedBox(
                          height: 36,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _QtyButton(
                                icon: Icons.remove,
                                onTap: () =>
                                    cart.updateQuantity(id, currentQty - 1),
                              ),
                              Container(
                                width: 32,
                                alignment: Alignment.center,
                                child: Text('$currentQty',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15)),
                              ),
                              _QtyButton(
                                icon: Icons.add,
                                onTap: () =>
                                    cart.updateQuantity(id, currentQty + 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ElevatedButton(
                      onPressed: () {
                        cart.addItem(
                          id: id,
                          name: name,
                          price: priceNum.toDouble(),
                          image: imageUrl,
                          quantity: initialQty.clamp(1, stock),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.dashboardGreen,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Add',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
          ],
        );
      },
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: AppTheme.dashboardGreen.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: AppTheme.dashboardGreen),
      ),
    );
  }
}
