import 'package:flutter/material.dart';
import '../models/waste_scan.dart';
import '../models/report.dart';
import '../models/eco_action.dart';
import '../services/database_service.dart';
import '../services/classifier_service.dart';

class AppState extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final ClassifierService _classifier = ClassifierService();

  bool _isDarkMode = false;
  String _currentLanguage = 'en'; // 'en' or 'mr'
  bool _isLoading = true;

  // User Statistics (matching visual reference mockup)
  String _userName = 'Alex';
  int _userLevel = 3;
  int _userXP = 1674;
  double _recycledKg = 3.5;
  double _co2SavedKg = 42.0;
  int _ecoScore = 72;
  int _ecoPoints = 7837;

  List<WasteScan> _scans = [];
  List<EnvironmentalReport> _reports = [];
  List<EcoAction> _actions = [];

  // Getters
  bool get isDarkMode => _isDarkMode;
  String get currentLanguage => _currentLanguage;
  bool get isLoading => _isLoading;

  String get userName => _userName;
  int get userLevel => _userLevel;
  int get userXP => _userXP;
  double get recycledKg => _recycledKg;
  double get co2SavedKg => _co2SavedKg;
  int get ecoScore => _ecoScore;
  int get ecoPoints => _ecoPoints;

  List<WasteScan> get scans => _scans;
  List<EnvironmentalReport> get reports => _reports;
  List<EcoAction> get actions => _actions;

  ClassifierService get classifier => _classifier;

  AppState() {
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _scans = await _db.getScans();
      _reports = await _db.getReports();
      _actions = await _db.getEcoActions();
      final total = await _db.getTotalPoints();
      if (total > 0) {
        _ecoPoints = 7837 + total;
      }
    } catch (e) {
      debugPrint('Error loading db: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setLanguage(String lang) {
    _currentLanguage = lang;
    notifyListeners();
  }

  Future<void> recordScan({
    required String imagePath,
    required ClassificationResult result,
    String? confirmedCategory,
  }) async {
    final scan = WasteScan(
      userId: 'user_01',
      imagePath: imagePath,
      predictedClass: result.label,
      confidence: result.confidence,
      confirmedClass: confirmedCategory ?? result.label,
      syncStatus: 'synced',
      disposalGuidance: result.disposalGuidance,
    );

    await _db.insertScan(scan);
    _scans.insert(0, scan);

    // Add points & update stats
    _recycledKg += 0.25;
    _co2SavedKg += 0.65;
    _ecoPoints += result.pointsAwarded;
    _userXP += result.pointsAwarded * 10;

    final action = EcoAction(
      userId: 'user_01',
      actionType: 'Recycled ${confirmedCategory ?? result.category}',
      points: result.pointsAwarded,
      verificationStatus: 'Verified',
    );
    await _db.insertEcoAction(action);
    _actions.insert(0, action);

    notifyListeners();
  }

  Future<void> submitReport({
    required String category,
    required String description,
    required String area,
    String? imagePath,
    double? latitude,
    double? longitude,
  }) async {
    final report = EnvironmentalReport(
      clientUuid: 'rep_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'user_01',
      category: category,
      description: description,
      area: area,
      imagePath: imagePath,
      latitude: latitude ?? 18.5204,
      longitude: longitude ?? 73.8567,
      status: 'Submitted',
      syncStatus: 'synced',
    );

    await _db.insertReport(report);
    _reports.insert(0, report);

    // Reward points for filing verified report
    _ecoPoints += 50;
    _actions.insert(
      0,
      EcoAction(
        userId: 'user_01',
        actionType: 'Reported $category issue',
        points: 50,
      ),
    );

    notifyListeners();
  }

  Future<void> updateReportStatus(int id, String newStatus) async {
    await _db.updateReportStatus(id, newStatus);
    final idx = _reports.indexWhere((r) => r.id == id);
    if (idx != -1) {
      final old = _reports[idx];
      _reports[idx] = EnvironmentalReport(
        id: old.id,
        clientUuid: old.clientUuid,
        userId: old.userId,
        category: old.category,
        description: old.description,
        area: old.area,
        imagePath: old.imagePath,
        latitude: old.latitude,
        longitude: old.longitude,
        status: newStatus,
        createdAt: old.createdAt,
        syncStatus: old.syncStatus,
      );
      notifyListeners();
    }
  }

  bool redeemReward(int pointsCost) {
    if (_ecoPoints >= pointsCost) {
      _ecoPoints -= pointsCost;
      notifyListeners();
      return true;
    }
    return false;
  }
}
