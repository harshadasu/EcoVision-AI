import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/app_state.dart';
import 'report_issue_screen.dart';

/// Data model representing an environmental map point
class MapLocation {
  final String id;
  final String name;
  final String area;
  final String type; // 'Hotspot', 'Recycling', 'Reports'
  final String distance;
  final String severity; // 'Critical', 'High', 'Moderate', 'Active'
  final double relX; // 0.0 to 1.0 for CustomPaint map coordinate
  final double relY; // 0.0 to 1.0
  final double latitude;
  final double longitude;
  final String details;

  const MapLocation({
    required this.id,
    required this.name,
    required this.area,
    required this.type,
    required this.distance,
    required this.severity,
    required this.relX,
    required this.relY,
    required this.latitude,
    required this.longitude,
    required this.details,
  });
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  String _searchQuery = '';
  String? _selectedLocationId;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // 5 Pune-area locations specified in requirements
  final List<MapLocation> _locations = const [
    MapLocation(
      id: 'loc_north_campus',
      name: 'North Campus Quadrangle',
      area: 'Savitribai Phule Pune University',
      type: 'Recycling',
      distance: '0.3 km',
      severity: 'Active',
      relX: 0.36,
      relY: 0.28,
      latitude: 18.5529,
      longitude: 73.8260,
      details: 'High-capacity smart reverse vending machine & dry recyclable drop-off.',
    ),
    MapLocation(
      id: 'loc_shivajinagar',
      name: 'Shivajinagar Transit Hub',
      area: 'Shivajinagar, Central Pune',
      type: 'Reports',
      distance: '2.1 km',
      severity: 'Moderate',
      relX: 0.50,
      relY: 0.44,
      latitude: 18.5314,
      longitude: 73.8446,
      details: 'Bus terminal perimeter report: segregated bins overflowing at peak hours.',
    ),
    MapLocation(
      id: 'loc_kothrud',
      name: 'Kothrud Green Depot',
      area: 'Paud Road, Kothrud',
      type: 'Recycling',
      distance: '3.5 km',
      severity: 'Active',
      relX: 0.24,
      relY: 0.62,
      latitude: 18.5074,
      longitude: 73.8077,
      details: 'Community e-waste drop-off point & organic composting facility.',
    ),
    MapLocation(
      id: 'loc_katraj',
      name: 'Katraj Lake Wetland Reserve',
      area: 'Katraj Ghat, South Pune',
      type: 'Hotspots',
      distance: '4.8 km',
      severity: 'High',
      relX: 0.54,
      relY: 0.82,
      latitude: 18.4575,
      longitude: 73.8677,
      details: 'Plastic debris accumulation along lake boundary and drainage inlet.',
    ),
    MapLocation(
      id: 'loc_hadapsar',
      name: 'Hadapsar Industrial Zone',
      area: 'Magarpatta / Hadapsar Corridor',
      type: 'Hotspots',
      distance: '6.2 km',
      severity: 'Critical',
      relX: 0.82,
      relY: 0.58,
      latitude: 18.5089,
      longitude: 73.9260,
      details: 'Industrial packaging runoff and unauthorized open waste incineration alert.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  List<MapLocation> get _filteredLocations {
    return _locations.where((loc) {
      final matchesFilter = _selectedFilter == 'All' ||
          loc.type.toLowerCase() == _selectedFilter.toLowerCase();
      final matchesQuery = _searchQuery.isEmpty ||
          loc.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          loc.area.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          loc.type.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesQuery;
    }).toList();
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return const Color(0xFFDC2626); // Red
      case 'high':
        return const Color(0xFFEA580C); // Orange
      case 'moderate':
        return const Color(0xFFF59E0B); // Amber
      case 'active':
      default:
        return AppTheme.ecoGreen; // Eco Green
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'hotspots':
      case 'hotspot':
        return Icons.local_fire_department_rounded;
      case 'recycling':
        return Icons.recycling_rounded;
      case 'reports':
      default:
        return Icons.report_problem_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final isDark = state.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : const Color(0xFFF5F9F6),
      appBar: AppBar(
        title: const Text('Environmental Hotspots'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            tooltip: 'Recenter to Pune Campus',
            onPressed: () {
              setState(() => _selectedLocationId = null);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Centered on SPPU Campus, Pune (18.5204° N, 73.8567° E)'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.forestGreen,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt_rounded),
        label: const Text(
          'Report New Issue',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ReportIssueScreen()),
          );
        },
      ),
      body: Column(
        children: [
          // ── Search & Filter Controls ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search Pune hotspots, wards, or recycling centers...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white38 : AppTheme.secondaryText,
                      ),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.forestGreen),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                const SizedBox(height: 10),

                // Filter Buttons Row (All, Hotspots, Recycling, Reports)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', Icons.map_outlined),
                      const SizedBox(width: 8),
                      _buildFilterChip('Hotspots', Icons.warning_amber_rounded),
                      const SizedBox(width: 8),
                      _buildFilterChip('Recycling', Icons.recycling_rounded),
                      const SizedBox(width: 8),
                      _buildFilterChip('Reports', Icons.assignment_outlined),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Stylized Map Visualization (CustomPaint) ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.forestGreen.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    // Canvas Painter
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return CustomPaint(
                          size: const Size(double.infinity, 250),
                          painter: StylizedMapPainter(
                            isDarkMode: isDark,
                            locations: _filteredLocations,
                            selectedId: _selectedLocationId,
                            pulseScale: _pulseAnimation.value,
                          ),
                        );
                      },
                    ),

