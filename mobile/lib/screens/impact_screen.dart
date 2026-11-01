import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/app_state.dart';

class ImpactScreen extends StatefulWidget {
  const ImpactScreen({super.key});

  @override
  State<ImpactScreen> createState() => _ImpactScreenState();
}

class _ImpactScreenState extends State<ImpactScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scoreAnimation;
  late Animation<double> _co2Animation;
  int _touchedPieIndex = -1;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scoreAnimation = Tween<double>(begin: 0.0, end: 0.72).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _co2Animation = Tween<double>(begin: 0.0, end: 42.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _shareImpactCard(AppState state) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppTheme.forestGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            const Icon(Icons.share_rounded, color: AppTheme.ecoGreen),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Impact Card copied to clipboard! Shared ${state.co2SavedKg.toStringAsFixed(0)} kg CO2 footprint reduction.',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'OK',
          textColor: AppTheme.ecoGreen,
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final isDark = state.isDarkMode;

    // Calculate trees equivalent (~21 kg CO2 absorbed by one mature tree annually)
    final treesEquivalent = (state.co2SavedKg / 21.0).clamp(0.1, 999.0);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : const Color(0xFFF4FAF5),
      appBar: AppBar(
        title: const Text('Environmental Impact'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share Impact Certificate',
            onPressed: () => _shareImpactCard(state),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Beautiful Gradient Hero Card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF0F261E), const Color(0xFF091712)]
                      : [AppTheme.forestGreen, const Color(0xFF1B4D3E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.forestGreen.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.ecoGreen.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.ecoGreen.withOpacity(0.4)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.verified_rounded, size: 14, color: AppTheme.ecoGreen),
                                    SizedBox(width: 4),
                                    Text(
                                      'Certified Green Score',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.ecoGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Lifetime Impact',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Animated CO2 Counter
                          AnimatedBuilder(
                            animation: _co2Animation,
                            builder: (context, child) {
                              final val = _co2Animation.value;
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    val.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 38,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      height: 1.0,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'kg CO2',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.ecoGreen,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'saved from urban emissions',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white60,
                            ),
                          ),
                        ],
                      ),

                      // Large Circular Progress Indicator showing EcoScore (72/100)
                      AnimatedBuilder(
                        animation: _scoreAnimation,
                        builder: (context, child) {
                          final currentScore = (_scoreAnimation.value * 100).toInt();
                          return SizedBox(
                            width: 110,
                            height: 110,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 104,
                                  height: 104,
                                  child: CircularProgressIndicator(
                                    value: _scoreAnimation.value,
                                    strokeWidth: 9,
                                    backgroundColor: Colors.white.withOpacity(0.12),
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      AppTheme.ecoGreen,
                                    ),
                                    strokeCap: StrokeCap.round,
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '$currentScore',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        height: 1.0,
                                      ),
                                    ),
                                    const Text(
                                      '/100',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white54,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'EcoScore',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.ecoGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // ── Grid of Impact Stats (4 Cards) ──
            Text(
              'Impact Metrics Overview',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.primaryText,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.45,
              children: [
                _buildStatTile(
                  isDark: isDark,
                  icon: Icons.recycling_rounded,
                  iconColor: const Color(0xFF0284C7),
                  title: 'Waste Scanned',
                  value: '${state.recycledKg.toStringAsFixed(1)} kg',
                  subtitle: '${state.scans.length} verified scans',
                ),
                _buildStatTile(
                  isDark: isDark,
                  icon: Icons.cloud_done_rounded,
                  iconColor: AppTheme.ecoGreen,
                  title: 'CO2 Saved',
                  value: '${state.co2SavedKg.toStringAsFixed(1)} kg',
                  subtitle: '+18% this month',
                ),
                _buildStatTile(
                  isDark: isDark,
                  icon: Icons.assignment_turned_in_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'Reports Filed',
                  value: '${state.reports.length}',
                  subtitle: 'Community actions',
                ),
                _buildStatTile(
                  isDark: isDark,
                  icon: Icons.park_rounded,
                  iconColor: const Color(0xFF10B981),
                  title: 'Trees Equivalent',
                  value: '${treesEquivalent.toStringAsFixed(1)}',
                  subtitle: 'annual absorption',
                ),
              ],
            ),
            const SizedBox(height: 26),

            // ── Monthly Impact Chart (LineChart) ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
                ),
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Monthly CO2 Savings',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppTheme.primaryText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Last 6 months progression (kg CO2)',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : AppTheme.secondaryText,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.ecoGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.trending_up, size: 14, color: AppTheme.ecoGreen),
                            SizedBox(width: 4),
                            Text(
                              '+300%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.ecoGreen,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // fl_chart LineChart (Last 6 months)
                  SizedBox(
                    height: 180,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 15,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: isDark
                                ? Colors.white.withOpacity(0.06)
                                : Colors.black.withOpacity(0.05),
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                const months = ['May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct'];
                                final index = value.toInt();
                                if (index >= 0 && index < months.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      months[index],
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white54 : AppTheme.secondaryText,
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 15,
                              reservedSize: 34,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${value.toInt()}k',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark ? Colors.white38 : AppTheme.secondaryText,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        minX: 0,
                        maxX: 5,
                        minY: 0,
                        maxY: 55,
                        lineBarsData: [
                          LineChartBarData(
                            spots: const [
                              FlSpot(0, 10),
                              FlSpot(1, 16),
                              FlSpot(2, 22),
                              FlSpot(3, 31),
                              FlSpot(4, 36),
                              FlSpot(5, 42),
                            ],
                            isCurved: true,
                            curveSmoothness: 0.35,
                            color: AppTheme.ecoGreen,
                            barWidth: 3.5,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) =>
                                  FlDotCirclePainter(
                                radius: 4,
                                color: Colors.white,
                                strokeWidth: 2.5,
                                strokeColor: AppTheme.forestGreen,
                              ),
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.ecoGreen.withOpacity(0.32),
                                  AppTheme.ecoGreen.withOpacity(0.02),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),

            // ── Waste Distribution PieChart ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
                ),
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
                  Text(
                    'Waste Category Distribution',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Breakdown of materials segregated and diverted',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : AppTheme.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      // Pie Chart Widget
                      Expanded(
                        flex: 5,
                        child: SizedBox(
                          height: 160,
                          child: PieChart(
                            PieChartData(
                              pieTouchData: PieTouchData(
                                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                  setState(() {
                                    if (!event.isInterestedForInteractions ||
                                        pieTouchResponse == null ||
                                        pieTouchResponse.touchedSection == null) {
                                      _touchedPieIndex = -1;
                                      return;
                                    }
                                    _touchedPieIndex = pieTouchResponse
                                        .touchedSection!.touchedSectionIndex;
                                  });
                                },
                              ),
                              borderData: FlBorderData(show: false),
                              sectionsSpace: 3,
                              centerSpaceRadius: 36,
                              sections: _generatePieSections(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Legend items
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPieLegend(const Color(0xFF2563EB), 'Plastics (40%)'),
                            const SizedBox(height: 8),
                            _buildPieLegend(AppTheme.ecoGreen, 'Organic (25%)'),
                            const SizedBox(height: 8),
                            _buildPieLegend(const Color(0xFFF59E0B), 'Paper (20%)'),
                            const SizedBox(height: 8),
                            _buildPieLegend(const Color(0xFFDC2626), 'E-Waste (15%)'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),

            // ── Achievement Badges Section (3 Badges) ──
            Text(
              'Achievement Badges',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.primaryText,
              ),
            ),
            const SizedBox(height: 12),
            _buildAchievementBadge(
              isDark: isDark,
              icon: Icons.qr_code_scanner_rounded,
              iconBg: const Color(0xFF0284C7),
              title: 'First Scan',
              description: 'Initiated your journey by classifying your first recyclable item.',
              status: 'UNLOCKED',
              isUnlocked: state.scans.isNotEmpty,
            ),
            const SizedBox(height: 10),
            _buildAchievementBadge(
              isDark: isDark,
              icon: Icons.shield_rounded,
              iconBg: const Color(0xFF10B981),
              title: 'Report Hero',
              description: 'Submitted verified environmental reports to clean local hotspots.',
              status: 'UNLOCKED',
              isUnlocked: state.reports.isNotEmpty,
            ),
            const SizedBox(height: 10),
            _buildAchievementBadge(
              isDark: isDark,
              icon: Icons.bolt_rounded,
              iconBg: const Color(0xFFF59E0B),
              title: 'Eco Warrior',
              description: 'Achieved over 5,000 lifetime EcoPoints through sustainable habits.',
              status: state.ecoPoints >= 5000 ? 'UNLOCKED' : '${state.ecoPoints}/5000',
              isUnlocked: state.ecoPoints >= 5000,
            ),
            const SizedBox(height: 24),

            // ── Share Impact Card Button ──
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () => _shareImpactCard(state),
                icon: const Icon(Icons.share_rounded, color: Colors.white),
                label: const Text(
                  'Share Impact Certificate',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.forestGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white60 : AppTheme.secondaryText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white38 : AppTheme.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _generatePieSections() {
    return List.generate(4, (i) {
      final isTouched = i == _touchedPieIndex;
      final radius = isTouched ? 50.0 : 42.0;

      switch (i) {
        case 0:
          return PieChartSectionData(
            color: const Color(0xFF2563EB),
            value: 40,
            title: '40%',
            radius: radius,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        case 1:
          return PieChartSectionData(
            color: AppTheme.ecoGreen,
            value: 25,
            title: '25%',
            radius: radius,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        case 2:
          return PieChartSectionData(
            color: const Color(0xFFF59E0B),
            value: 20,
            title: '20%',
            radius: radius,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        case 3:
          return PieChartSectionData(
            color: const Color(0xFFDC2626),
            value: 15,
            title: '15%',
            radius: radius,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        default:
          throw Error();
      }
    });
  }

  Widget _buildPieLegend(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementBadge({
    required bool isDark,
    required IconData icon,
    required Color iconBg,
    required String title,
    required String description,
    required String status,
    required bool isUnlocked,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnlocked
              ? AppTheme.ecoGreen.withOpacity(0.3)
              : (isDark ? Colors.white10 : Colors.black.withOpacity(0.04)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isUnlocked ? iconBg.withOpacity(0.15) : Colors.black.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 26,
              color: isUnlocked ? iconBg : AppTheme.secondaryText,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.primaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : AppTheme.secondaryText,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isUnlocked ? AppTheme.ecoGreen : Colors.black.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isUnlocked ? Colors.white : AppTheme.secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
