import '../models/song.dart';
import 'emotion_profile.dart';
import 'dart:math';

class RecommendationEngine {

  // COSINE SIMILARITY CALCULATION

  static double cosineSimilarity(
      List<double> a,
      List<double> b,
      ) {

    double dotProduct = 0;
    double magnitudeA = 0;
    double magnitudeB = 0;

    for (int i = 0; i < a.length; i++) {

      dotProduct += a[i] * b[i];

      magnitudeA += a[i] * a[i];

      magnitudeB += b[i] * b[i];
    }

    if (magnitudeA == 0 ||
        magnitudeB == 0) {
      return 0;
    }

    return dotProduct /
        (sqrt(magnitudeA) *
            sqrt(magnitudeB));
  }

  // ==========================
  // RECOMMEND SONGS
  // ==========================
  static List<Map<String, dynamic>> recommendSongs(
      String emotion,
      List<Song> songs,
      ) {

    final profile =
    emotionProfiles[emotion];

    if (profile == null) {
      return [];
    }

    List<Map<String, dynamic>>
    scoredSongs = [];

    for (Song song in songs) {

      List<double> emotionVector = [

        profile["energy"]!,
        profile["danceability"]!,
        profile["positiveness"]!,
        profile["tempo"]!,
        profile["loudness"]!,
        profile["speechiness"]!,
        profile["liveness"]!,
        profile["acousticness"]!,
        profile["instrumentalness"]!,
        profile["popularity"]!,
      ];

      List<double> songVector = [

        song.energy,
        song.danceability,
        song.positiveness,
        song.tempo,
        song.loudness,
        song.speechiness,
        song.liveness,
        song.acousticness,
        song.instrumentalness,
        song.popularity,
      ];

      double similarity =
      cosineSimilarity(
        emotionVector,
        songVector,
      );

      scoredSongs.add({
        "song": song,
        "score": similarity,
      });
    }

    scoredSongs.sort(
          (a, b) =>
          (b["score"] as double)
              .compareTo(
            a["score"] as double,
          ),
    );

    return scoredSongs
        .take(10)
        .toList();
  }
}