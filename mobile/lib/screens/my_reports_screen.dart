import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/report.dart';
import '../providers/app_state.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final isDark = state.isDarkMode;

    List<EnvironmentalReport> reports = state.reports;
    if (_filter != 'All') {
      reports = reports.where((r) => r.status.toLowerCase() == _filter.toLowerCase()).toList();
    }

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : const Color(0xFFF9FBFA),
      appBar: AppBar(
        title: const Text('My Reports & Status'),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_outlined),
            tooltip: 'Admin Review Simulator (For Presentation Demo)',
            onPressed: () => _showAdminDemoDialog(context, state),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('All'),
                const SizedBox(width: 8),
                _buildFilterChip('Submitted'),
                const SizedBox(width: 8),
                _buildFilterChip('Under Review'),
                const SizedBox(width: 8),
                _buildFilterChip('Resolved'),
              ],
            ),
          ),

          Expanded(
            child: reports.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_outlined, size: 54, color: AppTheme.secondaryText.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        const Text('No environmental reports found in this category.'),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: reports.length,
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      return _buildReportCard(context, report, isDark, state);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _filter == label;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      selectedColor: AppTheme.ecoGreen.withOpacity(0.2),
      onSelected: (val) {
        if (val) setState(() => _filter = label);
      },
    );
  }

  Widget _buildReportCard(BuildContext context, EnvironmentalReport report, bool isDark, AppState state) {
    Color statusColor = const Color(0xFFF59E0B); // Amber
    if (report.status == 'Resolved') statusColor = AppTheme.ecoGreen;
    if (report.status == 'Under Review') statusColor = const Color(0xFF0284C7);

    final dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(report.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
              Expanded(
                child: Text(
                  report.category,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.primaryText,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withOpacity(0.5)),
                ),
                child: Text(
                  report.status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.secondaryText),
              const SizedBox(width: 4),
              Text(
                report.area,
                style: const TextStyle(fontSize: 12, color: AppTheme.secondaryText),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            report.description,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white70 : AppTheme.primaryText,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateStr,
                style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : AppTheme.secondaryText),
              ),
              Row(
                children: [
                  const Icon(Icons.cloud_done_outlined, size: 14, color: AppTheme.ecoGreen),
                  const SizedBox(width: 4),
                  Text(
                    report.syncStatus.toUpperCase(),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.ecoGreen),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAdminDemoDialog(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.security_rounded, color: AppTheme.forestGreen),
            SizedBox(width: 8),
            Text('Admin Review Panel'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'As highlighted in Section 18.1 Demo Sequence, test updating report status in real time:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            if (state.reports.isEmpty)
              const Text('No reports to review. File a report first!')
            else ...[
              Text(
                'First Report: ${state.reports.first.category}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (state.reports.first.id != null) {
                        state.updateReportStatus(state.reports.first.id!, 'Under Review');
                      }
                      Navigator.of(ctx).pop();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                    child: const Text('Under Review'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (state.reports.first.id != null) {
                        state.updateReportStatus(state.reports.first.id!, 'Resolved');
                      }
                      Navigator.of(ctx).pop();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.ecoGreen),
                    child: const Text('Resolved'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
