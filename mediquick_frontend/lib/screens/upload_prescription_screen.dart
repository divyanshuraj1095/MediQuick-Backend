import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../theme/app_theme.dart';
import '../config.dart';
import '../services/auth_service.dart';

class UploadPrescriptionScreen extends StatefulWidget {
  const UploadPrescriptionScreen({super.key});

  @override
  State<UploadPrescriptionScreen> createState() =>
      _UploadPrescriptionScreenState();
}

class _UploadPrescriptionScreenState extends State<UploadPrescriptionScreen>
    with SingleTickerProviderStateMixin {
  // We store the raw bytes + metadata instead of File (works on web)
  Uint8List? _fileBytes;
  String? _fileName;
  String? _fileExtension;
  String? _fileSize;
  bool _isProcessing = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<String> _processingSteps = [
    'Uploading prescription...',
    'Running AI analysis...',
    'Extracting medicine names...',
    'Matching with database...',
    'Preparing results...',
  ];
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation =
        Tween<double>(begin: 0.85, end: 1.0).animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        withData: true, // ensures bytes are loaded (required for web)
      );

      if (result != null && result.files.single.bytes != null) {
        final file = result.files.single;
        setState(() {
          _fileBytes = file.bytes;
          _fileName = file.name;
          _fileExtension = file.extension?.toLowerCase();
          _fileSize = _formatBytes(file.size);
        });
      }
    } catch (e) {
      if (mounted) {
        _showError('Could not open file picker. Please try again.');
      }
    }
  }

  void _removeFile() {
    setState(() {
      _fileBytes = null;
      _fileName = null;
      _fileExtension = null;
      _fileSize = null;
    });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(msg)),
        ]),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _mimeType() {
    switch (_fileExtension) {
      case 'pdf':
        return 'application/pdf';
      case 'png':
        return 'image/png';
      default:
        return 'image/jpeg';
    }
  }

  Future<void> _uploadPrescription() async {
    if (_fileBytes == null || _fileName == null) return;

    setState(() {
      _isProcessing = true;
      _currentStep = 0;
    });

    // Animate through processing steps while the actual request runs
    final stepFuture = Future(() async {
      for (int i = 1; i < _processingSteps.length; i++) {
        await Future.delayed(const Duration(milliseconds: 1600));
        if (!mounted) return;
        setState(() => _currentStep = i);
      }
    });

    try {
      final token = await AuthService.getToken();

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(Config.uploadPrescriptionUrl),
      );

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      final mimeStr = _mimeType(); // e.g. 'image/jpeg'
      final mimeParts = mimeStr.split('/');
      request.files.add(
        http.MultipartFile.fromBytes(
          'prescription',
          _fileBytes!,
          filename: _fileName!,
          contentType: MediaType(mimeParts[0], mimeParts[1]),
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      await stepFuture; // let animation finish gracefully
      if (!mounted) return;

      setState(() => _isProcessing = false);

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['success'] == true) {
        Navigator.pushReplacementNamed(
          context,
          '/prescription-results',
          arguments: data,
        );
      } else {
        _showError(data['message']?.toString() ?? 'Failed to process prescription');
      }
    } catch (e) {
      await stepFuture;
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showError('Network error. Please check your connection and try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.dashboardBg,
      appBar: AppBar(
        title: const Text(
          'Upload Prescription',
          style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/prescription-history'),
            icon: const Icon(Icons.history, size: 18, color: AppTheme.dashboardGreen),
            label: const Text(
              'History',
              style: TextStyle(color: AppTheme.dashboardGreen, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.dashboardGreen, AppTheme.primaryTeal],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.document_scanner, color: Colors.white, size: 40),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Prescription Scanner',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Upload a photo or PDF — AI extracts your medicines instantly',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            if (_isProcessing)
              _buildProcessingState()
            else if (_fileBytes == null)
              _buildUploadArea()
            else
              _buildPreviewSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadArea() {
    return Column(
      children: [
        // Main upload drop zone
        GestureDetector(
          onTap: _pickFile,
          child: Container(
            height: 220,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.dashboardGreen.withOpacity(0.45),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.dashboardGreen.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.dashboardGreen.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cloud_upload_outlined,
                    color: AppTheme.dashboardGreen,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Click to upload prescription',
                  style: TextStyle(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Supported: JPG, PNG, PDF  •  Max 10MB',
                  style: TextStyle(color: AppTheme.textGray, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Single big upload button
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            onPressed: _pickFile,
            icon: const Icon(Icons.upload_file_rounded, color: Colors.white, size: 22),
            label: const Text(
              'Upload Prescription',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dashboardGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Accepted formats info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tip: For best results, use a clear, well-lit photo or scan of your prescription.',
                  style: TextStyle(color: Colors.blue, fontSize: 13, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewSection() {
    final isPdf = _fileExtension == 'pdf';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Preview card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.dashboardGreen.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                if (isPdf)
                  Container(
                    height: 200,
                    alignment: Alignment.center,
                    color: Colors.red.shade50,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.picture_as_pdf,
                            size: 72, color: Colors.red.shade400),
                        const SizedBox(height: 8),
                        const Text('PDF Prescription',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  )
                else if (_fileBytes != null)
                  Image.memory(
                    _fileBytes!,
                    width: double.infinity,
                    height: 280,
                    fit: BoxFit.contain,
                  ),
                // Remove button
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: _removeFile,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child:
                          const Icon(Icons.close, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // File info strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderGray),
          ),
          child: Row(
            children: [
              Icon(
                isPdf ? Icons.picture_as_pdf : Icons.image_outlined,
                color: isPdf ? Colors.red : AppTheme.dashboardGreen,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _fileName ?? 'prescription',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _fileSize ?? '',
                      style: const TextStyle(
                          color: AppTheme.textGray, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.check_circle,
                  color: AppTheme.dashboardGreen, size: 22),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Process button
        SizedBox(
          height: 54,
          child: ElevatedButton.icon(
            onPressed: _uploadPrescription,
            icon: const Icon(Icons.science_outlined, color: Colors.white),
            label: const Text(
              'Analyse Prescription with AI',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dashboardGreen,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _pickFile,
          child: const Text(
            'Choose a different file',
            style: TextStyle(color: AppTheme.textGray),
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.dashboardGreen.withOpacity(0.08),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          // Pulsing icon
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.dashboardGreen, AppTheme.primaryTeal],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.psychology_outlined,
                  color: Colors.white, size: 52),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'AI Processing Prescription',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark),
          ),
          const SizedBox(height: 8),
          Text(
            _currentStep < _processingSteps.length
                ? _processingSteps[_currentStep]
                : 'Almost done...',
            style: const TextStyle(color: AppTheme.textGray, fontSize: 14),
          ),
          const SizedBox(height: 28),

          // Step progress list
          Column(
            children: List.generate(_processingSteps.length, (i) {
              final isDone = i < _currentStep;
              final isCurrent = i == _currentStep;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isDone
                            ? AppTheme.dashboardGreen
                            : isCurrent
                                ? AppTheme.dashboardGreen.withOpacity(0.15)
                                : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check, color: Colors.white, size: 14)
                            : isCurrent
                                ? const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.dashboardGreen,
                                    ),
                                  )
                                : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _processingSteps[i],
                      style: TextStyle(
                        fontSize: 13,
                        color: isDone || isCurrent
                            ? AppTheme.textDark
                            : AppTheme.textLightGray,
                        fontWeight:
                            isCurrent ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
