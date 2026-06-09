import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/song.dart';
import '../service/spotify_service.dart';

class SongDetailScreen
    extends StatefulWidget {

  final Song song;

  const SongDetailScreen({
    super.key,
    required this.song,
  });

  @override
  State<SongDetailScreen>
      createState() =>
      _SongDetailScreenState();
}

class _SongDetailScreenState
    extends State<SongDetailScreen> {

  final SpotifyService
      spotifyService =
      SpotifyService();

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title:
        Text(widget.song.title),
      ),

      body:
      SingleChildScrollView(

        padding:
        const EdgeInsets.all(16),

        child: Column(

          crossAxisAlignment:
          CrossAxisAlignment.center,

          children: [

            FutureBuilder<
                Map<String, String?>>(

              future:
              spotifyService
                  .getSpotifyData(

                widget.song.title,

                widget.song.artist,
              ),

              builder:
                  (context, snapshot) {

                if (snapshot.connectionState ==
                    ConnectionState
                        .waiting) {

                  return const Center(
                    child:
                    CircularProgressIndicator(),
                  );
                }

                final imageUrl =
                snapshot.data?[
                "image"];

                final spotifyUrl =
                snapshot.data?[
                "spotify"];

                return Column(

                  children: [

                    if (imageUrl !=
                        null)

                      ClipRRect(

                        borderRadius:
                        BorderRadius.circular(
                          20,
                        ),

                        child:
                        Image.network(

                          imageUrl,

                          height: 250,

                          width: 250,

                          fit:
                          BoxFit.cover,
                        ),
                      )

                    else

                      Container(

                        height: 250,
                        width: 250,

                        decoration:
                        BoxDecoration(

                          color:
                          Colors.grey,

                          borderRadius:
                          BorderRadius.circular(
                            20,
                          ),
                        ),

                        child:
                        const Icon(

                          Icons.music_note,

                          size: 100,
                        ),
                      ),

                    const SizedBox(
                      height: 15,
                    ),

                    if (spotifyUrl !=
                        null)

                      ElevatedButton.icon(

                        onPressed:
                            () async {

                          await launchUrl(
                            Uri.parse(
                              spotifyUrl,
                            ),
                          );
                        },

                        icon:
                        const Icon(
                          Icons.music_note,
                        ),

                        label:
                        const Text(
                          "Open in Spotify",
                        ),
                      ),
                  ],
                );
              },
            ),

            const SizedBox(
              height: 20,
            ),

            Text(

              widget.song.title,

              textAlign:
              TextAlign.center,

              style:
              const TextStyle(

                fontSize: 24,

                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Text(
              "Artist: ${widget.song.artist}",
            ),

            Text(
              "Album: ${widget.song.album}",
            ),

            Text(
              "Genre: ${widget.song.genre}",
            ),

            Text(
              "Release Date: ${widget.song.releaseDate}",
            ),

            Text(
              widget.song.explicit
                  ? "Explicit: Yes"
                  : "Explicit: No",
            ),

            const SizedBox(
              height: 20,
            ),

            const Divider(),

            const SizedBox(
              height: 10,
            ),

            const Text(

              "Audio Features",

              style: TextStyle(

                fontSize: 20,

                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 15,
            ),

            buildFeature(
              "Energy",
              widget.song.energy,
            ),

            buildFeature(
              "Danceability",
              widget.song.danceability,
            ),

            buildFeature(
              "Positiveness",
              widget.song.positiveness,
            ),

            buildFeature(
              "Tempo",
              widget.song.tempo,
            ),

            buildFeature(
              "Loudness",
              widget.song.loudness,
            ),

            buildFeature(
              "Speechiness",
              widget.song.speechiness,
            ),

            buildFeature(
              "Liveness",
              widget.song.liveness,
            ),

            buildFeature(
              "Acousticness",
              widget.song.acousticness,
            ),

            buildFeature(
              "Instrumentalness",
              widget.song.instrumentalness,
            ),

            buildFeature(
              "Popularity",
              widget.song.popularity,
            ),

            const SizedBox(
              height: 20,
            ),

            const Divider(),

            const SizedBox(
              height: 10,
            ),

            const Text(

              "Lyrics",

              style: TextStyle(

                fontSize: 20,

                fontWeight:
                FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 10,
            ),

            Text(
              widget.song.lyrics,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFeature(
      String title,
      double value,
      ) {

    return Padding(

      padding:
      const EdgeInsets.symmetric(
        vertical: 4,
      ),

      child: Row(

        mainAxisAlignment:
        MainAxisAlignment
            .spaceBetween,

        children: [

          Text(title),

          Text(
            value
                .toStringAsFixed(0),
          ),
        ],
      ),
    );
  }
}