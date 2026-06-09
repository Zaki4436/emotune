import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/song.dart';

class DatabaseService {

  Future<List<Song>> getSongs() async {

    final db = await database;

    final result =
        await db.query("song");

    print("TOTAL: ${result.length}");

    return result
        .map((e) => Song.fromMap(e))
        .toList();
  }

  static Database? _database;

  Future<Database> get database async {

    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();

    return _database!;
  }

  Future<Database> _initDatabase() async {

    Directory documentsDirectory =
      await getApplicationDocumentsDirectory();

    String path = join(
      documentsDirectory.path,
      "song.db",
    );

    print("DATABASE PATH: $path");

    if (!await File(path).exists()) {

      ByteData data =
          await rootBundle.load(
        "assets/database/song.db",
      );

      List<int> bytes =
          data.buffer.asUint8List();

      await File(path).writeAsBytes(bytes);

      print("DATABASE COPIED");
    }

    print("DATABASE OPENED");

    return await openDatabase(path);
  }

  Future<List<Map<String, dynamic>>>
      getAllSongs() async {

    final db = await database;

    return await db.query("song");
  }
}