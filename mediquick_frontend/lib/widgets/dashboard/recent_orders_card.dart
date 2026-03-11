import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/dashboard_service.dart';

class RecentOrdersCard extends StatelessWidget {
  final List<RecentOrderItem> items;
  final VoidCallback? onViewAll;

  const RecentOrdersCard({
    super.key,
    this.items = const [],
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Orders',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              TextButton(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.dashboardGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: const Text('View All Orders'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            const SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 56,
                      color: AppTheme.textLightGray,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No recent orders',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textGray,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Your order history will appear here',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textLightGray,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 320,
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 24),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _OrderListItem(
                    item: item,
                    onTap: () => _showOrderStatusDialog(context, item),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _showOrderStatusDialog(BuildContext context, RecentOrderItem item) {
    // Determine status stage based on time elapsed since order was placed
    final now = DateTime.now();
    final orderTime = item.createdAt ?? now.subtract(const Duration(hours: 1));
    final elapsed = now.difference(orderTime);

    // Stage logic: simulated since there's no delivery system
    // < 2 min  → Picked Up only
    // 2–10 min → In Transit
    // > 10 min → Delivered
    int currentStage;
    if (elapsed.inMinutes < 2) {
      currentStage = 0; // Picked Up
    } else if (elapsed.inMinutes < 10) {
      currentStage = 1; // In Transit
    } else {
      currentStage = 2; // Delivered
    }

    final stages = [
      {'label': 'Picked Up', 'icon': Icons.inventory_2_rounded, 'desc': 'Order has been picked up from the godown'},
      {'label': 'In Transit', 'icon': Icons.local_shipping_rounded, 'desc': 'Your order is on the way'},
      {'label': 'Delivered', 'icon': Icons.check_circle_rounded, 'desc': 'Order delivered to your address'},
    ];

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
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.dashboardGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.track_changes, color: AppTheme.dashboardGreen, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Order Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textDark)),
                        Text(item.name, style: const TextStyle(fontSize: 13, color: AppTheme.textGray)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, color: AppTheme.textGray),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Ordered on: ${item.date}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textGray)),
              const SizedBox(height: 24),
              // Timeline
              ...List.generate(stages.length, (i) {
                final done = i <= currentStage;
                final isLast = i == stages.length - 1;
                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon + connector
                        Column(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: done
                                    ? AppTheme.dashboardGreen
                                    : AppTheme.borderGray,
                              ),
                              child: Icon(
                                stages[i]['icon'] as IconData,
                                color: done ? Colors.white : AppTheme.textLightGray,
                                size: 20,
                              ),
                            ),
                            if (!isLast)
                              Container(
                                width: 2,
                                height: 40,
                                color: i < currentStage
                                    ? AppTheme.dashboardGreen
                                    : AppTheme.borderGray,
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  stages[i]['label'] as String,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: done ? AppTheme.textDark : AppTheme.textLightGray,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  stages[i]['desc'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: done ? AppTheme.textGray : AppTheme.textLightGray,
                                  ),
                                ),
                                if (!isLast) const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),
                        if (done && i == currentStage)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.dashboardGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Current',
                                style: TextStyle(color: AppTheme.dashboardGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  ],
                );
              }),
              const SizedBox(height: 16),
              if (item.items.isNotEmpty) ...[
                const Divider(),
                const SizedBox(height: 8),
                const Text('Order Items', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                ...item.items.map((it) {
                  final name = (it['name'] ?? 'Unknown') as String;
                  final qty = (it['quantity'] ?? 1) as num;
                  final price = (it['price'] ?? 0) as num;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.medication, size: 16, color: AppTheme.dashboardGreen),
                        const SizedBox(width: 8),
                        Expanded(child: Text(name, style: const TextStyle(fontSize: 13))),
                        Text('x$qty', style: const TextStyle(fontSize: 12, color: AppTheme.textGray)),
                        const SizedBox(width: 8),
                        Text('₹${price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderListItem extends StatelessWidget {
  final RecentOrderItem item;
  final VoidCallback? onTap;

  const _OrderListItem({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: item.imageColor ?? AppTheme.cardGradient.colors.first,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.medication,
                color: AppTheme.dashboardGreen,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.dashboardBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.category,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.dashboardGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.date,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textGray,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.price,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.dashboardGreen,
                  ),
                ),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Icon(Icons.touch_app_rounded, size: 12, color: AppTheme.textLightGray),
                    SizedBox(width: 2),
                    Text('Track', style: TextStyle(fontSize: 11, color: AppTheme.textLightGray)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
