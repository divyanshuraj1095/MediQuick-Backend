import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_theme.dart';
import '../config.dart';

class LocalAdvisorScreen extends StatefulWidget {
  const LocalAdvisorScreen({super.key});

  @override
  State<LocalAdvisorScreen> createState() => _LocalAdvisorScreenState();
}

class _LocalAdvisorScreenState extends State<LocalAdvisorScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isAnalysing = false;
  AdvisorResponse? _response;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 0.9, end: 1.0).animate(_pulseController);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _analyse() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isAnalysing = true;
      _response = null;
    });

    // Scroll down to show processing state
    await Future.delayed(const Duration(milliseconds: 100));
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }

    try {
      final res = await http.post(
        Uri.parse('${Config.apiUrl}/advisor/analyse'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': query}),
      );

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (!mounted) return;

      if (res.statusCode == 200 && data['success'] == true) {
        setState(() {
          _response = AdvisorResponse.fromJson(data);
          _isAnalysing = false;
        });
      } else {
        setState(() {
          _isAnalysing = false;
          _response = AdvisorResponse(
            isSerious: false,
            tips: [],
            medicines: [],
            precaution: '',
            suggestDoctor: false,
            rawText: data['message']?.toString() ?? 'Something went wrong.',
            error: true,
          );
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAnalysing = false;
        _response = AdvisorResponse(
          isSerious: false,
          tips: [],
          medicines: [],
          precaution: '',
          suggestDoctor: false,
          rawText: 'Network error. Please check your connection.',
          error: true,
        );
      });
    }

    // Scroll to results
    await Future.delayed(const Duration(milliseconds: 200));
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.dashboardBg,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.smart_toy_outlined, color: AppTheme.dashboardGreen, size: 22),
            SizedBox(width: 10),
            Text(
              'Local Health Advisor',
              style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E40AF),
                    Color(0xFF3B82F6),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.health_and_safety, color: Colors.white, size: 32),
                      SizedBox(width: 12),
                      Text(
                        'AI Health Advisor',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Describe your symptoms in any language. Our AI will suggest health tips, over-the-counter medicines, and tell you if you need to see a doctor.',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ⚠️ Disclaimer banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade300),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This is for informational purposes only. It does NOT replace professional medical advice. Always consult a qualified doctor for serious health concerns.',
                      style: TextStyle(
                        color: Color(0xFF92400E),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Input area
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Describe your symptoms or health concern:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _controller,
                    maxLines: 5,
                    minLines: 3,
                    enabled: !_isAnalysing,
                    decoration: InputDecoration(
                      hintText:
                          'e.g. "मुझे सिरदर्द और बुखार है" or "I have a sore throat and cough since 2 days" or "پیٹ میں درد"',
                      hintStyle: const TextStyle(color: AppTheme.textLightGray, fontSize: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.borderGray),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.borderGray),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: AppTheme.dashboardGreen, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isAnalysing ? null : _analyse,
                      icon: const Icon(Icons.search_rounded, color: Colors.white),
                      label: Text(
                        _isAnalysing ? 'Analysing...' : 'Analyse My Symptoms',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E40AF),
                        disabledBackgroundColor:
                            const Color(0xFF1E40AF).withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Processing indicator
            if (_isAnalysing) _buildProcessingState(),

            // Results
            if (_response != null && !_isAnalysing)
              _buildResults(_response!),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessingState() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E40AF).withOpacity(0.08),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.psychology_outlined,
                  color: Colors.white, size: 44),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Analysing your symptoms…',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Understanding language, matching conditions, preparing advice…',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textGray, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 16),
          const LinearProgressIndicator(
            color: Color(0xFF3B82F6),
            backgroundColor: Color(0xFFDBEAFE),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(AdvisorResponse r) {
    if (r.error) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
                child: Text(r.rawText,
                    style: const TextStyle(color: Colors.red))),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 🚨 Doctor Alert (if serious)
        if (r.suggestDoctor || r.isSerious) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.red.shade300, width: 1.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.local_hospital,
                      color: Colors.red.shade700, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚠️ Please See a Doctor',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Based on your symptoms, we strongly recommend consulting a qualified healthcare professional as soon as possible.',
                        style: TextStyle(
                            color: Color(0xFF7F1D1D), fontSize: 13, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ✅ Health Tips
        if (r.tips.isNotEmpty) ...[
          _SectionCard(
            icon: Icons.tips_and_updates_outlined,
            title: 'Health Tips & Home Care',
            color: const Color(0xFF059669),
            child: Column(
              children: r.tips
                  .map((tip) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle_outline,
                                color: Color(0xFF059669), size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(tip,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.textDark,
                                      height: 1.4)),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 💊 Medicine Suggestions
        if (r.medicines.isNotEmpty) ...[
          _SectionCard(
            icon: Icons.medication_outlined,
            title: 'Suggested OTC Medicines',
            color: const Color(0xFF2563EB),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...r.medicines.map((m) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.medication,
                              color: Color(0xFF2563EB), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: AppTheme.textDark)),
                                if (m.dosage.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(m.dosage,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textGray)),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),

                // ⚠️ Medicine precaution (always shown)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          color: Colors.orange, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Always read the label before use. Do not exceed the recommended dose. These are general suggestions — consult a pharmacist or doctor for personalised advice.',
                          style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF92400E),
                              height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 🛡️ Precaution (custom AI message)
        if (r.precaution.isNotEmpty) ...[
          _SectionCard(
            icon: Icons.shield_outlined,
            title: 'Precautions',
            color: Colors.purple.shade600,
            child: Text(
              r.precaution,
              style:
                  const TextStyle(fontSize: 14, color: AppTheme.textDark, height: 1.5),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Standard bottom disclaimer
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 16, color: AppTheme.textGray),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This advice is AI-generated and for informational purposes only. MediQuick is not responsible for medical decisions made based on this content. Always consult a licensed doctor.',
                  style: TextStyle(
                      fontSize: 11, color: AppTheme.textGray, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Search medicines button
        SizedBox(
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/dashboard'),
            icon: const Icon(Icons.search, color: AppTheme.dashboardGreen),
            label: const Text('Search Medicines on MediQuick',
                style: TextStyle(
                    color: AppTheme.dashboardGreen, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.dashboardGreen),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ─── Section Card ────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ─── Data Models ─────────────────────────────────────────────────────────────

class MedicineSuggestion {
  final String name;
  final String dosage;
  MedicineSuggestion({required this.name, required this.dosage});
}

class AdvisorResponse {
  final bool isSerious;
  final bool suggestDoctor;
  final List<String> tips;
  final List<MedicineSuggestion> medicines;
  final String precaution;
  final String rawText;
  final bool error;

  AdvisorResponse({
    required this.isSerious,
    required this.suggestDoctor,
    required this.tips,
    required this.medicines,
    required this.precaution,
    required this.rawText,
    this.error = false,
  });

  factory AdvisorResponse.fromJson(Map<String, dynamic> json) {
    final advice = json['advice'] as Map<String, dynamic>? ?? {};

    final tipsList = (advice['tips'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    final medsList = (advice['medicines'] as List?)
            ?.map((e) {
              final m = e as Map<String, dynamic>;
              return MedicineSuggestion(
                name: m['name']?.toString() ?? '',
                dosage: m['dosage']?.toString() ?? '',
              );
            })
            .where((m) => m.name.isNotEmpty)
            .toList() ??
        [];

    return AdvisorResponse(
      isSerious: advice['isSerious'] as bool? ?? false,
      suggestDoctor: advice['suggestDoctor'] as bool? ?? false,
      tips: tipsList,
      medicines: medsList,
      precaution: advice['precaution']?.toString() ?? '',
      rawText: '',
    );
  }
}
