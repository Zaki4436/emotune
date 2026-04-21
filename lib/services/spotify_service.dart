import 'dart:convert';
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
        'Authorization': 'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}',
        'Content-Type': 'application/x-www-form-urlencoded',
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
  // 🎵 GET SONGS (WORKING VERSION)
  // ===============================
Future<List<Map<String, dynamic>>> getSongsByEmotion(String emotion) async {
  final token = await _getAccessToken();
  String genre = buildQuery(emotion);

  List allSongs = [];

  for (int offset = 0; offset < 50; offset += 10) {
    final uri = Uri.https(
      'api.spotify.com',
      '/v1/search',
      {
        'q': "${buildQuery(emotion)} ${DateTime.now().millisecond}",
        'type': 'track',
        'limit': '10',   // ✅ MUST be 10
        'offset': offset.toString(),
        'market': 'MY',
      },
    );

    print("🎵 URL: $uri");

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    print("🎵 STATUS: ${response.statusCode}");

    if (response.statusCode != 200) {
      throw Exception("Spotify Error: ${response.body}");
    }

    final data = json.decode(response.body);
    List items = data['tracks']['items'];

    allSongs.addAll(items);
  }

  return allSongs.map<Map<String, dynamic>>((song) {
    return {
      "title": song['name'],
      "artist": song['artists'][0]['name'],
      "album": song['album']['name'],
      "year": song['album']['release_date'],
      "image": song['album']['images'][0]['url'],
      "spotify_url": song['external_urls']['spotify'],
      "artist_id": song['artists'][0]['id'],
      "preview": song['preview_url'],
    };
  }).toList();
}

  // ===============================
  // 🧠 EMOTION → GENRE
  // ===============================
  String buildQuery(String emotion) {
    switch (emotion.toLowerCase()) {
      case "happy":
        return "happy upbeat dance";
      case "sad":
        return "sad emotional piano";
      case "angry":
        return "angry rock metal";
      case "fear":
        return "calm relaxing ambient";
      case "disgust":
        return "lofi chill";
      case "neutral":
        return "top hits";
      case "surprise":
        return "party dance edm";
      default:
        return "top hits";
    }
  }
}