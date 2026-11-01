import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/app_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final isDark = state.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : const Color(0xFFF9FBFA),
      appBar: AppBar(
        title: const Text('Profile & Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.ecoGreen.withOpacity(0.2),
                    ),
                    child: const Icon(Icons.person, size: 36, color: AppTheme.forestGreen),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.userName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppTheme.primaryText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Student Environmental Volunteer',
                          style: TextStyle(fontSize: 12, color: AppTheme.secondaryText),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Level ${state.userLevel} • ${state.ecoPoints} EcoPoints',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.ecoGreen),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Settings Group
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black.withOpacity(0.04)),
              ),
              child: Column(
                children: [
                  // Dark Theme Toggle
                  SwitchListTile(
                    title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Switch between light and dark themes', style: TextStyle(fontSize: 12)),
                    value: state.isDarkMode,
                    activeColor: AppTheme.ecoGreen,
                    onChanged: (val) => state.toggleTheme(),
                    secondary: Icon(
                      state.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: AppTheme.ecoGreen,
                    ),
                  ),
                  const Divider(height: 1),

                  // Language Selector (Marathi / English)
                  ListTile(
                    leading: const Icon(Icons.translate_rounded, color: AppTheme.forestGreen),
                    title: const Text('Language / भाषा', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(
                      state.currentLanguage == 'mr' ? 'मराठी (Marathi)' : 'English',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: DropdownButton<String>(
                      value: state.currentLanguage,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'en', child: Text('English')),
                        DropdownMenuItem(value: 'mr', child: Text('मराठी')),
                      ],
                      onChanged: (val) {
                        if (val != null) state.setLanguage(val);
                      },
                    ),
                  ),
                  const Divider(height: 1),

                  // Offline Storage Status
                  ListTile(
                    leading: const Icon(Icons.storage_rounded, color: AppTheme.ecoGreen),
                    title: const Text('Local SQLite Storage', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(
                      '${state.scans.length} scans & ${state.reports.length} reports saved locally',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.check_circle_rounded, color: AppTheme.ecoGreen, size: 20),
                  ),
                  const Divider(height: 1),

                  // Backend API Status
                  ListTile(
                    leading: const Icon(Icons.cloud_sync_rounded, color: Color(0xFF0284C7)),
                    title: const Text('FastAPI Server Sync', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('Connected: http://127.0.0.1:8000', style: TextStyle(fontSize: 12)),
                    trailing: const Icon(Icons.check_circle_rounded, color: Color(0xFF0284C7), size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // About Project Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black.withOpacity(0.04)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'EcoVision AI',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.forestGreen),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Advanced Academic Project • Flutter, SQLite, Dart, Python, FastAPI',
                    style: TextStyle(fontSize: 12, color: AppTheme.secondaryText),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Designed for zero-cost offline-first environmental monitoring, AI waste classification, and citizen sustainability engagement.',
                    style: TextStyle(fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
