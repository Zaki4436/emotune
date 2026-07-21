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
    extends State<SongDetailScreen> with TickerProviderStateMixin {

  final SpotifyService
      spotifyService =
      SpotifyService();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  late AnimationController _imageAnimationController;
  late Animation<double> _imageScaleAnimation;

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
    _animationController.forward();

    _imageAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _imageScaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _imageAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _imageAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade800,
              Colors.blue.shade400,
              Colors.white
            ],
            stops: const [0.0, 0.4, 0.4],
          ),
        ),
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: MediaQuery.of(context).padding.top + 20),
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
                            return const SizedBox(
                              height: 250,
                              child: Center(
                                child:
                                CircularProgressIndicator(color: Colors.white),
                              ),
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
                              ScaleTransition(
                                scale: _imageScaleAnimation,
                                child: Container(
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
                                    child: imageUrl != null
                                        ? Image.network(
                                            imageUrl,
                                            height: 250,
                                            width: 250,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
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
                                  ),
                                ),
                              ),
                              const SizedBox(
                                height: 25,
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
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 5,
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
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
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