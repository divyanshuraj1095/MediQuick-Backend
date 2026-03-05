import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../services/admin_auth_service.dart';
import '../components/admin_sidebar.dart';
import '../../../config.dart';
import '../../../theme/app_theme.dart';

// ── Data models ───────────────────────────────────────────────────────────────
class _GodownData {
  final String id;
  String name;
  String address;
  String code;
  String contactNumber;
  bool isActive;
  double? lat;
  double? lng;
  List<String> pincodes;

  _GodownData({
    required this.id,
    required this.name,
    required this.address,
    required this.code,
    required this.contactNumber,
    required this.isActive,
    this.lat,
    this.lng,
    this.pincodes = const [],
  });

  factory _GodownData.fromJson(Map<String, dynamic> j) {
    // Parse lat/lng from both GeoJSON `location.coordinates` [lng, lat]
    // and from direct `location.lat` / `location.lng`
    double? lat;
    double? lng;
    final rawLoc = j['location'];
    if (rawLoc != null && rawLoc is Map) {
      // GeoJSON: { type: "Point", coordinates: [lng, lat] }
      final coords = rawLoc['coordinates'];
      if (coords is List && coords.length >= 2) {
        lng = (coords[0] as num?)?.toDouble();
        lat = (coords[1] as num?)?.toDouble();
      }
      // Flat: { lat: ..., lng: ... }
      if (lat == null && rawLoc['lat'] != null) {
        lat = (rawLoc['lat'] as num?)?.toDouble();
      }
      if (lng == null && rawLoc['lng'] != null) {
        lng = (rawLoc['lng'] as num?)?.toDouble();
      }
    }

    // Parse pincodes (can be either `servicePincodes` or `pincodes`)
    List<String> pincodes = [];
    final sp = j['servicePincodes'];
    if (sp is List) pincodes = sp.map((e) => e.toString()).toList();
    if (pincodes.isEmpty) {
      final p = j['pincodes'];
      if (p is List) pincodes = p.map((e) => e.toString()).toList();
    }

    return _GodownData(
      id: j['_id'] ?? '',
      name: j['name'] ?? '',
      address: j['address'] ?? '',
      code: j['code'] ?? '',
      contactNumber: j['contactNumber'] ?? '',
      isActive: j['isActive'] ?? true,
      lat: lat,
      lng: lng,
      pincodes: pincodes,
    );
  }

  bool get hasLocation => lat != null && lng != null;
  String get locationText =>
      hasLocation ? '${lat!.toStringAsFixed(6)}, ${lng!.toStringAsFixed(6)}' : '';
  String get googleMapsUrl =>
      hasLocation ? 'https://www.google.com/maps?q=$lat,$lng' : '';
}

