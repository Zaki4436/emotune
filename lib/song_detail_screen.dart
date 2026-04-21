import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;

class SongDetailScreen extends StatefulWidget {
  final Map song;

  const SongDetailScreen({super.key, required this.song});

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen> {
  final AudioPlayer _player = AudioPlayer();

  bool isPlaying = false;
  bool isLoadingLyrics = false;
  String lyrics = "Loading lyrics...";

  // ===============================
  // 🎧 PLAY PREVIEW
  // ===============================
  Future<void> playPreview() async {
    final url = widget.song['preview'];

    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No preview available ❌")),
      );
      return;
    }

    await _player.setUrl(url);
    _player.play();

    setState(() => isPlaying = true);
  }

  Future<void> stopPreview() async {
    await _player.stop();
    setState(() => isPlaying = false);
  }

  // ===============================
  // 🎵 OPEN SPOTIFY
  // ===============================
  Future<void> openSpotify() async {
    final Uri url = Uri.parse(widget.song['spotify_url']);

    await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );
  }

  // ===============================
  // 🎤 FETCH LYRICS (Lyrics.ovh)
  // ===============================
  Future<void> fetchLyrics() async {
    setState(() => isLoadingLyrics = true);

    try {
      final artist = widget.song['artist'];
      final title = widget.song['title'];

      final url = Uri.parse(
        "https://api.lyrics.ovh/v1/${Uri.encodeComponent(artist)}/${Uri.encodeComponent(title)}",
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          lyrics = data['lyrics'] ?? "No lyrics found";
          isLoadingLyrics = false;
        });
      } else {
        setState(() {
          lyrics = "Lyrics not available ❌";
          isLoadingLyrics = false;
        });
      }
    } catch (e) {
      setState(() {
        lyrics = "Error loading lyrics ❌";
        isLoadingLyrics = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchLyrics(); // 🔥 AUTO LOAD LYRICS
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  // ===============================
  // 🎨 UI
  // ===============================
  @override
  Widget build(BuildContext context) {
    final song = widget.song;

    return Scaffold(
      appBar: AppBar(title: Text(song['title'])),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Image.network(song['image'], height: 200),

            const SizedBox(height: 20),

            Text(
              song['title'],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            Text("Artist: ${song['artist']}"),
            Text("Album: ${song['album']}"),
            Text("Year: ${song['year']}"),

            const SizedBox(height: 20),

            // 🎧 PREVIEW BUTTON
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: song['preview'] == null ? null : playPreview,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(
                    song['preview'] == null
                        ? "No Preview ❌"
                        : "Play Preview 🎧",
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: stopPreview,
                  icon: const Icon(Icons.stop),
                  label: const Text("Stop"),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 🎵 SPOTIFY BUTTON
            ElevatedButton(
              onPressed: openSpotify,
              child: const Text("Open in Spotify 🎧"),
            ),

            const SizedBox(height: 20),

            // 🎤 LYRICS SECTION
            const Text(
              "Lyrics 🎤",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: isLoadingLyrics
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Text(
                        lyrics,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}