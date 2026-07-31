import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/song.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  Future<void> addSongToHistory(Song song) async {
    final user = _auth.currentUser;
    if (user == null) {
      print("No user logged in to save history.");
      return;
    }

    final historyRef =
        _firestore.collection('users').doc(user.uid).collection('history');

    // Use a combination of title and artist as doc ID to prevent duplicates
    // and simply update the timestamp.
    final docId =
        '${song.title}_${song.artist}'.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');

    await historyRef.doc(docId).set({
      'song_title': song.title,
      'song_artist': song.artist,
      'visited_at': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Song>> getHistory() async {
    final user = _auth.currentUser;
    if (user == null) {
      print("No user logged in to fetch history.");
      return [];
    }

    final historySnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('history')
        .orderBy('visited_at', descending: true)
        .limit(50)
        .get();

    if (historySnapshot.docs.isEmpty) {
      return [];
    }

    final songIdentifiers = historySnapshot.docs.map((doc) {
      return {
        'title': doc.data()['song_title'] as String,
        'artist': doc.data()['song_artist'] as String,
      };
    }).toList();

    final db = await database;

    final whereClause =
        songIdentifiers.map((_) => '(song = ? AND "Artist(s)" = ?)').join(' OR ');
    final whereArgs =
        songIdentifiers.expand((id) => [id['title']!, id['artist']!]).toList();

    final List<Map<String, dynamic>> songMaps = await db.query(
      'song',
      where: whereClause,
      whereArgs: whereArgs,
    );

    final allFoundSongs = songMaps.map((map) => Song.fromMap(map)).toList();

    // Re-order the songs to match the history order (most recent first).
    final orderedHistory = <Song>[];
    for (final identifier in songIdentifiers) {
      final song = allFoundSongs.where(
        (s) => s.title == identifier['title'] && s.artist == identifier['artist'],
      );
      if (song.isNotEmpty) orderedHistory.add(song.first);
    }

    return orderedHistory;
  }
}