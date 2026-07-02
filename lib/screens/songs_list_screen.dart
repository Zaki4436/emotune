import 'package:flutter/material.dart';
import '../models/song.dart';
import 'search_song_screen.dart';
import 'song_detail_screen.dart';
import 'settings_screen.dart';

class SongsListScreen extends StatelessWidget {
  final List<Map<String, dynamic>> recommendedSongs;
  final String emotion;

  const SongsListScreen({
    super.key,
    required this.recommendedSongs,
    required this.emotion,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Songs For $emotion",
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade800, Colors.blue.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: recommendedSongs.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.music_off, size: 64, color: Colors.blue.shade200),
                    const SizedBox(height: 16),
                    Text(
                      "No recommended songs found.",
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: recommendedSongs.length,
                itemBuilder: (context, index) {
                  final item = recommendedSongs[index];
                  Song song = item["song"] as Song;
                  return Card(
                    elevation: 2,
                    shadowColor: Colors.blue.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        foregroundColor: Colors.blue.shade900,
                        child: Text(
                          "${index + 1}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        song.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "${song.artist}\n${song.genre}",
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      isThreeLine: true,
                      trailing: Icon(
                        Icons.play_circle_fill,
                        size: 36,
                        color: Colors.blue.shade400,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SongDetailScreen(
                              song: song,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}