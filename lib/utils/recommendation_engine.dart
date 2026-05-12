import 'emotion_profile.dart';

class RecommendationEngine {

  static double calculateScore(
    Map<String, dynamic> song,
    String emotion,
  ) {

    final target = emotionProfiles[emotion]!;

    // ✅ CONVERT TO DOUBLE
    double songEnergy =
        (song['energy'] as num).toDouble();

    double songValence =
        (song['valence'] as num).toDouble();

    double songDance =
        (song['danceability'] as num).toDouble();

    double targetEnergy =
        (target['energy'] as num).toDouble();

    double targetValence =
        (target['valence'] as num).toDouble();

    double targetDance =
        (target['danceability'] as num).toDouble();

    // ✅ SIMILARITY SCORES
    double energyScore =
        1 - (songEnergy - targetEnergy).abs();

    double valenceScore =
        1 - (songValence - targetValence).abs();

    double danceScore =
        1 - (songDance - targetDance).abs();

    // ✅ FINAL WEIGHTED SCORE
    double total =
        (energyScore * 0.4) +
        (valenceScore * 0.4) +
        (danceScore * 0.2);

    return total;
  }
}