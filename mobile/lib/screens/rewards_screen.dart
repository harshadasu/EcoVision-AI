import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/app_state.dart';

class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final isDark = state.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : const Color(0xFFF2F9F3),
      appBar: AppBar(
        title: const Text('Eco Rewards & Badges'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            // Level & Avatar Header
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: CircularProgressIndicator(
                          value: (state.userXP % 2000) / 2000,
                          strokeWidth: 6,
                          backgroundColor: AppTheme.ecoGreen.withOpacity(0.15),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.ecoGreen),
                        ),
                      ),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.forestGreen.withOpacity(0.1),
                        ),
                        child: const Center(
                          child: Icon(Icons.person, size: 40, color: AppTheme.forestGreen),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.forestGreen,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Lvl ${state.userLevel}',
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'XP ${state.userXP} to next level',
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : AppTheme.secondaryText),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Top Stat Counters Row (Matches Mockup 4)
            Row(
              children: [
                Expanded(child: _buildStatCard(isDark, Icons.recycling_rounded, '${state.recycledKg.toStringAsFixed(1)} kg', 'recycled')),
                const SizedBox(width: 10),
                Expanded(child: _buildStatCard(isDark, Icons.cloud_done_rounded, '${state.co2SavedKg.toStringAsFixed(1)} kg', 'CO2 saved')),
                const SizedBox(width: 10),
                Expanded(child: _buildStatCard(isDark, Icons.eco_rounded, '${state.ecoPoints}', 'points')),
              ],
            ),
            const SizedBox(height: 18),

            // Exchange & Donate Actions Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black.withOpacity(0.06)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${state.ecoPoints} pts',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppTheme.primaryText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text('Exchange', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.forestGreen)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.forestGreen,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      children: [
                        Text(
                          'Campus Green Fund',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(height: 6),
                        Text('Donate', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.ecoGreen)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Weekly Challenge Card (Matches Mockup 4)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'WEEKLY CHALLENGE',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Color(0xFF0369A1)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('+200 pts', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Brewed to Be Green\nZero-Waste Coffee Challenge',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), height: 1.25),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: const [
                      Icon(Icons.people_alt_rounded, size: 16, color: Color(0xFF0369A1)),
                      SizedBox(width: 6),
                      Text('12,480 students participating', style: TextStyle(fontSize: 12, color: Color(0xFF0369A1))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Unlocked Badges (Matches Mockup 4 & 5)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Achievements & Badges',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.primaryText,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildAchievementCard(
              isDark,
              '🐝',
              'Sustainable New-bee',
              'Diverted 1 kg of waste from landfills through verified segregation.',
              true,
              'Completed',
            ),
            const SizedBox(height: 10),
            _buildAchievementCard(
              isDark,
              '🍾',
              'Bottle Buddy',
              'Recycle 50 plastic bottles into dedicated reverse vending bins.',
              false,
              '35 / 50',
            ),
            const SizedBox(height: 10),
            _buildAchievementCard(
              isDark,
              '🛡️',
              'CO2 Champion',
              'Save 100 kg CO2 through green living recommendations.',
              false,
              '42 / 100 kg',
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(bool isDark, IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppTheme.ecoGreen),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white54 : AppTheme.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(bool isDark, String emoji, String title, String desc, bool isUnlocked, String progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isUnlocked ? AppTheme.ecoGreen.withOpacity(0.15) : Colors.black.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
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
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : AppTheme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isUnlocked ? AppTheme.ecoGreen : Colors.black.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              progress,
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
