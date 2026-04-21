import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:just_audio/just_audio.dart';

class SongDetailScreen extends StatefulWidget {
  final Map song;

  const SongDetailScreen({super.key, required this.song});

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen> {
  final AudioPlayer _player = AudioPlayer();
  bool isPlaying = false;

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

  Future<void> openSpotify() async {
    final Uri url = Uri.parse(widget.song['spotify_url']);

    await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

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
                    song['preview'] == null ? "No Preview ❌" : "Play Preview 🎧",
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
          ],
        ),
      ),
    );
  }
}