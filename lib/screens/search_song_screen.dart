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
        title:
        const Text("Search Songs"),
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

      body: isLoading

          ? const Center(
        child:
        CircularProgressIndicator(),
      )

          : Column(

        children: [

          Padding(

            padding:
            const EdgeInsets.all(12),

            child: TextField(

              decoration:
              InputDecoration(

                hintText:
                "Search song or artist",

                prefixIcon:
                const Icon(
                  Icons.search,
                ),

                border:
                OutlineInputBorder(

                  borderRadius:
                  BorderRadius.circular(
                    12,
                  ),
                ),
              ),

              onChanged:
              searchSong,
            ),
          ),

          Expanded(

            child:
            filteredSongs.isEmpty

                ? const Center(
              child: Text(
                "Search for a song or artist",
              ),
            )

                : ListView.builder(

              itemCount:
              filteredSongs.length,

              itemBuilder:
                  (context,
                  index) {

                final song =
                filteredSongs[
                index];

                return Card(

                  margin:
                  const EdgeInsets
                      .symmetric(

                    horizontal:
                    12,

                    vertical:
                    5,
                  ),

                  child:
                  ListTile(

                    leading:
                    CircleAvatar(

                      child:
                      Text(
                        "${index + 1}",
                      ),
                    ),

                    title:
                    Text(
                      song.title,
                    ),

                    subtitle:
                    Text(
                      "${song.artist}\n${song.genre}",
                    ),

                    isThreeLine:
                    true,

                    trailing:
                    const Icon(
                      Icons
                          .arrow_forward_ios,
                    ),

                    onTap:
                        () {

                      Navigator.push(

                        context,

                        MaterialPageRoute(

                          builder:
                              (_) =>
                              SongDetailScreen(
                                song:
                                song,
                              ),
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
    );
  }
}