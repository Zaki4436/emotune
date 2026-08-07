import 'package:flutter/material.dart';

import '../database/database_service.dart';
import '../models/song.dart';
import 'song_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseService _databaseService = DatabaseService();
  late Future<List<Song>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      _historyFuture = _databaseService.getHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recently Song Viewed'),
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade800, Colors.white],
            stops: const [0.1, 0.1],
          ),
        ),
        child: FutureBuilder<List<Song>>(
          future: _historyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.white));
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error loading history: ${snapshot.error}',
                  style: TextStyle(fontSize: screenWidth * 0.04, color: Colors.red),
                ),
              );
            }

            final history = snapshot.data;

            if (history == null || history.isEmpty) {
              return Center(
                child: Text(
                  'Your listening history will appear here.',
                  style: TextStyle(fontSize: screenWidth * 0.04, color: Colors.grey),
                ),
              );
            }

            return ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final song = history[index];
                return Card(
                  margin: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04, vertical: 6),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.05, vertical: 10),
                      title: Text(song.title,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(song.artist),
                      trailing: Icon(Icons.arrow_forward_ios, size: screenWidth * 0.04),
                      onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => SongDetailScreen(song: song)))
                          .then((_) => _loadHistory())),
                );
              },
            );
          },
        ),
      ),
    );
  }
}