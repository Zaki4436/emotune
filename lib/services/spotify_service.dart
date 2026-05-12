import 'dart:convert';
import 'dart:async';
import 'dart:math';

import 'package:http/http.dart' as http;

class SpotifyService {

  final String clientId = "7f7fbb3ab75a4df89cce0ee469699deb";
  final String clientSecret = "2627580223474a0c953dcafbfeb0509a";

  // ===============================
  // 🔐 GET ACCESS TOKEN
  // ===============================
  Future<String> _getAccessToken() async {

    final response = await http.post(
      Uri.parse('https://accounts.spotify.com/api/token'),

      headers: {
        'Authorization':
        'Basic ${base64Encode(
            utf8.encode('$clientId:$clientSecret'))}',

        'Content-Type':
        'application/x-www-form-urlencoded',
      },

      body: {
        'grant_type': 'client_credentials',
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to get token");
    }

    final data = json.decode(response.body);

    return data['access_token'];
  }

  // ===============================
  // 🎵 FETCH SONGS
  // ===============================
  Future<List<Map<String, dynamic>>>
  getSongsByEmotion(String emotion) async {

    final token = await _getAccessToken();

    List allSongs = [];

    for (int offset = 0; offset < 50; offset += 10) {

      final uri = Uri.https(
        'api.spotify.com',
        '/v1/search',
        {
          'q': 'top hits',
          'type': 'track',
          'limit': '10',
          'offset': offset.toString(),
          'market': 'MY',
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception("Spotify Error");
      }

      final data = json.decode(response.body);

      List items = data['tracks']['items'];

      allSongs.addAll(items);
    }

    Random random = Random();

    return allSongs.map<Map<String, dynamic>>((song) {

      double popularity =
          ((song['popularity'] ?? 50) / 100);

      double energy =
          (0.5 + random.nextDouble() * 0.5);

      double valence =
          (0.3 + random.nextDouble() * 0.7);

      double danceability =
          (0.4 + random.nextDouble() * 0.6);

      return {

        "title": song['name'],

        "artist":
        song['artists'][0]['name'],

        "album":
        song['album']['name'],

        "year":
        song['album']['release_date'],

        "image":
        song['album']['images'][0]['url'],

        "spotify_url":
        song['external_urls']['spotify'],

        "artist_id":
        song['artists'][0]['id'],

        "preview":
        song['preview_url'],

        // 🎯 CONTENT FEATURES
        "energy": energy,
        "valence": valence,
        "danceability": danceability,

        "popularity": popularity,
      };

    }).toList();
  }

  // ===============================
  // 🎤 GET LYRICS
  // ===============================
  Future<String> getLyrics(
      String artist,
      String title,
      ) async {

    try {

      final url = Uri.parse(
        "https://api.lyrics.ovh/v1/"
            "${Uri.encodeComponent(artist)}/"
            "${Uri.encodeComponent(title)}",
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {

        final data = json.decode(response.body);

        return data['lyrics']
            ?? "Lyrics not available";

      } else {

        return "Lyrics not available";

      }

    } catch (e) {

      return "Error loading lyrics";

    }
  }
}