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
        title: Text(
          widget.song.title,
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
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
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

                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 15,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            imageUrl,
                            height: 250,
                            width: 250,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )

                    else

                      Container(

                        height: 250,
                        width: 250,

                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.music_note,
                          size: 100,
                          color: Colors.blue.shade300,
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

                          await launchUrl(Uri.parse(spotifyUrl));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1DB954),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 3,
                        ),
                        icon: const Icon(Icons.play_circle_fill),
                        label: const Text("Open in Spotify", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.song.artist,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Text(
                    "Emotion: ${_calculateEmotion(widget.song)}",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 2,
              shadowColor: Colors.blue.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.album, "Album", widget.song.album),
                    const Divider(height: 24),
                    _buildInfoRow(Icons.category, "Genre", widget.song.genre),
                    const Divider(height: 24),
                    _buildInfoRow(Icons.calendar_today, "Released", widget.song.releaseDate),
                    const Divider(height: 24),
                    _buildInfoRow(
                      widget.song.explicit ? Icons.explicit : Icons.check_circle_outline,
                      "Explicit",
                      widget.song.explicit ? "Yes" : "No",
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Lyrics",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shadowColor: Colors.blue.withOpacity(0.1),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  widget.song.lyrics.isNotEmpty ? widget.song.lyrics : "Lyrics not available.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.6,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.blue.shade600, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
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