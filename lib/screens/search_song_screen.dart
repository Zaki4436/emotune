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
    extends State<SearchSongScreen> with SingleTickerProviderStateMixin {

  final DatabaseService
      _databaseService =
      DatabaseService();

  List<Song> allSongs = [];

  List<Song> filteredSongs = [];

  bool isLoading = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn));
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
            CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    loadSongs();
  }

  Future<void> loadSongs() async {

    allSongs =
        await _databaseService.getSongs();

    filteredSongs = [];

    setState(() {
      isLoading = false;
      _animationController.forward();
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
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(

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
            colors: [
              Colors.blue.shade800,
              Colors.blue.shade400,
              Colors.white
            ],
            stops: const [0.0, 0.3, 0.3],
          ),
        ),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      SizedBox(height: MediaQuery.of(context).padding.top + screenHeight * 0.02),
                      Text(
                        "Search Your Songs",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: screenWidth * 0.07),
                        textAlign: TextAlign.center,
                      ),
                      Padding(
                        padding: EdgeInsets.all(screenWidth * 0.04),
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
                            contentPadding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
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
                                    Icon(Icons.music_note, size: screenWidth * 0.15, color: Colors.blue.shade200),
                                    SizedBox(height: screenHeight * 0.02),
                                    Text(
                                      "Search for a song or artist",
                                      style: TextStyle(fontSize: screenWidth * 0.04, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03),
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
                                      contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: 8),
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
                                        size: screenWidth * 0.04,
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
              ),
      ),
    );
  }
}