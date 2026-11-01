import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/app_state.dart';
import '../services/classifier_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  bool _isAnalyzing = false;
  ClassificationResult? _result;
  String? _correctedCategory;

  late AnimationController _animController;
  late Animation<double> _scanLineAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        if (!mounted) return;
        setState(() {
          _selectedImage = image;
          _isAnalyzing = true;
          _result = null;
          _correctedCategory = null;
        });

        final classifier = Provider.of<AppState>(context, listen: false).classifier;
        final res = await classifier.classifyImage(image.path);

        // Simulate slight network/inference delay for realistic feedback
        await Future.delayed(const Duration(milliseconds: 900));

        if (mounted) {
          setState(() {
            _result = res;
            _correctedCategory = res.category;
            _isAnalyzing = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error accessing camera/gallery: $e')),
        );
      }
    }
  }

  Future<void> _demoScan(String type) async {
    setState(() {
      _selectedImage = XFile(type);
      _isAnalyzing = true;
      _result = null;
      _correctedCategory = null;
    });

    final classifier = Provider.of<AppState>(context, listen: false).classifier;
    final res = await classifier.classifyImage(type);
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      setState(() {
        _result = res;
        _correctedCategory = res.category;
        _isAnalyzing = false;
      });
    }
  }

  void _confirmAndSave() {
    if (_result == null) return;
    final state = Provider.of<AppState>(context, listen: false);

    state.recordScan(
      imagePath: _selectedImage?.path ?? 'demo_scan.jpg',
      result: _result!,
      confirmedCategory: _correctedCategory,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.forestGreen,
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppTheme.ecoGreen),
            const SizedBox(width: 10),
            Text('Success! +${_result!.pointsAwarded} EcoPoints awarded'),
          ],
        ),
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final isDark = state.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : const Color(0xFFF0FDF4),
      appBar: AppBar(
        title: const Text('AI Waste Scanner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'Waste Guide',
            onPressed: () => _showGuidanceModal(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Viewfinder Camera Box ──
            Container(
              height: 320,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppTheme.ecoGreen.withOpacity(0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.forestGreen.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_selectedImage != null && !_selectedImage!.path.startsWith('demo'))
                      Image.file(
                        File(_selectedImage!.path),
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(isDark),
                      )
                    else if (_selectedImage != null && _selectedImage!.path.startsWith('demo'))
                      _buildDemoDisplay(isDark, _selectedImage!.path)
                    else
                      _buildPlaceholder(isDark),

                    // Scanning Laser Animation
                    if (_isAnalyzing)
                      AnimatedBuilder(
                        animation: _scanLineAnimation,
                        builder: (context, child) {
                          return Positioned(
                            top: 320 * _scanLineAnimation.value,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: AppTheme.ecoGreen,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.ecoGreen.withOpacity(0.8),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                    // Loading Indicator
                    if (_isAnalyzing)
                      Container(
                        color: Colors.black45,
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: AppTheme.ecoGreen),
                              SizedBox(height: 14),
                              Text(
                                'EcoVision AI Analyzing...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Camera / Gallery / Demo Bar ──
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.forestGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_rounded, color: AppTheme.forestGreen),
                    label: const Text('Gallery', style: TextStyle(color: AppTheme.forestGreen)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.forestGreen),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Quick Samples Bar for zero-camera desktop testing
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildDemoChip('Plastic Bottle', 'demo_plastic_bottle.jpg'),
                _buildDemoChip('Soft Packaging', 'demo_soft_packaging_wrapper.jpg'),
                _buildDemoChip('Cardboard Box', 'demo_cardboard_box.jpg'),
                _buildDemoChip('Aluminium Can', 'demo_aluminium_can.jpg'),
                _buildDemoChip('Food Scrap', 'demo_food_organic.jpg'),
                _buildDemoChip('Battery / E-Waste', 'demo_battery_wire.jpg'),
              ],
            ),
            const SizedBox(height: 24),

            // ── AI Result Card (Matches Mockup 3) ──
            if (_result != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Result Header & Bin Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Scan Result',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white54 : AppTheme.secondaryText,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _result!.label,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : AppTheme.primaryText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Color(int.parse(_result!.binColor.replaceFirst('#', '0xFF'))).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Color(int.parse(_result!.binColor.replaceFirst('#', '0xFF'))),
                            ),
                          ),
                          child: Text(
                            _result!.binName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(int.parse(_result!.binColor.replaceFirst('#', '0xFF'))),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Confidence Meter
                    Row(
                      children: [
                        Text(
                          'Confidence: ${(_result!.confidence * 100).toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : AppTheme.secondaryText,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: _result!.confidence,
                              minHeight: 8,
                              backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
                              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.ecoGreen),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Manual Correction Section (Requirement 4.2 Objective 3)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.edit_note_rounded, size: 20, color: AppTheme.secondaryText),
                          const SizedBox(width: 10),
                          const Text('Correct Category: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          const Spacer(),
                          DropdownButton<String>(
                            value: _correctedCategory,
                            underline: const SizedBox(),
                            items: ClassifierService.availableCategories.map((c) {
                              return DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _correctedCategory = val;
                                  _result = ClassifierService.getResultForCategory(val);
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Disposal Guidance
                    Text(
                      'Disposal Instructions:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.primaryText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _result!.disposalGuidance,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : AppTheme.secondaryText,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Eco Impact
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.ecoGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.eco_rounded, color: AppTheme.ecoGreen, size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _result!.environmentalImpact,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.forestGreen),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Recycle Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _confirmAndSave,
                        icon: const Icon(Icons.check_circle_rounded),
                        label: Text('Confirm & Recycle (+${_result!.pointsAwarded} pts)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.forestGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.center_focus_strong_rounded,
            size: 64,
            color: isDark ? Colors.white24 : AppTheme.forestGreen.withOpacity(0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'Point camera at item or tap sample',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white54 : AppTheme.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoDisplay(bool isDark, String path) {
    IconData icon = Icons.recycling_rounded;
    if (path.contains('can')) icon = Icons.local_drink_rounded;
    if (path.contains('box')) icon = Icons.inventory_2_rounded;
    if (path.contains('food')) icon = Icons.restaurant_rounded;
    if (path.contains('battery')) icon = Icons.battery_charging_full_rounded;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 72, color: AppTheme.ecoGreen),
          const SizedBox(height: 12),
          Text(
            path.replaceAll('demo_', '').replaceAll('.jpg', '').replaceAll('_', ' ').toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? Colors.white : AppTheme.primaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoChip(String label, String demoPath) {
    return ActionChip(
      avatar: const Icon(Icons.science_outlined, size: 16, color: AppTheme.forestGreen),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: () => _demoScan(demoPath),
    );
  }

  void _showGuidanceModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'AI Waste Classification Guidelines',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.forestGreen),
              ),
              SizedBox(height: 12),
              Text('• Place item clearly within the central reticle.'),
              Text('• Ensure adequate lighting and minimal shadow.'),
              Text('• Keep single items centered for highest model accuracy.'),
              Text('• Verify prediction and correct category if uncertain.'),
            ],
          ),
        );
      },
    );
  }
}
