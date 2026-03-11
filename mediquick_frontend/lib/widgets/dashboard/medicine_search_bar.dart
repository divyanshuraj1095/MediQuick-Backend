import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config.dart';
import '../../theme/app_theme.dart';

// ─── Data Model ─────────────────────────────────────────────────────────────

class MedicineResult {
  final String id;
  final String name;
  final double price;
  final String image;
  final String type; // Replaced category with type to match backend schema types (e.g. Antibiotic)
  final bool prescriptionRequired;

  const MedicineResult({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    required this.type,
    required this.prescriptionRequired,
  });

  factory MedicineResult.fromJson(Map<String, dynamic> json) {
    return MedicineResult(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Unknown').toString(),
      price: ((json['price'] ?? 0) as num).toDouble(),
      image: (json['image'] ?? '').toString(),
      type: (json['type'] ?? 'OTHER').toString(),
      prescriptionRequired: (json['prescriptionRequired'] ?? false) == true,
    );
  }

  /// Format price as Indian Rupees e.g. ₹1,250.00
  String get formattedPrice {
    // Indian number formatting using manual approach
    final rupees = price.toStringAsFixed(2);
    final parts = rupees.split('.');
    final intPart = parts[0];
    final decPart = parts[1];

    if (intPart.length <= 3) return '₹$rupees';

    // Indian system: last 3 digits, then groups of 2
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
}

// ─── Search Service ──────────────────────────────────────────────────────────

class _MedicineSearchService {
  static Future<List<MedicineResult>> search(String keyword) async {
    if (keyword.trim().isEmpty) return [];
    try {
      final uri = Uri.parse(Config.medicineSearchUrl)
          .replace(queryParameters: {'keyword': keyword.trim()});
      final response = await http
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return [];
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] != true) return [];

      final list = (data['medicines'] as List<dynamic>?) ?? [];
      return list
          .take(12)
          .map((m) => MedicineResult.fromJson(m as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

// ─── Search Bar Widget ───────────────────────────────────────────────────────

class MedicineSearchBar extends StatefulWidget {
  /// Called when the user selects a medicine from results (Option A: navigate)
  final ValueChanged<MedicineResult>? onMedicineSelected;

  const MedicineSearchBar({super.key, this.onMedicineSelected});

  @override
  State<MedicineSearchBar> createState() => _MedicineSearchBarState();
}

class _MedicineSearchBarState extends State<MedicineSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  Timer? _debounce;
  List<MedicineResult> _results = [];
  bool _isLoading = false;
  bool _hasError = false;
  bool _showDropdown = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      // Small delay so taps on result items are registered first
      Future.delayed(const Duration(milliseconds: 200), _hideDropdown);
    }
  }

  void _onTextChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() {
        _results = [];
        _isLoading = false;
        _hasError = false;
      });
      _hideDropdown();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _doSearch(value));
  }

  Future<void> _doSearch(String keyword) async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    _showDropdownOverlay();

    try {
      final results = await _MedicineSearchService.search(keyword);
      if (!mounted) return;
      setState(() {
        _results = results;
        _isLoading = false;
      });
      _updateOverlay();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      _updateOverlay();
    }
  }

  // ── Overlay management ──────────────────────────────────────────────────

  void _showDropdownOverlay() {
    if (_overlayEntry != null) return;
    _overlayEntry = _buildOverlay();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _showDropdown = true);
  }

  void _updateOverlay() {
    _overlayEntry?.markNeedsBuild();
  }

  void _hideDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _showDropdown = false);
  }

  OverlayEntry _buildOverlay() {
    final renderBox = context.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? Size.zero;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 8), // More breathing room
          child: Material(
            elevation: 0, // Using manual shadow instead
            borderRadius: AppTheme.authBorderRadius,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppTheme.authBorderRadius,
                boxShadow: AppTheme.authShadow,
              ),
              child: _DropdownContent(
                isLoading: _isLoading,
                hasError: _hasError,
                results: _results,
                query: _controller.text,
                onSelect: (med) {
                  _controller.clear();
                  _hideDropdown();
                  _focusNode.unfocus();
                  widget.onMedicineSelected?.call(med);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        height: 56, // Increased height to resemble auth fields
        decoration: BoxDecoration(
          color: _showDropdown ? Colors.white : AppTheme.backgroundGray,
          borderRadius: BorderRadius.circular(16), // Slightly rounded like auth
          border: Border.all(
            color: _showDropdown
                ? AppTheme.primaryGreen
                : AppTheme.borderGray,
            width: _showDropdown ? 2 : 1, // Matches focused auth borders
          ),
          boxShadow: _showDropdown ? AppTheme.authShadow : [],
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(
              Icons.search,
              size: 20,
              color: _showDropdown ? AppTheme.dashboardGreen : AppTheme.textGray,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: _onTextChanged,
                onSubmitted: _doSearch,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textDark,
                ),
                decoration: const InputDecoration(
                  hintText: 'Search medicines...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textLightGray,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.dashboardGreen,
                  ),
                ),
              )
            else if (_controller.text.isNotEmpty)
              IconButton(
                onPressed: () {
                  _controller.clear();
                  _hideDropdown();
                  setState(() => _results = []);
                },
                icon: const Icon(Icons.close, size: 18, color: AppTheme.textGray),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              )
            else
              const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

// ─── Dropdown Content ────────────────────────────────────────────────────────

class _DropdownContent extends StatelessWidget {
  final bool isLoading;
  final bool hasError;
  final List<MedicineResult> results;
  final String query;
  final ValueChanged<MedicineResult> onSelect;

  const _DropdownContent({
    required this.isLoading,
    required this.hasError,
    required this.results,
    required this.query,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 380),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.dashboardGreen,
          ),
        ),
      );
    }

    if (hasError) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 18),
            SizedBox(width: 8),
            Text(
              'Could not connect to server',
              style: TextStyle(color: Colors.red, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (results.isEmpty && query.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            const Icon(Icons.search_off, color: AppTheme.textLightGray, size: 20),
            const SizedBox(width: 8),
            Text(
              'No medicines found for "$query"',
              style: const TextStyle(
                color: AppTheme.textGray,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      shrinkWrap: true,
      itemCount: results.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (context, i) => _ResultTile(
        medicine: results[i],
        onTap: () => onSelect(results[i]),
      ),
    );
  }
}

// ─── Result Tile ─────────────────────────────────────────────────────────────

class _ResultTile extends StatelessWidget {
  final MedicineResult medicine;
  final VoidCallback onTap;

  const _ResultTile({required this.medicine, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPrescription = medicine.prescriptionRequired;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.dashboardBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: medicine.image.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        medicine.image,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.medication,
                          color: AppTheme.dashboardGreen,
                          size: 24,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.medication,
                      color: AppTheme.dashboardGreen,
                      size: 24,
                    ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medicine.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.dashboardGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          medicine.type,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.dashboardGreen,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isPrescription)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Rx',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Price
            Text(
              medicine.formattedPrice,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.dashboardGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
