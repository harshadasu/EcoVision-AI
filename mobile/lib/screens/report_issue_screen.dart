import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/app_state.dart';
import 'my_reports_screen.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  String _category = 'Illegal Waste Dumping';
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _areaController = TextEditingController(text: 'Campus North Zone / Main Quad');
  XFile? _attachedPhoto;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Illegal Waste Dumping',
    'Plastic Waste Overflow',
    'Water Contamination / Sewage',
    'Air Pollution / Open Waste Burning',
    'Hazardous E-Waste Hazard',
    'Unsegregated Mixed Garbage',
  ];

  @override
  void dispose() {
    _descController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera, maxWidth: 1024, imageQuality: 80);
    if (photo != null) {
      setState(() => _attachedPhoto = photo);
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final state = Provider.of<AppState>(context, listen: false);

    await state.submitReport(
      category: _category,
      description: _descController.text.trim(),
      area: _areaController.text.trim(),
      imagePath: _attachedPhoto?.path,
    );

    setState(() => _isSubmitting = false);

    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppTheme.ecoGreen, size: 28),
              SizedBox(width: 10),
              Text('Report Filed'),
            ],
          ),
          content: const Text(
            'Your environmental report has been stored securely in the local SQLite database and synchronized with EcoVision AI. You earned +50 EcoPoints!',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const MyReportsScreen()),
                );
              },
              child: const Text('View My Reports', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.forestGreen)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final isDark = state.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : const Color(0xFFF9FBFA),
      appBar: AppBar(
        title: const Text('Report Issue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'My Reports',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyReportsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Citizen Environmental Action',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.primaryText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Help keep our campus and community clean. Reports are recorded with transparent status tracking.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white60 : AppTheme.secondaryText,
                ),
              ),
              const SizedBox(height: 24),

              // Category Dropdown
              Text(
                'Issue Category',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black.withOpacity(0.08)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _category,
                    isExpanded: true,
                    items: _categories.map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(fontSize: 14)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _category = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Location / Area
              Text(
                'Location / Area',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _areaController,
                decoration: InputDecoration(
                  hintText: 'e.g. North Gate Cafeteria or Main Garden',
                  prefixIcon: const Icon(Icons.location_on_outlined, color: AppTheme.forestGreen),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.my_location_rounded, size: 20, color: AppTheme.ecoGreen),
                    tooltip: 'Use GPS',
                    onPressed: () {
                      _areaController.text = 'GPS: 18.5204° N, 73.8567° E (Campus Zone A)';
                    },
                  ),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Please specify location' : null,
              ),
              const SizedBox(height: 20),

              // Description Field
              Text(
                'Description & Observations',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Describe the environmental hazard, volume of waste, or urgent action needed...',
                ),
                validator: (v) => v == null || v.trim().length < 5 ? 'Please provide detailed description' : null,
              ),
              const SizedBox(height: 20),

              // Photo Attachment Box
              Text(
                'Evidence Photo (Optional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickPhoto,
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.ecoGreen.withOpacity(0.5),
                      style: BorderStyle.solid,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: _attachedPhoto != null
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_rounded, color: AppTheme.ecoGreen),
                              const SizedBox(width: 8),
                              const Text('Photo attached! Tap to retake', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.add_a_photo_outlined, size: 32, color: AppTheme.forestGreen),
                              SizedBox(height: 8),
                              Text('Tap to capture or upload evidence photo', style: TextStyle(fontSize: 13, color: AppTheme.secondaryText)),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitReport,
                  icon: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded),
                  label: Text(_isSubmitting ? 'Submitting...' : 'Submit Environmental Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.forestGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
