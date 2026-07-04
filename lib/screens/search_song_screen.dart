import 'package:flutter/material.dart';

import '../database/database_service.dart';
import '../models/song.dart';
import 'song_detail_screen.dart';
import 'settings_screen.dart';

class SearchSongScreen extends StatefulWidget {
  const SearchSongScreen({super.key});

  @override
  State<SearchSongScreen> createState() =>
      _SearchSongScreenState();
}

class _SearchSongScreenState
    extends State<SearchSongScreen> {

  final DatabaseService
      _databaseService =
      DatabaseService();

  List<Song> allSongs = [];

  List<Song> filteredSongs = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    loadSongs();
  }

  Future<void> loadSongs() async {

    allSongs =
        await _databaseService.getSongs();

    filteredSongs = [];

    setState(() {
      isLoading = false;
    });
  }

  void searchSong(String query) {

    if (query.isEmpty) {

      setState(() {
        filteredSongs = [];
      });

      return;
    }

    final results = allSongs.where(

      (song) {

        final title =
        song.title.toLowerCase();

        final artist =
        song.artist.toLowerCase();

        final keyword =
        query.toLowerCase();

        return title.contains(keyword)
            || artist.contains(keyword);
      },

    ).toList();

    setState(() {
      filteredSongs = results;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Search Your Songs",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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

      bottomNavigationBar:
      BottomNavigationBar(

        type: BottomNavigationBarType.fixed,

        currentIndex: 1,

        items: const [

          BottomNavigationBarItem(

            icon: Icon(
              Icons.home,
            ),

            label: "Home",
          ),

          BottomNavigationBarItem(

            icon: Icon(
              Icons.search,
            ),

            label: "Search",
          ),

          BottomNavigationBarItem(

            icon: Icon(
              Icons.settings,
            ),

            label: "Settings",
          ),
        ],

        onTap:
            (index) {

          if (index == 0) {
            
            Navigator.popUntil(
              context,
              (route) => route.isFirst,
            );
          } else if (index == 2) {

            Navigator.push(

              context,

              MaterialPageRoute(
                builder: (_) => const SettingsScreen(),
              ),
            );
          }
        },
      ),

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search song or artist",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                        ),
                        prefixIcon: Icon(Icons.search, color: Colors.blue.shade600),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onChanged: searchSong,
                    ),
                  ),
                  Expanded(
                    child: filteredSongs.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.music_note, size: 64, color: Colors.blue.shade200),
                                const SizedBox(height: 16),
                                Text(
                                  "Search for a song or artist",
                                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: filteredSongs.length,
                            itemBuilder: (context, index) {
                              final song = filteredSongs[index];
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
                                    child: const Icon(Icons.music_note),
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
                                    Icons.arrow_forward_ios,
                                    size: 16,
                                    color: Colors.blue.shade300,
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SongDetailScreen(song: song),
                                      ),
                                    );
                                  },
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
}