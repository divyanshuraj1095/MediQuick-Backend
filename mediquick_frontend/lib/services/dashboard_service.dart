import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../services/auth_service.dart';
import '../widgets/dashboard/recent_orders_card.dart';

/// Data class holding all computed dashboard statistics.
class DashboardData {
  final int totalOrders;
  final double monthlySpending;
  final String mostOrdered;
  final int mostOrderedCount;
  final List<RecentOrderItem> recentOrders;
  final Map<String, int> categoryCounts;

  const DashboardData({
    required this.totalOrders,
    required this.monthlySpending,
    required this.mostOrdered,
    required this.mostOrderedCount,
    required this.recentOrders,
    required this.categoryCounts,
  });

  factory DashboardData.empty() => const DashboardData(
        totalOrders: 0,
        monthlySpending: 0,
        mostOrdered: 'N/A',
        mostOrderedCount: 0,
        recentOrders: [],
        categoryCounts: {
          'Pain Relief': 0,
          'Antibiotics': 0,
          'Vitamins': 0,
          'Personal Care': 0,
        },
      );
}

class DashboardService {
  // Known category keywords for classifying medicines from their names.
  static const Map<String, List<String>> _categoryKeywords = {
    'Pain Relief': ['ibuprofen', 'aspirin', 'paracetamol', 'pain', 'analgesic', 'diclofenac'],
    'Antibiotics': ['amoxicillin', 'azithromycin', 'ciprofloxacin', 'antibiotic', 'penicillin', 'metronidazole'],
    'Vitamins': ['vitamin', 'zinc', 'calcium', 'iron', 'supplement', 'omega'],
    'Personal Care': ['shampoo', 'lotion', 'cream', 'soap', 'gel', 'sanitizer'],
  };

  static String _classifyMedicine(String name) {
    final lower = name.toLowerCase();
    for (final entry in _categoryKeywords.entries) {
      for (final keyword in entry.value) {
        if (lower.contains(keyword)) return entry.key;
      }
    }
    return 'Other';
  }

  /// Fetches all orders from the backend and computes dashboard statistics.
  static Future<DashboardData> fetchDashboardData() async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        return DashboardData.empty();
      }

      final response = await http.get(
        Uri.parse(Config.simpleMyOrdersUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) return DashboardData.empty();

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) return DashboardData.empty();

      final rawOrders = (data['orders'] as List<dynamic>?) ?? [];
      final totalOrders = rawOrders.length;

      // Monthly spending: sum totalAmount for orders created this calendar month.
      final now = DateTime.now();
      double monthlySpending = 0;
      for (final o in rawOrders) {
        final createdAt = DateTime.tryParse(o['createdAt'] ?? '');
        if (createdAt != null &&
            createdAt.year == now.year &&
            createdAt.month == now.month) {
          monthlySpending += ((o['totalAmount'] ?? 0) as num).toDouble();
        }
      }

      // Most ordered medicine by quantity across all orders.
      final Map<String, int> medicineQty = {};
      final Map<String, int> categoryCounts = {
        'Pain Relief': 0,
        'Antibiotics': 0,
        'Vitamins': 0,
        'Personal Care': 0,
      };

      for (final o in rawOrders) {
        final items = (o['items'] as List<dynamic>?) ?? [];
        for (final item in items) {
          // SimpleOrder stores name directly (flat), not nested under medicine
          final medName = (item['name'] ?? 'Unknown') as String;
          final qty = ((item['quantity'] ?? 1) as num).toInt();
          medicineQty[medName] = (medicineQty[medName] ?? 0) + qty;

          final cat = _classifyMedicine(medName);
          if (categoryCounts.containsKey(cat)) {
            categoryCounts[cat] = categoryCounts[cat]! + qty;
          }
        }
      }

      String mostOrdered = 'N/A';
      int mostOrderedCount = 0;
      if (medicineQty.isNotEmpty) {
        final top = medicineQty.entries.reduce((a, b) => a.value >= b.value ? a : b);
        mostOrdered = top.key;
        mostOrderedCount = top.value;
      }

      // Recent orders: last 4 orders (already sorted desc by backend).
      final List<RecentOrderItem> recentOrders = [];
      final recentRaw = rawOrders.take(4).toList();
      final itemColors = [
        const Color(0xFFE8F5E9),
        const Color(0xFFE3F2FD),
        const Color(0xFFFCE4EC),
        const Color(0xFFF3E5F5),
      ];

      for (int i = 0; i < recentRaw.length; i++) {
        final o = recentRaw[i];
        final items = (o['items'] as List<dynamic>?) ?? [];
        final firstMed = items.isNotEmpty
            ? (items[0]['name'] ?? 'Medicine') as String  // SimpleOrder uses flat name
            : 'Medicine';
        final medCategory = _classifyMedicine(firstMed);
        final totalAmt = ((o['totalAmount'] ?? 0) as num).toDouble();
        final createdAt = DateTime.tryParse(o['createdAt'] ?? '');
        final dateStr = createdAt != null
            ? '${_monthName(createdAt.month)} ${createdAt.day}, ${createdAt.year}'
            : 'Unknown date';


        recentOrders.add(RecentOrderItem(
          name: firstMed,
          category: medCategory,
          date: dateStr,
          price: '₹${totalAmt.toStringAsFixed(2)}',
          imageColor: itemColors[i % itemColors.length],
        ));
      }

      return DashboardData(
        totalOrders: totalOrders,
        monthlySpending: monthlySpending,
        mostOrdered: mostOrdered,
        mostOrderedCount: mostOrderedCount,
        recentOrders: recentOrders,
        categoryCounts: categoryCounts,
      );
    } catch (_) {
      return DashboardData.empty();
    }
  }

  static String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month.clamp(1, 12)];
  }
}
