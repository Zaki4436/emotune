import 'dart:math' as math;
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

              "Emotion",

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
              _calculateEmotion(widget.song),
              style: const TextStyle(
                fontSize: 18,
                color: Colors.blue,
              ),
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

  String _calculateEmotion(Song song) {
    final Map<String, List<double>> emotionVectors = {
      "Happy": [0.8, 0.8, 0.8, 0.1, 0.2, 0.1, 0.0],
      "Sad": [0.2, 0.3, 0.2, 0.0, 0.1, 0.8, 0.1],
      "Angry": [0.9, 0.4, 0.2, 0.2, 0.3, 0.0, 0.1],
      "Fear": [0.3, 0.3, 0.2, 0.1, 0.2, 0.6, 0.4],
      "Neutral": [0.5, 0.5, 0.5, 0.1, 0.2, 0.5, 0.2],
      "Surprise": [0.7, 0.6, 0.6, 0.2, 0.3, 0.2, 0.1],
      "Disgust": [0.4, 0.4, 0.3, 0.2, 0.2, 0.4, 0.2],
    };

    List<double> songVector = [
      song.energy,
      song.danceability,
      song.positiveness,
      song.speechiness,
      song.liveness,
      song.acousticness,
      song.instrumentalness,
    ];

    String bestEmotion = "Unknown";
    double maxSimilarity = -1.0;

    for (var entry in emotionVectors.entries) {
      double sim = _cosineSimilarity(songVector, entry.value);
      if (sim > maxSimilarity) {
        maxSimilarity = sim;
        bestEmotion = entry.key;
      }
    }

    return bestEmotion;
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA == 0 || normB == 0) return 0.0;
    return dotProduct / (math.sqrt(normA) * math.sqrt(normB));
  }
}