                    // Gesture detector overlay for clicking pins
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: _filteredLocations.map((loc) {
                            final left = loc.relX * constraints.maxWidth - 20;
                            final top = loc.relY * constraints.maxHeight - 20;
                            final isSelected = loc.id == _selectedLocationId;

                            return Positioned(
                              left: left,
                              top: top,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedLocationId =
                                        _selectedLocationId == loc.id ? null : loc.id;
                                  });
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  color: Colors.transparent,
                                  alignment: Alignment.center,
                                  child: isSelected
                                      ? Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2),
                                            color: _getSeverityColor(loc.severity),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Colors.black38,
                                                blurRadius: 6,
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            _getTypeIcon(loc.type),
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),

                    // Map UI Controls Overlay (Zoom, Compass & Legend)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: (isDark ? AppTheme.darkCard : Colors.white).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.black.withOpacity(0.06),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.explore_rounded, size: 16, color: AppTheme.ecoGreen),
                            const SizedBox(width: 6),
                            Text(
                              'Pune Metropolitan Grid',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppTheme.primaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Map Legend (Bottom Left)
                    Positioned(
                      bottom: 10,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.black87 : Colors.white).withOpacity(0.85),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildLegendItem(const Color(0xFFDC2626), 'Critical'),
                            const SizedBox(width: 8),
                            _buildLegendItem(const Color(0xFFF59E0B), 'Warning'),
                            const SizedBox(width: 8),
                            _buildLegendItem(AppTheme.ecoGreen, 'Recycling'),
                          ],
                        ),
                      ),
                    ),

                    // Zoom Pill (Top Right)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        decoration: BoxDecoration(
                          color: (isDark ? AppTheme.darkCard : Colors.white).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () {},
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(Icons.add, size: 18),
                              ),
                            ),
                            Container(height: 1, width: 22, color: Colors.black12),
                            InkWell(
                              onTap: () {},
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(Icons.remove, size: 18),
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
          ),

          // ── Nearby Locations List Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nearby Environmental Points (${_filteredLocations.length})',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.primaryText,
                  ),
                ),
                Text(
                  'Sorted by distance',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : AppTheme.secondaryText,
                  ),
                ),
              ],
            ),
          ),

          // ── Nearby Locations List ──
          Expanded(
            child: _filteredLocations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_off_rounded,
                          size: 48,
                          color: AppTheme.secondaryText.withOpacity(0.4),
                        ),
                        const SizedBox(height: 10),
                        const Text('No locations match your filter or search.'),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    itemCount: _filteredLocations.length,
                    itemBuilder: (context, index) {
                      final item = _filteredLocations[index];
                      final isSelected = item.id == _selectedLocationId;
                      final severityColor = _getSeverityColor(item.severity);

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedLocationId = isSelected ? null : item.id;
                          });
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkCard : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.ecoGreen
                                  : Colors.black.withOpacity(0.04),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? AppTheme.ecoGreen.withOpacity(0.12)
                                    : Colors.black.withOpacity(0.02),
                                blurRadius: isSelected ? 12 : 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Type Icon
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: severityColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  _getTypeIcon(item.type),
                                  color: severityColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Info Column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.name,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white : AppTheme.primaryText,
                                            ),
                                          ),
                                        ),
                                        // Distance indicator
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? Colors.white10
                                                : const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.near_me_outlined,
                                                  size: 12, color: AppTheme.secondaryText),
                                              const SizedBox(width: 4),
                                              Text(
                                                item.distance,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.secondaryText,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.area,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? Colors.white60 : AppTheme.secondaryText,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      item.details,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    // Badge Row
                                    Row(
                                      children: [
                                        // Severity Badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: severityColor.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(
                                              color: severityColor.withOpacity(0.4),
                                            ),
                                          ),
                                          child: Text(
                                            'Severity: ${item.severity}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: severityColor,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),

                                        // Category Pill
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: AppTheme.forestGreen.withOpacity(0.08),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            item.type,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.forestGreen,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final isSelected = _selectedFilter == label;
    return FilterChip(
      selected: isSelected,
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? Colors.white : AppTheme.forestGreen,
      ),
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? Colors.white : AppTheme.forestGreen,
      ),
      selectedColor: AppTheme.forestGreen,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppTheme.forestGreen : Colors.black.withOpacity(0.08),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (val) {
        setState(() => _selectedFilter = label);
      },
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// Custom painter rendering a stylized, realistic grid map with Pune river curves,
/// heatmap radial blobs, road lines, and hotspot pin markers.
class StylizedMapPainter extends CustomPainter {
  final bool isDarkMode;
  final List<MapLocation> locations;
  final String? selectedId;
  final double pulseScale;

  StylizedMapPainter({
    required this.isDarkMode,
    required this.locations,
    required this.selectedId,
    required this.pulseScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Terrain Base Fill
    final baseColor = isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F7F3);
    final bgPaint = Paint()..color = baseColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Green Zones (Vetal Hill, University Woods, Taljai)
    final greenZonePaint = Paint()
      ..color = isDarkMode
          ? const Color(0xFF142E24).withOpacity(0.6)
          : const Color(0xFFD7EEDF).withOpacity(0.85);

    // University green polygon
    final uniPark = Path()
      ..moveTo(size.width * 0.15, size.height * 0.15)
      ..quadraticBezierTo(
          size.width * 0.35, size.height * 0.10, size.width * 0.45, size.height * 0.30)
      ..quadraticBezierTo(
          size.width * 0.30, size.height * 0.45, size.width * 0.18, size.height * 0.35)
      ..close();
    canvas.drawPath(uniPark, greenZonePaint);

    // Vetal Tekdi green polygon (South-West)
    final vetalTekdi = Path()
      ..moveTo(size.width * 0.10, size.height * 0.50)
      ..quadraticBezierTo(
          size.width * 0.28, size.height * 0.52, size.width * 0.25, size.height * 0.78)
      ..quadraticBezierTo(
          size.width * 0.08, size.height * 0.85, size.width * 0.06, size.height * 0.65)
      ..close();
    canvas.drawPath(vetalTekdi, greenZonePaint);

    // Katraj / Southern green boundary
    final katrajHills = Path()
      ..moveTo(size.width * 0.40, size.height * 0.80)
      ..quadraticBezierTo(
          size.width * 0.60, size.height * 0.70, size.width * 0.85, size.height * 0.88)
      ..lineTo(size.width * 0.85, size.height)
      ..lineTo(size.width * 0.35, size.height)
      ..close();
    canvas.drawPath(katrajHills, greenZonePaint);

    // 3. Mula-Mutha River Ribbon (Stylized curve cutting through central Pune)
    final riverPaint = Paint()
      ..color = isDarkMode ? const Color(0xFF1E3A5F) : const Color(0xFFBAE6FD)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final riverPath = Path()
      ..moveTo(0, size.height * 0.32)
      ..cubicTo(
        size.width * 0.30,
        size.height * 0.38,
        size.width * 0.45,
        size.height * 0.48,
        size.width * 0.70,
        size.height * 0.46,
      )
      ..cubicTo(
        size.width * 0.85,
        size.height * 0.44,
        size.width * 0.95,
        size.height * 0.38,
        size.width,
        size.height * 0.40,
      );
    canvas.drawPath(riverPath, riverPaint);

    // 4. Urban Road Grid Lines
    final roadPaint = Paint()
      ..color = isDarkMode ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.9)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final minorRoadPaint = Paint()
      ..color = isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Grid lines (East-West & North-South arterials)
    for (double y = 40; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), minorRoadPaint);
    }
    for (double x = 40; x < size.width; x += 50) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), minorRoadPaint);
    }

    // Arterial Highways (e.g. Pune-Bangalore bypass, Paud Rd, Nagar Rd)
    final highwayPaint = Paint()
      ..color = isDarkMode ? const Color(0xFF334155) : const Color(0xFFE2E8F0)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(size.width * 0.05, size.height * 0.1),
      Offset(size.width * 0.95, size.height * 0.85),
      highwayPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.10, size.height * 0.90),
      Offset(size.width * 0.90, size.height * 0.20),
      highwayPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.50),
      Offset(size.width, size.height * 0.50),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.48, 0),
      Offset(size.width * 0.48, size.height),
      roadPaint,
    );

    // 5. Heatmap Radial Glow Blobs for Hotspots
    for (final loc in locations) {
      final center = Offset(loc.relX * size.width, loc.relY * size.height);
      Color glowColor;
      double radius;

      if (loc.severity == 'Critical') {
        glowColor = const Color(0xFFDC2626);
        radius = 48.0;
      } else if (loc.severity == 'High') {
        glowColor = const Color(0xFFEA580C);
        radius = 40.0;
      } else if (loc.severity == 'Moderate') {
        glowColor = const Color(0xFFF59E0B);
        radius = 32.0;
      } else {
        glowColor = AppTheme.ecoGreen;
        radius = 30.0;
      }

      final heatPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            glowColor.withOpacity(0.35),
            glowColor.withOpacity(0.12),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius));

      canvas.drawCircle(center, radius, heatPaint);
    }

    // 6. Location Markers & Labels
    for (final loc in locations) {
      final center = Offset(loc.relX * size.width, loc.relY * size.height);
      final isSelected = loc.id == selectedId;

      Color pinColor;
      if (loc.severity == 'Critical') {
        pinColor = const Color(0xFFDC2626);
      } else if (loc.severity == 'High') {
        pinColor = const Color(0xFFEA580C);
      } else if (loc.severity == 'Moderate') {
        pinColor = const Color(0xFFF59E0B);
      } else {
        pinColor = AppTheme.ecoGreen;
      }

      // Outer animated pulse ring for selected or critical
      if (isSelected || loc.severity == 'Critical') {
        final ringPaint = Paint()
          ..color = pinColor.withOpacity(0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;
        canvas.drawCircle(center, 12 * (isSelected ? pulseScale : 1.1), ringPaint);
      }

      // Marker Shadow
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(center.translate(0, 2), 7, shadowPaint);

      // Marker Outer Pin Circle
      final pinPaint = Paint()..color = pinColor;
      canvas.drawCircle(center, 7, pinPaint);

      // Marker Inner White Dot
      final innerDot = Paint()..color = Colors.white;
      canvas.drawCircle(center, 2.8, innerDot);

      // Text Label Pill
      final textSpan = TextSpan(
        text: loc.name.split(' ').first, // Short label
        style: TextStyle(
          color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          backgroundColor:
              (isDarkMode ? Colors.black87 : Colors.white).withOpacity(0.85),
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(center.dx - (textPainter.width / 2), center.dy + 9),
      );
    }
  }

  @override
  bool shouldRepaint(covariant StylizedMapPainter oldDelegate) {
    return oldDelegate.selectedId != selectedId ||
        oldDelegate.pulseScale != pulseScale ||
        oldDelegate.isDarkMode != isDarkMode ||
        oldDelegate.locations.length != locations.length;
  }
}
