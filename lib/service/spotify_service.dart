import 'dart:convert';
import 'package:http/http.dart' as http;

class SpotifyService {

  final String clientId =
      "7f7fbb3ab75a4df89cce0ee469699deb";

  final String clientSecret =
      "2627580223474a0c953dcafbfeb0509a";

  Future<String> _getAccessToken() async {

    final response =
        await http.post(

      Uri.parse(
        "https://accounts.spotify.com/api/token",
      ),

      headers: {

        "Authorization":
            "Basic ${base64Encode(
          utf8.encode(
            "$clientId:$clientSecret",
          ),
        )}",

        "Content-Type":
            "application/x-www-form-urlencoded",
      },

      body: {
        "grant_type":
            "client_credentials",
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
          "Failed to get Spotify token");
    }

    final data =
        jsonDecode(response.body);

    return data["access_token"];
  }

  Future<Map<String, String?>> getSpotifyData(
      String title,
      String artist,
      ) async {

    try {

      final token =
          await _getAccessToken();

      final response =
          await http.get(

        Uri.parse(
          "https://api.spotify.com/v1/search"
              "?q=${Uri.encodeComponent("$title $artist")}"
              "&type=track"
              "&limit=1",
        ),

        headers: {
          "Authorization":
              "Bearer $token",
        },
      );

      if (response.statusCode != 200) {

        return {
          "image": null,
          "spotify": null,
        };
      }

      final data =
          jsonDecode(response.body);

      final items =
          data["tracks"]["items"];

      if (items.isEmpty) {

        return {
          "image": null,
          "spotify": null,
        };
      }

      return {

        "image":

        items[0]
        ["album"]
        ["images"][0]
        ["url"],

        "spotify":

        items[0]
        ["external_urls"]
        ["spotify"],
      };

    } catch (e) {

      return {
        "image": null,
        "spotify": null,
      };
    }
  }
}