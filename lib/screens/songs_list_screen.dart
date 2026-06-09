import 'package:flutter/material.dart';

import '../models/song.dart';
import 'search_song_screen.dart';
import 'song_detail_screen.dart';

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
        automaticallyImplyLeading: false,
        title: Text("Recommended: $emotion"),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: "Search",
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            // Kembali ke skrin utama
            Navigator.popUntil(
              context,
              (route) => route.isFirst,
            );
          } else if (index == 1) {
            // Pergi ke skrin carian lagu
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SearchSongScreen(),
              ),
            );
          }
        },
      ),
      body: recommendedSongs.isEmpty
          ? const Center(
              child: Text("No recommended songs found."),
            )
          : ListView.builder(
              itemCount: recommendedSongs.length,
              itemBuilder: (context, index) {
                final item = recommendedSongs[index];
                Song song = item["song"] as Song;
                double score = item["score"] as double;

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text("${index + 1}"),
                    ),
                    title: Text(song.title),
                    subtitle: Text("${song.artist}\n${song.genre}"),
                    isThreeLine: true,
                    trailing: Text(
                      "${(score * 100).toStringAsFixed(1)}%",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
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
    );
  }
}