import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/app_state.dart';
import 'scanner_screen.dart';
import 'report_issue_screen.dart';
import 'eco_advisor_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final isDark = state.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : const Color(0xFFF4FAF5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Profile Row ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.ecoGreen.withOpacity(0.2),
                          border: Border.all(color: AppTheme.ecoGreen, width: 2),
                        ),
                        child: const Center(
                          child: Icon(Icons.person, color: AppTheme.forestGreen, size: 26),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good morning, ${state.userName}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppTheme.primaryText,
                            ),
                          ),
                          Text(
                            'Campus Eco Champion 🌿',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : AppTheme.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkCard : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.notifications_none_rounded,
                        size: 22,
                        color: isDark ? Colors.white70 : AppTheme.primaryText,
                      ),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Your Impact This Month Card (Hero Card) ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF132A20), const Color(0xFF0F1E19)]
                        : [const Color(0xFFE8F8ED), const Color(0xFFD4F3DE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.ecoGreen.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Impact This Month',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : AppTheme.forestGreen,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              state.co2SavedKg.toStringAsFixed(0),
                              style: TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppTheme.forestGreen,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'kg CO2 saved',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : AppTheme.primaryText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.trending_up, color: AppTheme.ecoGreen, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              '18% vs last month',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppTheme.ecoGreen : const Color(0xFF15803D),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.ecoGreen.withOpacity(0.25),
                      ),
                      child: const Center(
                        child: Icon(Icons.cloud_done_rounded, size: 40, color: AppTheme.ecoGreen),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Snapshot Section ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Snapshot',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.primaryText,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const EcoAdvisorScreen()),
                      );
                    },
                    child: const Text('See all', style: TextStyle(color: AppTheme.ecoGreen, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildSnapshotCard(
                      isDark: isDark,
                      icon: Icons.directions_walk_rounded,
                      iconColor: const Color(0xFF0284C7),
                      title: 'Carbon Footprint',
                      value: '128',
                      unit: 'kg CO2',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildSnapshotCard(
                      isDark: isDark,
                      icon: Icons.recycling_rounded,
                      iconColor: AppTheme.ecoGreen,
                      title: 'Eco Score',
                      value: '${state.ecoScore}',
                      unit: 'Good ★',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Third Snapshot Full Width Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.ecoGreen.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.nature_people_rounded, color: AppTheme.ecoGreen, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Active Eco Quests',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppTheme.primaryText,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.ecoGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${state.actions.length} In progress',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.ecoGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Smart Suggestion Banner ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.black.withOpacity(0.04)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.emoji_objects_rounded, color: Color(0xFFD97706), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Smart Suggestion',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white54 : AppTheme.secondaryText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Switch campus single-use plastic & save 128 kg CO2',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppTheme.primaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppTheme.secondaryText),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Impact Breakdown ──
              Text(
                'Footprint Breakdown',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.primaryText,
                ),
              ),
              const SizedBox(height: 14),
              _buildBreakdownItem(isDark, Icons.directions_bus_rounded, 'Transport', '45 kg CO2', 0.45, const Color(0xFF8B5CF6), '+8%'),
              _buildBreakdownItem(isDark, Icons.restaurant_rounded, 'Food & Organic', '32 kg CO2', 0.32, const Color(0xFF10B981), '↑15%'),
              _buildBreakdownItem(isDark, Icons.shopping_bag_rounded, 'Shopping & Packaging', '40 kg CO2', 0.40, const Color(0xFFEC4899), '↓5%'),
              _buildBreakdownItem(isDark, Icons.home_rounded, 'Campus & Hostel', '23 kg CO2', 0.23, const Color(0xFF06B6D4), '↑10%'),
              const SizedBox(height: 24),

              // ── Quick Action Buttons Row ──
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ScannerScreen()),
                        );
                      },
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text('Scan Waste'),
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
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ReportIssueScreen()),
                        );
                      },
                      icon: const Icon(Icons.report_problem_rounded, color: Color(0xFFDC2626)),
                      label: const Text('Report Issue', style: TextStyle(color: Color(0xFFDC2626))),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
                        side: const BorderSide(color: Color(0xFFFCA5A5)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSnapshotCard({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white60 : AppTheme.secondaryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.primaryText,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : AppTheme.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownItem(
    bool isDark,
    IconData icon,
    String title,
    String amount,
    double progress,
    Color color,
    String tag,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: color),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppTheme.primaryText,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    amount,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tag,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: tag.contains('↓') ? AppTheme.ecoGreen : const Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