// ── Main screen ───────────────────────────────────────────────────────────────
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // godowns panel
  bool _godownsVisible = true;
  bool _godownsLoading = false;
  List<_GodownData> _godowns = [];
  String? _godownError;

  @override
  void initState() {
    super.initState();
    _fetchGodowns();
  }

  // ── API helpers ──────────────────────────────────────────────────────────────
  Future<String?> get _token => AdminAuthService.getAdminToken();



  Future<void> _fetchGodowns() async {
    setState(() {
      _godownsLoading = true;
      _godownError = null;
    });
    try {
      final token = await _token;
      final res = await http.get(
        Uri.parse(Config.adminGodownsUrl),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final raw = jsonDecode(res.body)['godowns'] as List;
        setState(() => _godowns = raw.map((e) => _GodownData.fromJson(e)).toList());
      } else {
        setState(() => _godownError = 'Failed to load godowns');
      }
    } catch (_) {
      if (mounted) setState(() => _godownError = 'Network error');
    }
    if (mounted) setState(() => _godownsLoading = false);
  }

  Future<void> _deleteGodown(String id) async {
    final token = await _token;
    final res = await http.delete(
      Uri.parse(Config.adminGodownUrl(id)),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (!mounted) return;
    if (res.statusCode == 200) {
      setState(() {
        _godowns.removeWhere((g) => g.id == id);
      });
      _showSnack('Godown removed successfully', isError: false);
    } else {
      _showSnack('Failed to remove godown', isError: true);
    }
  }

  Future<void> _updateGodown(_GodownData godown, Map<String, dynamic> updates) async {
    final token = await _token;
    final res = await http.put(
      Uri.parse(Config.adminGodownUrl(godown.id)),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode(updates),
    );
    if (!mounted) return;
    if (res.statusCode == 200) {
      final updated = _GodownData.fromJson(jsonDecode(res.body)['godown']);
      setState(() {
        final idx = _godowns.indexWhere((g) => g.id == godown.id);
        if (idx != -1) _godowns[idx] = updated;
      });
      _showSnack('Godown updated successfully', isError: false);
    } else {
      _showSnack('Failed to update godown', isError: true);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? const Color(0xFFDC2626) : AppTheme.primaryGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  // ── Dialogs ──────────────────────────────────────────────────────────────────
  void _showDeleteDialog(_GodownData godown) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626)),
          SizedBox(width: 8),
          Text('Remove Godown'),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to remove "${godown.name}"?'),
            const SizedBox(height: 8),
            if (godown.hasLocation)
              Text(
                'Location: ${godown.locationText}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textGray),
              ),
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(fontSize: 12, color: Color(0xFFDC2626), fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteGodown(godown.id);
            },
            child: const Text('Remove Godown'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(_GodownData godown) {
    final nameCtrl = TextEditingController(text: godown.name);
    final addressCtrl = TextEditingController(text: godown.address);
    final contactCtrl = TextEditingController(text: godown.contactNumber);
    bool isActive = godown.isActive;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warehouse_rounded,
                  color: AppTheme.primaryGreen, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Edit Godown', style: TextStyle(fontSize: 18)),
          ]),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dialogField('Name', nameCtrl, Icons.store_rounded),
                const SizedBox(height: 14),
                _dialogField('Address', addressCtrl, Icons.location_on_outlined, maxLines: 2),
                const SizedBox(height: 14),
                _dialogField('Contact Number', contactCtrl, Icons.phone_outlined),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Text('Active', style: TextStyle(fontWeight: FontWeight.w500)),
                    const Spacer(),
                    Switch(
                      value: isActive,
                      activeColor: AppTheme.primaryGreen,
                      onChanged: (v) => setDialogState(() => isActive = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(context);
                _updateGodown(godown, {
                  'name': nameCtrl.text.trim(),
                  'address': addressCtrl.text.trim(),
                  'contactNumber': contactCtrl.text.trim(),
                  'isActive': isActive,
                });
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogField(String label, TextEditingController ctrl, IconData icon,
      {int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: AppTheme.textGray),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.dashboardBg,
      body: Row(
        children: [
          const AdminSidebar(activePage: 'dashboard'),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome + refresh
          Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome back, Admin',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                  SizedBox(height: 8),
                  Text('Here\'s your medicine activity overview',
                      style: TextStyle(fontSize: 16, color: AppTheme.textGray)),
                ],
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  if (_godownsVisible) _fetchGodowns();
                },
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ── Godowns panel ──
          if (_godownsVisible) _buildGodownsPanel(),
        ],
      ),
    );
  }

  Widget _buildGodownsPanel() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Panel header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)]),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warehouse_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Godown Locations',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(
                        '${_godowns.length} godown${_godowns.length == 1 ? '' : 's'} configured',
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _fetchGodowns,
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                    tooltip: 'Refresh godowns',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => setState(() => _godownsVisible = false),
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Panel body
            if (_godownsLoading)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator(color: Color(0xFF0EA5E9))),
              )
            else if (_godownError != null)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(children: [
                    const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 36),
                    const SizedBox(height: 8),
                    Text(_godownError!, style: const TextStyle(color: Color(0xFFDC2626))),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _fetchGodowns,
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen, foregroundColor: Colors.white),
                      child: const Text('Retry'),
                    ),
                  ]),
                ),
              )
            else if (_godowns.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Column(children: [
                    Icon(Icons.warehouse_rounded, color: AppTheme.textLightGray, size: 48),
                    SizedBox(height: 8),
                    Text('No godowns found', style: TextStyle(color: AppTheme.textGray)),
                  ]),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: _godowns.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _GodownLocationCard(
                  godown: _godowns[i],
                  onEdit: () => _showEditDialog(_godowns[i]),
                  onDelete: () => _showDeleteDialog(_godowns[i]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


// ── Godown Location Card ───────────────────────────────────────────────────────
class _GodownLocationCard extends StatelessWidget {
  final _GodownData godown;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GodownLocationCard({
    required this.godown,
    required this.onEdit,
    required this.onDelete,
  });

  Future<void> _openMap(BuildContext context) async {
    if (!godown.hasLocation) return;
    final uri = Uri.parse(godown.googleMapsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps')),
        );
      }
    }
  }

  void _copyCoords(BuildContext context) {
    Clipboard.setData(ClipboardData(text: godown.locationText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied: ${godown.locationText}'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderGray),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        children: [
          // ── Top section: name + status + action buttons ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              children: [
                // Gradient icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.warehouse_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                // Name + code + status badges
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              godown.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (godown.code.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEDE9FE),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                godown.code,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF7C3AED),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Status dot + badge
                          Container(
                            width: 7,
                            height: 7,
                            margin: const EdgeInsets.only(right: 5),
                            decoration: BoxDecoration(
                              color: godown.isActive ? AppTheme.primaryGreen : const Color(0xFF9CA3AF),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: godown.isActive ? const Color(0xFFD1FAE5) : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              godown.isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 10,
                                color: godown.isActive ? AppTheme.darkGreen : AppTheme.textGray,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Action buttons
                Row(
                  children: [
                    IconButton(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 17),
                      color: AppTheme.primaryGreen,
                      tooltip: 'Edit godown',
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFD1FAE5),
                        padding: const EdgeInsets.all(6),
                        minimumSize: const Size(32, 32),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Prominent remove button
                    ElevatedButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_rounded, size: 15),
                      label: const Text('Remove', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Divider ──
          Divider(height: 1, color: AppTheme.borderGray.withOpacity(0.6)),

          // ── Location info section ──
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // Address
                if (godown.address.isNotEmpty)
                  _InfoRow(
                    icon: Icons.home_work_outlined,
                    color: const Color(0xFF6366F1),
                    label: 'Address',
                    value: godown.address,
                  ),

                // GPS Coordinates
                if (godown.hasLocation) ...[
                  if (godown.address.isNotEmpty) const SizedBox(height: 8),
                  _LocationRow(
                    lat: godown.lat!,
                    lng: godown.lng!,
                    onOpenMap: () => _openMap(context),
                    onCopy: () => _copyCoords(context),
                  ),
                ] else ...[
                  if (godown.address.isNotEmpty) const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFED7AA)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.location_off_outlined, size: 15, color: Color(0xFFEA580C)),
                        SizedBox(width: 8),
                        Text(
                          'No GPS coordinates set',
                          style: TextStyle(fontSize: 12, color: Color(0xFFEA580C)),
                        ),
                      ],
                    ),
                  ),
                ],

                // Contact
                if (godown.contactNumber.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.phone_outlined,
                    color: AppTheme.primaryGreen,
                    label: 'Contact',
                    value: godown.contactNumber,
                  ),
                ],

                // Service Pincodes
                if (godown.pincodes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.pin_drop_outlined, size: 14, color: Color(0xFF3B82F6)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Service Pincodes',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textGray,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: godown.pincodes
                                  .map((p) => Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: const Color(0xFFBFDBFE)),
                                        ),
                                        child: Text(
                                          p,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF1D4ED8),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info Row ──────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textGray)),
              const SizedBox(height: 1),
              Text(value, style: const TextStyle(fontSize: 13, color: AppTheme.textDark)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Location Row ──────────────────────────────────────────────────────────────
class _LocationRow extends StatelessWidget {
  final double lat;
  final double lng;
  final VoidCallback onOpenMap;
  final VoidCallback onCopy;

  const _LocationRow({
    required this.lat,
    required this.lng,
    required this.onOpenMap,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0EA5E9).withOpacity(0.08),
            const Color(0xFF6366F1).withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF0EA5E9).withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)]),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.my_location_rounded, size: 15, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GPS Location',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0EA5E9),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      'Lat: ${lat.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textDark, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Lng: ${lng.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textDark, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Copy coords button
          IconButton(
            onPressed: onCopy,
            icon: const Icon(Icons.copy_rounded, size: 15),
            tooltip: 'Copy coordinates',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF6366F1),
              padding: const EdgeInsets.all(6),
              minimumSize: const Size(30, 30),
            ),
          ),
          const SizedBox(width: 4),
          // Open in Google Maps button
          ElevatedButton.icon(
            onPressed: onOpenMap,
            icon: const Icon(Icons.map_outlined, size: 14),
            label: const Text('Maps', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0EA5E9),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
