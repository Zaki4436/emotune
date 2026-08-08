import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../database/database_service.dart';
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

  final DatabaseService _databaseService = DatabaseService();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  late AnimationController _imageAnimationController;
  late Animation<double> _imageScaleAnimation;

  bool _isFavourite = false;
  bool _isCheckingFavourite = true;

  @override
  void initState() {
    super.initState();

    _databaseService.addSongToHistory(widget.song);
    _checkIfFavourite();

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

  void _checkIfFavourite() async {
    final isFav = await _databaseService.isFavourite(widget.song);
    if (mounted) {
      setState(() {
        _isFavourite = isFav;
        _isCheckingFavourite = false;
      });
    }
  }

  void _toggleFavourite() async {
    final newFavouriteState = !_isFavourite;
    setState(() {
      _isFavourite = newFavouriteState;
    });

    if (newFavouriteState) {
      await _databaseService.addSongToFavourites(widget.song);
    } else {
      await _databaseService.removeSongFromFavourites(widget.song);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _imageAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = screenWidth * 0.56;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundStart = isDark ? const Color(0xFF0F172A) : const Color(0xFFEEF2FF);
    final backgroundMid = isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC);
    final backgroundEnd = isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFFFF);
    final surfaceColor = isDark ? const Color(0xFF111827) : Colors.white;
    final mutedText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final headingColor = isDark ? Colors.white : const Color(0xFF111827);
    final accentColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF4F46E5);
    final softAccent = isDark ? const Color(0xFF1E3A8A) : const Color(0xFFE0E7FF);
    final mainButtonColor = const Color(0xFF4F46E5);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [backgroundStart, backgroundMid, backgroundEnd],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withOpacity(isDark ? 0.12 : 0.08),
                ),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: MediaQuery.of(context).padding.top + 50),
                      FutureBuilder<Map<String, String?>>(
                        future: spotifyService.getSpotifyData(widget.song.title, widget.song.artist),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return SizedBox(
                              height: imageSize,
                              width: imageSize,
                              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                            );
                          }

                          final imageUrl = snapshot.data?["image"];
                          final spotifyUrl = snapshot.data?["spotify"];

                          return Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: surfaceColor.withOpacity(isDark ? 0.95 : 0.98),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.transparent),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
                                      blurRadius: 18,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ScaleTransition(
                                          scale: _imageScaleAnimation,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(24),
                                            child: imageUrl != null
                                                ? Image.network(
                                                    imageUrl,
                                                    height: imageSize,
                                                    width: imageSize,
                                                    fit: BoxFit.cover,
                                                  )
                                                : Container(
                                                    height: imageSize,
                                                    width: imageSize,
                                                    decoration: BoxDecoration(
                                                      color: isDark ? const Color(0xFF334155) : Colors.blue.shade100,
                                                      borderRadius: BorderRadius.circular(24),
                                                    ),
                                                    child: Icon(
                                                      Icons.music_note,
                                                      size: imageSize * 0.38,
                                                      color: isDark ? const Color(0xFF93C5FD) : Colors.blue.shade300,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        if (_isCheckingFavourite)
                                          SizedBox(
                                            width: imageSize,
                                            child: const Center(
                                              child: SizedBox(
                                                height: 18,
                                                width: 18,
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              ),
                                            ),
                                          )
                                        else
                                          GestureDetector(
                                            onTap: _toggleFavourite,
                                            child: Container(
                                              width: imageSize,
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                              decoration: BoxDecoration(
                                                color: _isFavourite
                                                    ? Colors.red.shade500
                                                    : (isDark ? Colors.white.withOpacity(0.12) : Colors.blue.shade50),
                                                borderRadius: BorderRadius.circular(999),
                                                border: Border.all(
                                                  color: _isFavourite
                                                      ? Colors.transparent
                                                      : (isDark ? Colors.white.withOpacity(0.08) : Colors.blue.shade100),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    _isFavourite ? Icons.favorite : Icons.favorite_border,
                                                    size: 18,
                                                    color: _isFavourite ? Colors.white : (isDark ? Colors.white : Colors.blue.shade700),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    _isFavourite ? 'Saved' : 'Add to favourite',
                                                    style: TextStyle(
                                                      color: _isFavourite ? Colors.white : (isDark ? Colors.white : Colors.blue.shade700),
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: softAccent,
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              'Now playing',
                                              style: TextStyle(
                                                color: accentColor,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            widget.song.title,
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: headingColor,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            widget.song.artist,
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: mutedText,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                  decoration: BoxDecoration(
                                                    color: softAccent,
                                                    borderRadius: BorderRadius.circular(999),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (spotifyUrl != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        await launchUrl(Uri.parse(spotifyUrl));
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: mainButtonColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        elevation: 0,
                                      ),
                                      icon: const Icon(Icons.play_circle_fill_rounded, size: 20),
                                      label: const Text('Open in Spotify'),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoPill('Genre', widget.song.genre, accentColor),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildInfoPill('Released', widget.song.releaseDate, accentColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoPill('Album', widget.song.album, accentColor),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildInfoPill(widget.song.explicit ? 'Explicit' : 'Explicit', widget.song.explicit ? 'Yes' : 'No', accentColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: surfaceColor.withOpacity(isDark ? 0.95 : 0.98),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lyrics',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: headingColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 490,
                              child: Scrollbar(
                                child: SingleChildScrollView(
                                  child: Text(
                                    widget.song.lyrics.isNotEmpty ? widget.song.lyrics : 'Lyrics not available.',
                                    textAlign: TextAlign.justify,
                                    style: TextStyle(
                                      fontSize: 15,
                                      height: 1.6,
                                      color: mutedText,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
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
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.blue.shade100),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : const Color(0xFF1E3A8A)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPill(String title, String value, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: accentColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF111827),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF334155) : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: isDark ? const Color(0xFF93C5FD) : Colors.blue.shade600, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black)),
            ],
          ),
        ),
      ],
    );
  }
}