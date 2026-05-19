import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;

class SpotifyService {

  final String clientId =
      "7f7fbb3ab75a4df89cce0ee469699deb";

  final String clientSecret =
      "2627580223474a0c953dcafbfeb0509a";

  // ===============================
  // 🔐 GET ACCESS TOKEN
  // ===============================
  Future<String> _getAccessToken() async {

    final response = await http.post(
      Uri.parse(
        'https://accounts.spotify.com/api/token',
      ),

      headers: {

        'Authorization':
        'Basic ${base64Encode(
            utf8.encode(
                '$clientId:$clientSecret'))}',

        'Content-Type':
        'application/x-www-form-urlencoded',
      },

      body: {
        'grant_type':
        'client_credentials',
      },
    );

    if (response.statusCode != 200) {

      throw Exception(
        "Failed to get token",
      );
    }

    final data =
    json.decode(response.body);

    return data['access_token'];
  }

  // ===============================
  // 🎵 FETCH SONGS
  // ===============================
  Future<List<Map<String, dynamic>>>
  getSongsByEmotion(
      String emotion,
      ) async {

    final token =
    await _getAccessToken();

    List allSongs = [];

    // 🎯 SEARCH QUERY
    String query =
    buildQuery(emotion);

    for (int offset = 0;
    offset < 50;
    offset += 10) {

      final uri = Uri.https(
        'api.spotify.com',
        '/v1/search',
        {

          'q': query,

          'type': 'track',

          'limit': '10',

          'offset':
          offset.toString(),

          'market': 'MY',
        },
      );

      final response = await http.get(
        uri,

        headers: {

          'Authorization':
          'Bearer $token',
        },
      );

      if (response.statusCode != 200) {

        throw Exception(
          "Spotify Error: ${response.body}",
        );
      }

      final data =
      json.decode(response.body);

      List items =
      data['tracks']['items'];

      allSongs.addAll(items);
    }

    List<Map<String, dynamic>>
    finalSongs = [];

    // ===============================
    // 🎵 LOOP SONGS
    // ===============================
    for (var song in allSongs) {

      String artistId =
      song['artists'][0]['id'];

      String trackId =
      song['id'];

      // ===============================
      // 🎤 GET ARTIST DETAILS
      // ===============================
      final artistResponse =
      await http.get(

        Uri.parse(
          'https://api.spotify.com/v1/artists/$artistId',
        ),

        headers: {

          'Authorization':
          'Bearer $token',
        },
      );

      List genres = [];

      if (artistResponse.statusCode
          == 200) {

        final artistData =
        json.decode(
          artistResponse.body,
        );

        genres =
            artistData['genres']
                ?? [];
      }

      // ===============================
      // 🎧 GET AUDIO FEATURES
      // ===============================
      final audioResponse =
      await http.get(

        Uri.parse(
          'https://api.spotify.com/v1/audio-features/$trackId',
        ),

        headers: {

          'Authorization':
          'Bearer $token',
        },
      );

      Map<String, dynamic>
      audioFeatures = {};

      if (audioResponse.statusCode
          == 200) {

        audioFeatures =
        json.decode(
          audioResponse.body,
        );
      }

      // ===============================
      // 🎵 FINAL SONG DATA
      // ===============================
      finalSongs.add({

        // 🎵 BASIC DETAILS
        "title":
        song['name'],

        "artist":
        song['artists'][0]['name'],

        "album":
        song['album']['name'],

        "year":
        song['album']
        ['release_date'],

        "explicit":
        song['explicit'],

        "spotify_url":
        song['external_urls']
        ['spotify'],

        "image":
        song['album']['images'][0]
        ['url'],

        "genre":
        genres.isNotEmpty
            ? genres.join(', ')
            : "Unknown",

        "preview":
        song['preview_url'],

        "artist_id":
        artistId,

        // 🎯 REAL AUDIO FEATURES
        "danceability":
        (audioFeatures[
        'danceability']
        ?? 0.0)
            .toDouble(),

        "energy":
        (audioFeatures[
        'energy']
        ?? 0.0)
            .toDouble(),

        "valence":
        (audioFeatures[
        'valence']
        ?? 0.0)
            .toDouble(),

        "tempo":
        ((audioFeatures[
        'tempo']
        ?? 0.0) / 200)
            .toDouble(),

        "loudness":
        (((audioFeatures[
        'loudness']
        ?? -60.0) + 60)
            / 60)
            .toDouble(),

        "speechiness":
        (audioFeatures[
        'speechiness']
        ?? 0.0)
            .toDouble(),

        "acousticness":
        (audioFeatures[
        'acousticness']
        ?? 0.0)
            .toDouble(),

        "instrumentalness":
        (audioFeatures[
        'instrumentalness']
        ?? 0.0)
            .toDouble(),

        "liveness":
        (audioFeatures[
        'liveness']
        ?? 0.0)
            .toDouble(),

        "popularity":
        ((song['popularity']
        ?? 50) / 100)
            .toDouble(),
      });
    }

    return finalSongs;
  }

  // ===============================
  // 🔎 SEARCH SONGS
  // ===============================
  Future<List<Map<String, dynamic>>>
  searchSongs(
      String query,
      ) async {

    final token =
    await _getAccessToken();

    final uri = Uri.https(
      'api.spotify.com',
      '/v1/search',
      {

        'q': query,

        'type': 'track',

        'limit': '10',

        'market': 'MY',
      },
    );

    final response = await http.get(
      uri,

      headers: {

        'Authorization':
        'Bearer $token',
      },
    );

    if (response.statusCode != 200) {

      throw Exception(
        "Spotify Error: ${response.body}",
      );
    }

    final data =
    json.decode(response.body);

    List items =
    data['tracks']['items'];

    return items.map<
        Map<String, dynamic>>((song) {

      return {

        "title":
        song['name'],

        "artist":
        song['artists'][0]['name'],

        "album":
        song['album']['name'],

        "year":
        song['album']
        ['release_date'],

        "explicit":
        song['explicit'],

        "spotify_url":
        song['external_urls']
        ['spotify'],

        "image":
        song['album']['images'][0]
        ['url'],

        "preview":
        song['preview_url'],
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

      final response =
      await http.get(url);

      if (response.statusCode
          == 200) {

        final data =
        json.decode(response.body);

        return data['lyrics']
            ?? "Lyrics not available";

      } else {

        return "Lyrics not available";
      }

    } catch (e) {

      return "Error loading lyrics";
    }
  }

  // ===============================
  // 🎭 EMOTION QUERY
  // ===============================
  String buildQuery(
      String emotion,
      ) {

    switch (
    emotion.toLowerCase()) {

      case "happy":
        return "happy upbeat pop";

      case "sad":
        return "sad emotional piano";

      case "angry":
        return "rock metal intense";

      case "fear":
        return "calm relaxing ambient";

      case "surprise":
        return "party edm dance";

      case "neutral":
        return "top hits";

      case "disgust":
        return "lofi chill";

      default:
        return "top hits";
    }
  }
}