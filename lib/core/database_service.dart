import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models/models.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;
  List<DrillItem>? _webDrills;
  final Map<String, double> _webStats = {};
  final Map<String, Map<String, int>> _webUnitStats = {}; // unit -> {correct: x, total: y}

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database;
    _database = await _initDatabase();
    return _database;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'wits_end.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE unit_stats (
          unit TEXT PRIMARY KEY,
          correct INTEGER,
          total INTEGER
        )
      ''');
    }
    if (oldVersion < 3) {
      // Re-seed the drills table to include crash_course data
      await db.execute('DROP TABLE IF EXISTS drills');
      await db.execute('''
        CREATE TABLE drills (
          id TEXT PRIMARY KEY,
          unit TEXT,
          type TEXT,
          criticality TEXT,
          content TEXT
        )
      ''');
      await _seedDatabase(db);
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE drills (
        id TEXT PRIMARY KEY,
        unit TEXT,
        type TEXT,
        criticality TEXT,
        content TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE stats (
        key TEXT PRIMARY KEY,
        value REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE unit_stats (
        unit TEXT PRIMARY KEY,
        correct INTEGER,
        total INTEGER
      )
    ''');

    await _seedDatabase(db);
  }

  Future<void> _seedDatabase(Database db) async {
    final String response = await rootBundle.loadString('assets/json/tome.json');
    final List<dynamic> data = jsonDecode(response);

    int idCounter = 0;
    for (var unit in data) {
      final String unitName = unit['chapter'] ?? 'General';
      final modules = unit['combat_modules'];
      
      if (modules['matching'] != null) {
        for (var item in modules['matching']) {
          await db.insert('drills', {
            'id': 'matching_${idCounter++}',
            'unit': unitName,
            'type': 'matching',
            'criticality': item['criticality'],
            'content': jsonEncode(item),
          });
        }
      }

      if (modules['multiple_choice'] != null) {
        for (var item in modules['multiple_choice']) {
          await db.insert('drills', {
            'id': 'mcq_${idCounter++}',
            'unit': unitName,
            'type': 'mcq',
            'criticality': item['criticality'],
            'content': jsonEncode(item),
          });
        }
      }

      if (modules['frq_drills'] != null) {
        for (var item in modules['frq_drills']) {
          await db.insert('drills', {
            'id': 'frq_${idCounter++}',
            'unit': unitName,
            'type': 'frq',
            'criticality': item['criticality'],
            'content': jsonEncode(item),
          });
        }
      }
    }
  }

  Future<void> _initWeb() async {
    if (_webDrills != null) return;
    _webDrills = [];
    final String response = await rootBundle.loadString('assets/json/tome.json');
    final List<dynamic> data = jsonDecode(response);

    int idCounter = 0;
    for (var unit in data) {
      final String unitName = unit['chapter'] ?? 'General';
      final modules = unit['combat_modules'];
      
      if (modules['matching'] != null) {
        for (var item in modules['matching']) {
          final mappedItem = Map<String, dynamic>.from(item);
          mappedItem['id'] = 'matching_${idCounter++}';
          mappedItem['unit'] = unitName;
          _webDrills!.add(MatchingItem.fromMap(mappedItem));
        }
      }

      if (modules['multiple_choice'] != null) {
        for (var item in modules['multiple_choice']) {
          final mappedItem = Map<String, dynamic>.from(item);
          mappedItem['id'] = 'mcq_${idCounter++}';
          mappedItem['unit'] = unitName;
          mappedItem['options'] = jsonEncode(item['options']);
          mappedItem['correctAnswer'] = item['correct_answer'];
          mappedItem['explanation'] = item['explanation'];
          _webDrills!.add(MCQItem.fromMap(mappedItem));
        }
      }

      if (modules['frq_drills'] != null) {
        for (var item in modules['frq_drills']) {
          final mappedItem = Map<String, dynamic>.from(item);
          mappedItem['id'] = 'frq_${idCounter++}';
          mappedItem['unit'] = unitName;
          mappedItem['rubricBulletPoints'] = jsonEncode(item['rubric_bullet_points']);
          mappedItem['prompt'] = item['prompt'];
          _webDrills!.add(FRQItem.fromMap(mappedItem));
        }
      }
    }
  }

  Future<List<String>> getUnits() async {
    if (kIsWeb) {
      await _initWeb();
      return _webDrills!.map((e) => e.unit).toSet().toList();
    }
    final db = await database;
    final List<Map<String, dynamic>> maps = await db!.rawQuery('SELECT DISTINCT unit FROM drills');
    return maps.map((e) => e['unit'] as String).toList();
  }

  Future<DrillItem> getRandomDrill({
    List<String>? units,
    List<DrillType>? types,
    List<String>? excludedIds,
    Map<Criticality, int>? weights,
  }) async {
    if (kIsWeb) {
      await _initWeb();
      var pool = _webDrills!;
      if (units != null && units.isNotEmpty) {
        pool = pool.where((e) => units.contains(e.unit)).toList();
      }
      if (types != null && types.isNotEmpty) {
        pool = pool.where((e) => types.contains(e.type)).toList();
      }
      if (excludedIds != null && excludedIds.isNotEmpty) {
        pool = pool.where((e) => !excludedIds.contains(e.id)).toList();
      }
      
      if (pool.isEmpty) throw Exception('No matching drills found');

      return _weightedPick(pool, weights);
    }

    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (units != null && units.isNotEmpty) {
      whereClause += 'unit IN (${List.filled(units.length, '?').join(',')})';
      whereArgs.addAll(units);
    }

    if (types != null && types.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      final typeNames = types.map((e) => e.name).toList();
      whereClause += 'type IN (${List.filled(typeNames.length, '?').join(',')})';
      whereArgs.addAll(typeNames);
    }

    if (excludedIds != null && excludedIds.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'id NOT IN (${List.filled(excludedIds.length, '?').join(',')})';
      whereArgs.addAll(excludedIds);
    }

    final List<Map<String, dynamic>> maps = await db!.query(
      'drills',
      columns: ['id', 'criticality'],
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
    );
    
    if (maps.isEmpty) throw Exception('No drills found with current filters');

    final List<DrillItem> pool = maps.map<DrillItem>((m) => MatchingItem(
      id: m['id'],
      unit: '', 
      criticality: CriticalityExtension.fromString(m['criticality'] ?? 'low'),
      crashCourse: '',
      term: '', 
      definition: ''
    )).toList();

    final selectedStub = _weightedPick(pool, weights);

    final List<Map<String, dynamic>> result = await db.query(
      'drills',
      where: 'id = ?',
      whereArgs: [selectedStub.id],
    );

    final map = result.first;
    final content = jsonDecode(map['content']);
    content['id'] = map['id'];
    content['unit'] = map['unit'];
    content['criticality'] = map['criticality'];

    switch (map['type']) {
      case 'matching':
        return MatchingItem.fromMap(content);
      case 'mcq':
        return MCQItem.fromMap(content);
      case 'frq':
        return FRQItem.fromMap(content);
      default:
        throw Exception('Unknown drill type');
    }
  }

  Future<List<String>> getMatchingDefinitions({String? unit, int limit = 3, String? exclude}) async {
    if (kIsWeb) {
      await _initWeb();
      var pool = _webDrills!
          .whereType<MatchingItem>()
          .where((e) => e.definition != exclude);
      if (unit != null) {
        pool = pool.where((e) => e.unit == unit);
      }
      final list = pool.map((e) => e.definition).toList();
      list.shuffle();
      return list.take(limit).toList();
    }

    final db = await database;
    String where = '';
    List<dynamic> args = [];
    if (unit != null) {
      where = 'unit = ?';
      args.add(unit);
    }
    
    final List<Map<String, dynamic>> maps = await db!.query(
      'drills',
      where: 'type = "matching" ${where.isNotEmpty ? "AND $where" : ""}',
      whereArgs: args,
    );

    final List<String> definitions = [];
    for (var m in maps) {
      final content = jsonDecode(m['content']);
      final def = content['definition'] as String;
      if (def != exclude) definitions.add(def);
    }
    
    definitions.shuffle();
    return definitions.take(limit).toList();
  }

  DrillItem _weightedPick(List<DrillItem> pool, Map<Criticality, int>? customWeights) {
    final weights = customWeights ?? {
      Criticality.high: 50,
      Criticality.medium: 33,
      Criticality.low: 17,
    };

    final grouped = <Criticality, List<DrillItem>>{};
    for (var item in pool) {
      grouped.putIfAbsent(item.criticality, () => []).add(item);
    }

    final availableWeights = <Criticality, int>{};
    int totalAvailableWeight = 0;
    for (var entry in weights.entries) {
      if (grouped.containsKey(entry.key) && grouped[entry.key]!.isNotEmpty) {
        availableWeights[entry.key] = entry.value;
        totalAvailableWeight += entry.value;
      }
    }

    if (totalAvailableWeight == 0) {
      return pool[Random().nextInt(pool.length)];
    }

    final random = Random();
    int r = random.nextInt(totalAvailableWeight);
    int current = 0;
    for (var entry in availableWeights.entries) {
      current += entry.value;
      if (r < current) {
        final categoryPool = grouped[entry.key]!;
        return categoryPool[random.nextInt(categoryPool.length)];
      }
    }

    return pool.first;
  }

  Future<void> updateStat(String key, double value) async {
    if (kIsWeb) {
      _webStats[key] = value;
      return;
    }
    final db = await database;
    await db!.insert(
      'stats',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<double> getStat(String key) async {
    if (kIsWeb) return _webStats[key] ?? 0;
    final db = await database;
    final List<Map<String, dynamic>> maps = await db!.query(
      'stats',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isEmpty) return 0;
    return maps.first['value'] as double;
  }

  Future<void> updateUnitStat(String unit, bool isCorrect, {bool isOverride = false}) async {
    if (kIsWeb) {
      _webUnitStats.putIfAbsent(unit, () => {'correct': 0, 'total': 0});
      if (isOverride) {
        if (isCorrect) _webUnitStats[unit]!['correct'] = (_webUnitStats[unit]!['correct'] ?? 0) + 1;
      } else {
        _webUnitStats[unit]!['total'] = (_webUnitStats[unit]!['total'] ?? 0) + 1;
        if (isCorrect) {
          _webUnitStats[unit]!['correct'] = (_webUnitStats[unit]!['correct'] ?? 0) + 1;
        }
      }
      return;
    }
    final db = await database;
    final List<Map<String, dynamic>> maps = await db!.query(
      'unit_stats',
      where: 'unit = ?',
      whereArgs: [unit],
    );
    
    if (maps.isEmpty) {
      await db.insert('unit_stats', {
        'unit': unit,
        'correct': isCorrect ? 1 : 0,
        'total': isOverride ? 0 : 1, // Should not happen with override first
      });
    } else {
      int correct = (maps.first['correct'] as int) + (isCorrect ? 1 : 0);
      int total = (maps.first['total'] as int) + (isOverride ? 0 : 1);
      await db.update(
        'unit_stats',
        {'correct': correct, 'total': total},
        where: 'unit = ?',
        whereArgs: [unit],
      );
    }
  }

  Future<Map<String, Map<String, int>>> getAllUnitStats() async {
    if (kIsWeb) return _webUnitStats;
    final db = await database;
    final List<Map<String, dynamic>> maps = await db!.query('unit_stats');
    final Map<String, Map<String, int>> results = {};
    for (var map in maps) {
      results[map['unit'] as String] = {
        'correct': map['correct'] as int,
        'total': map['total'] as int,
      };
    }
    return results;
  }

  Future<void> resetStats() async {
    final db = await database;
    await db!.delete('stats');
    await db.delete('unit_stats');
    _webStats.clear();
    _webUnitStats.clear();
  }
}
