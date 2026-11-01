import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/waste_scan.dart';
import '../models/report.dart';
import '../models/eco_action.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ecovision_ai.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // waste_scans
    await db.execute('''
      CREATE TABLE waste_scans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        image_path TEXT,
        predicted_class TEXT,
        confidence REAL,
        confirmed_class TEXT,
        created_at TEXT,
        sync_status TEXT,
        disposal_guidance TEXT
      )
    ''');

    // reports
    await db.execute('''
      CREATE TABLE reports (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_uuid TEXT UNIQUE,
        user_id TEXT,
        category TEXT,
        description TEXT,
        image_path TEXT,
        area TEXT,
        latitude REAL,
        longitude REAL,
        status TEXT,
        created_at TEXT,
        sync_status TEXT
      )
    ''');

    // eco_actions
    await db.execute('''
      CREATE TABLE eco_actions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT,
        action_type TEXT,
        points INTEGER,
        verification_status TEXT,
        created_at TEXT
      )
    ''');

    // Seed default starter eco actions
    await db.insert('eco_actions', {
      'user_id': 'user_01',
      'action_type': 'Segregated Plastic & Dry Waste',
      'points': 50,
      'verification_status': 'Verified',
      'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
    });
    await db.insert('eco_actions', {
      'user_id': 'user_01',
      'action_type': 'Reported Illegal Plastic Dump',
      'points': 100,
      'verification_status': 'Verified',
      'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
    });

    // Seed default sample scans
    await db.insert('waste_scans', {
      'user_id': 'user_01',
      'image_path': '',
      'predicted_class': 'Plastic Bottle',
      'confidence': 0.94,
      'confirmed_class': 'Plastic Bottle',
      'created_at': DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
      'sync_status': 'synced',
      'disposal_guidance': 'Empty completely, crush, and place in Blue Recycling Bin.',
    });
    await db.insert('waste_scans', {
      'user_id': 'user_01',
      'image_path': '',
      'predicted_class': 'Cardboard Packaging',
      'confidence': 0.89,
      'confirmed_class': 'Cardboard Packaging',
      'created_at': DateTime.now().subtract(const Duration(hours: 26)).toIso8601String(),
      'sync_status': 'synced',
      'disposal_guidance': 'Flatten boxes and keep dry before placing in Dry Waste collection.',
    });

    // Seed default reports
    await db.insert('reports', {
      'client_uuid': 'init_report_01',
      'user_id': 'user_01',
      'category': 'Plastic Overflow',
      'description': 'Overflowing plastic waste bins near the Science & Tech quadrangle.',
      'image_path': null,
      'area': 'North Campus Quadrangle',
      'latitude': 18.5204,
      'longitude': 73.8567,
      'status': 'Under Review',
      'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      'sync_status': 'synced',
    });
  }

  // Waste Scans CRUD
  Future<int> insertScan(WasteScan scan) async {
    final db = await database;
    return await db.insert('waste_scans', scan.toMap());
  }

  Future<List<WasteScan>> getScans() async {
    final db = await database;
    final maps = await db.query('waste_scans', orderBy: 'created_at DESC');
    return maps.map((m) => WasteScan.fromMap(m)).toList();
  }

  // Reports CRUD
  Future<int> insertReport(EnvironmentalReport report) async {
    final db = await database;
    return await db.insert(
      'reports',
      report.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<EnvironmentalReport>> getReports() async {
    final db = await database;
    final maps = await db.query('reports', orderBy: 'created_at DESC');
    return maps.map((m) => EnvironmentalReport.fromMap(m)).toList();
  }

  Future<int> updateReportStatus(int id, String newStatus) async {
    final db = await database;
    return await db.update(
      'reports',
      {'status': newStatus},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Eco Actions & Points
  Future<int> insertEcoAction(EcoAction action) async {
    final db = await database;
    return await db.insert('eco_actions', action.toMap());
  }

  Future<List<EcoAction>> getEcoActions() async {
    final db = await database;
    final maps = await db.query('eco_actions', orderBy: 'created_at DESC');
    return maps.map((m) => EcoAction.fromMap(m)).toList();
  }

  Future<int> getTotalPoints() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT SUM(points) as total FROM eco_actions WHERE verification_status = 'Verified'"
    );
    final total = result.first['total'] as int?;
    return total ?? 0;
  }
}
