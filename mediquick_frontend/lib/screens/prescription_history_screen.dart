import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_theme.dart';
import '../config.dart';
import '../services/auth_service.dart';

class PrescriptionHistoryScreen extends StatefulWidget {
  const PrescriptionHistoryScreen({super.key});

  @override
  State<PrescriptionHistoryScreen> createState() =>
      _PrescriptionHistoryScreenState();
}

class _PrescriptionHistoryScreenState
    extends State<PrescriptionHistoryScreen> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _prescriptions = [];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        setState(() {
          _error = 'Please log in to view your prescription history.';
          _isLoading = false;
        });
        return;
      }
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/prescription/history'),
        headers: {'Authorization': 'Bearer $token'},
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _prescriptions = data['prescriptions'] as List;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = data['message'] as String? ?? 'Failed to load history';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error. Please check your connection.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.dashboardBg,
      appBar: AppBar(
        title: const Text('Prescription History',
            style: TextStyle(
                color: AppTheme.textDark, fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
        actions: [
          IconButton(
            onPressed: _fetchHistory,
            icon: const Icon(Icons.refresh, color: AppTheme.textDark),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.pushNamed(context, '/upload-prescription'),
        backgroundColor: AppTheme.dashboardGreen,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Upload',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.dashboardGreen),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppTheme.textGray, fontSize: 15, height: 1.5)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchHistory,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.dashboardGreen),
                child: const Text('Retry',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (_prescriptions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.dashboardGreen.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.receipt_long_outlined,
                    size: 64, color: AppTheme.dashboardGreen),
              ),
              const SizedBox(height: 20),
              const Text('No Prescriptions Yet',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark)),
              const SizedBox(height: 8),
              const Text(
                'Upload your first prescription to get started.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textGray, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _prescriptions.length,
      itemBuilder: (context, index) {
        final rx = _prescriptions[index] as Map<String, dynamic>;
        return _PrescriptionHistoryCard(prescription: rx);
      },
    );
  }
}

class _PrescriptionHistoryCard extends StatelessWidget {
  final Map<String, dynamic> prescription;

  const _PrescriptionHistoryCard({required this.prescription});

  @override
  Widget build(BuildContext context) {
    final bool verified = prescription['verified'] as bool? ?? false;
    final String status = prescription['status'] as String? ?? 'pending';
    final String imageUrl = prescription['imageUrl'] as String? ?? '';
    final List medicines = prescription['medicines'] as List? ?? [];
    final String createdAt = prescription['createdAt'] as String? ?? '';

    DateTime? date;
    try {
      date = DateTime.parse(createdAt).toLocal();
    } catch (_) {}
    final dateStr = date != null
        ? '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
        : 'Unknown date';

    Color statusColor;
    IconData statusIcon;
    String statusLabel;
    switch (status) {
      case 'processed':
        statusColor = Colors.green.shade600;
        statusIcon = Icons.check_circle_outline;
        statusLabel = 'Processed';
        break;
      case 'failed':
        statusColor = Colors.red.shade500;
        statusIcon = Icons.cancel_outlined;
        statusLabel = 'Failed';
        break;
      default:
        statusColor = Colors.orange.shade600;
        statusIcon = Icons.hourglass_top_rounded;
        statusLabel = 'Pending';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Prescription thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl.isNotEmpty
                  ? Image.network(imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholderIcon())
                  : _placeholderIcon(),
            ),
            const SizedBox(width: 14),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dateStr,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: AppTheme.textDark)),
                  const SizedBox(height: 4),
                  Text(
                    '${medicines.length} medicine${medicines.length == 1 ? '' : 's'} extracted',
                    style: const TextStyle(
                        color: AppTheme.textGray, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Row(children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(statusLabel,
                        style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12)),
                    if (!verified) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Unverified',
                            style: TextStyle(
                                fontSize: 10, color: Colors.orange)),
                      ),
                    ],
                  ]),
                ],
              ),
            ),

            // Arrow
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.textGray),
          ],
        ),
      ),
    );
  }

  Widget _placeholderIcon() => Container(
        width: 60,
        height: 60,
        color: Colors.grey.shade100,
        child: const Icon(Icons.receipt_long,
            color: Colors.grey, size: 28),
      );
}
