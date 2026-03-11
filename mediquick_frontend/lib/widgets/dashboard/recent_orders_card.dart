import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class RecentOrderItem {
  final String name;
  final String category;
  final String date;
  final String price;
  final Color? imageColor;

  const RecentOrderItem({
    required this.name,
    required this.category,
    required this.date,
    required this.price,
    this.imageColor,
  });
}

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
        borderRadius: AppTheme.authBorderRadius,
        boxShadow: AppTheme.authShadow,
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
                  return _OrderListItem(item: item);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderListItem extends StatelessWidget {
  final RecentOrderItem item;

  const _OrderListItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
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
        Text(
          item.price,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.dashboardGreen,
          ),
        ),
      ],
    );
  }
}
