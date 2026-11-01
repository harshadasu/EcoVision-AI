import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/app_state.dart';

class EcoAdvisorScreen extends StatefulWidget {
  const EcoAdvisorScreen({super.key});

  @override
  State<EcoAdvisorScreen> createState() => _EcoAdvisorScreenState();
}

class _EcoAdvisorScreenState extends State<EcoAdvisorScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  final List<Map<String, String>> _guidelines = [
    {
      'title': 'Plastic Milk & Oil Pouches',
      'category': 'Plastic (Dry Waste)',
      'bin': 'Blue Bin',
      'color': '#2563EB',
      'tip': 'Rinse thoroughly with water and cut corner carefully without separating tiny plastic bits.',
    },
    {
      'title': 'Vegetable & Fruit Peels',
      'category': 'Organic (Wet Waste)',
      'bin': 'Green Bin',
      'color': '#16A34A',
      'tip': 'Direct into home compost or green municipality bin. Never wrap in non-biodegradable polythene.',
    },
    {
      'title': 'Discarded Lithium Batteries',
      'category': 'Hazardous E-Waste',
      'bin': 'Red Bin',
      'color': '#DC2626',
      'tip': 'Tape both positive and negative terminals with cello-tape to prevent accidental short circuits.',
    },
    {
      'title': 'Corrugated Shipping Boxes',
      'category': 'Paper & Cardboard',
      'bin': 'Blue Bin',
      'color': '#2563EB',
      'tip': 'Remove packing tape, flatten completely, and keep away from rain or liquids.',
    },
    {
      'title': 'Glass Juice & Jam Bottles',
      'category': 'Glass Recyclables',
      'bin': 'Blue Bin',
      'color': '#2563EB',
      'tip': 'Wash inside, inspect for cracks. Metal lids go to dry metal recycling.',
    },
    {
      'title': 'Soft Drink Aluminium Cans',
      'category': 'Metal Recyclables',
      'bin': 'Blue Bin',
      'color': '#2563EB',
      'tip': 'Rinse out sticky beverage and crush flat to conserve space.',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final isDark = state.isDarkMode;

    final filtered = _guidelines.where((g) {
      return g['title']!.toLowerCase().contains(_query.toLowerCase()) ||
          g['category']!.toLowerCase().contains(_query.toLowerCase()) ||
          g['tip']!.toLowerCase().contains(_query.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : const Color(0xFFF9FBFA),
      appBar: AppBar(
        title: const Text('EcoAdvisor Knowledge Base'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search waste items (e.g. pouch, battery, box)...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.forestGreen),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
              onChanged: (val) => setState(() => _query = val),
            ),
            const SizedBox(height: 16),

            // Color-coded Bin Summary
            Row(
              children: [
                _buildBinBadge('Green Bin', 'Wet / Organic', const Color(0xFF16A34A)),
                const SizedBox(width: 8),
                _buildBinBadge('Blue Bin', 'Dry Recyclables', const Color(0xFF2563EB)),
                const SizedBox(width: 8),
                _buildBinBadge('Red Bin', 'E-Waste / Hazard', const Color(0xFFDC2626)),
              ],
            ),
            const SizedBox(height: 16),

            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.search_off_rounded, size: 48, color: AppTheme.secondaryText),
                          SizedBox(height: 10),
                          Text('No matching items found.'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final binColor = Color(int.parse(item['color']!.replaceFirst('#', '0xFF')));

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkCard : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.black.withOpacity(0.04)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item['title']!,
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
                                      color: binColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: binColor.withOpacity(0.5)),
                                    ),
                                    child: Text(
                                      item['bin']!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: binColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item['category']!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white60 : AppTheme.secondaryText,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                item['tip']!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white70 : AppTheme.primaryText,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBinBadge(String title, String subtitle, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 9, color: color.withOpacity(0.8)), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
