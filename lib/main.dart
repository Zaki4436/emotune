import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'screens/search_song_screen.dart';
import 'provider/theme_provider.dart';
import 'database/database_service.dart';
import 'emotion/emotion_detector.dart';
import 'models/song.dart';
import 'recommendation/recommendation_engine.dart';
import 'screens/songs_list_screen.dart';
import 'screens/login_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';

Future<void> main() async{

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'EmoTune',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF4F46E5),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF7F8FC),
            cardTheme: CardThemeData(
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              foregroundColor: Color(0xFF111827),
              elevation: 0,
              centerTitle: true,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            chipTheme: ChipThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              side: BorderSide.none,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF4F46E5),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF0F172A),
            cardTheme: CardThemeData(
              elevation: 0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          themeMode: themeProvider.themeMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // =========================
  // SERVICES
  // =========================

  final DatabaseService
      _databaseService =
      DatabaseService();

  final EmotionDetector
      _emotionDetector =
      EmotionDetector();

  final ImagePicker picker =
      ImagePicker();

  // =========================
  // VARIABLES
  // =========================

  List<Song> allSongs = [];

  bool isLoading = true;

  bool isAnalyzing = false;

  File? selectedImage;

  String detectedEmotion =
      "No Emotion";

  String? selectedEmotion;

  // =========================
  // INIT
  // =========================

  @override
  void initState() {
    super.initState();

    initialize();
  }

  @override
  void dispose() {
    super.dispose();
  }



  Future<void> initialize() async {

    await _emotionDetector
        .loadModel();

    await loadSongs();
  }

  // =========================
  // LOAD SONGS
  // =========================

  Future<void> loadSongs() async {

    try {

      allSongs =
          await _databaseService
              .getSongs();

      setState(() {
        isLoading = false;
      });

    } catch (e) {

      print(
          "LOAD SONG ERROR: $e");

      setState(() {
        isLoading = false;
      });
    }
  }

  // =========================
  // CAMERA
  // =========================

  Future<void> captureImage() async {

    final pickedFile =
        await picker.pickImage(
      source:
      ImageSource.camera,
    );

    if (pickedFile == null) {
      return;
    }

    File imageFile =
        File(pickedFile.path);

    setState(() {
      selectedImage =
          imageFile;
      isAnalyzing = true;
      detectedEmotion =
          "No Emotion";
    });

    String emotion =
        await _emotionDetector
            .predictEmotion(
      imageFile,
    );

    setState(() {
      isAnalyzing = false;
    });

    setState(() {

      detectedEmotion =
          emotion;

      selectedEmotion =
          emotion;
      selectedImage =
          imageFile;
    });
  }

  // =========================
  // GALLERY
  // =========================

  Future<void> pickImage() async {

    final pickedFile =
        await picker.pickImage(
      source:
      ImageSource.gallery,
    );

    if (pickedFile == null) {
      return;
    }

    File imageFile =
        File(pickedFile.path);

    setState(() {
      selectedImage =
          imageFile;
      isAnalyzing = true;
      detectedEmotion =
          "No Emotion";
    });

    String emotion =
        await _emotionDetector
            .predictEmotion(
      imageFile,
    );

    setState(() {
      isAnalyzing = false;
    });

    if (emotion ==
        "No Face") {
      return;
    }

    setState(() {

      detectedEmotion =
          emotion;

      selectedEmotion =
          emotion;
    });
  }

  // =========================
  // MANUAL EMOTION
  // =========================

  void updateRecommendation(
      String emotion) {

    setState(() {

      selectedEmotion =
          emotion;
      selectedImage =
          null;
    });

    final recommendedSongs =
        RecommendationEngine
            .recommendSongs(
      emotion,
      allSongs,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SongsListScreen(
          recommendedSongs: recommendedSongs,
          emotion: emotion,
        ),
      ),
    );
  }

  // =========================
  // UI HELPERS
  // =========================

  Color _getEmotionColor(String emotion) {
    switch (emotion) {
      case "Happy": return Colors.orange;
      case "Sad": return Colors.blueGrey;
      case "Angry": return Colors.red;
      case "Fear": return Colors.deepPurple;
      case "Neutral": return Colors.grey.shade600;
      case "Surprise": return Colors.teal;
      case "Disgust": return Colors.green;
      default: return Colors.blue;
    }
  }

  IconData _getEmotionIcon(String emotion) {
    switch (emotion) {
      case "Happy": return Icons.sentiment_very_satisfied;
      case "Sad": return Icons.sentiment_dissatisfied;
      case "Angry": return Icons.mood_bad;
      case "Fear": return Icons.sentiment_very_dissatisfied;
      case "Neutral": return Icons.sentiment_neutral;
      case "Surprise": return Icons.emoji_emotions;
      case "Disgust": return Icons.sick;
      default: return Icons.face;
    }
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.95),
            Theme.of(context).colorScheme.secondary.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Text(
                  "Find the soundtrack for your moment",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Capture your mood, pick a feeling, or browse instantly for the perfect playlist.",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.92),
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.music_note_rounded,
              size: 34,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCaptureSection() {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            icon: Icons.camera_alt_rounded,
            title: "Camera",
            subtitle: "Take a photo",
            color: Theme.of(context).colorScheme.primary,
            onTap: captureImage,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionCard(
            icon: Icons.photo_library_rounded,
            title: "Gallery",
            subtitle: "Upload photo",
            color: Theme.of(context).colorScheme.secondary,
            onTap: pickImage,
          ),
        ),
      ],
    );
  }

  Widget _buildEmotionSelector() {
    final emotions = ["Happy", "Sad", "Angry", "Fear", "Neutral", "Surprise", "Disgust"];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Choose a mood",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: emotions.map((emotion) {
              final emotionColor = _getEmotionColor(emotion);
              final emotionIcon = _getEmotionIcon(emotion);
              final isSelected = selectedEmotion == emotion;

              return ChoiceChip(
                label: Text(emotion),
                avatar: Icon(emotionIcon, size: 18, color: emotionColor),
                selected: isSelected,
                selectedColor: emotionColor.withOpacity(0.14),
                onSelected: (_) => updateRecommendation(emotion),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                side: BorderSide(color: emotionColor.withOpacity(0.25)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    if (selectedImage == null) return const SizedBox.shrink();

    final statusColor = _getEmotionColor(detectedEmotion);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.file(
              selectedImage!,
              height: MediaQuery.of(context).size.height * 0.24,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome_rounded, color: statusColor, size: 18),
                const SizedBox(width: 8),
                Text(
                  isAnalyzing ? "Analyzing your mood..." : "Mood detected: $detectedEmotion",
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (isAnalyzing)
            const SizedBox(
              width: double.infinity,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else
            Column(
              children: [
                Text(
                  detectedEmotion == "No Emotion" || detectedEmotion == "No Face"
                      ? "We couldn’t detect a clear mood yet. Try another photo or choose manually."
                      : "Your selected mood is ready. Tap below to explore songs.",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                if (detectedEmotion != "No Emotion" && detectedEmotion != "No Face")
                  ElevatedButton.icon(
                    icon: const Icon(Icons.music_note_rounded),
                    onPressed: () {
                      final recommendedSongs = RecommendationEngine.recommendSongs(
                        detectedEmotion,
                        allSongs,
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SongsListScreen(
                            recommendedSongs: recommendedSongs,
                            emotion: detectedEmotion,
                          ),
                        ),
                      );
                    },
                    label: const Text("Discover songs"),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [color.withOpacity(0.9), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.18),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, size: 28, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
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
    );
  }

  // =========================
  // UI
  // =========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("EmoTune"),
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/app icon/logo no bg.png',
              width: 36,
              height: 36,
              fit: BoxFit.contain,
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                selectedImage = null;
                detectedEmotion = "No Emotion";
                selectedEmotion = null;
                isAnalyzing = false;
              });
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.96),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              currentIndex: 0,
              backgroundColor: Colors.transparent,
              selectedItemColor: Theme.of(context).colorScheme.primary,
              unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
              showUnselectedLabels: true,
              elevation: 0,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Home"),
                BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: "Search"),
                BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: "Settings"),
              ],
              onTap: (index) {
            if (index == 0) {
              if (selectedImage != null || selectedEmotion != null) {
                setState(() {
                  selectedImage = null;
                  detectedEmotion = "No Emotion";
                  selectedEmotion = null;
                });
              }
            } else if (index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchSongScreen()),
              );
            } else if (index == 2) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            }
          },
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.08),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeaderCard(),
                      const SizedBox(height: 18),
                      _buildImageCaptureSection(),
                      const SizedBox(height: 18),
                      _buildEmotionSelector(),
                      const SizedBox(height: 18),
                      _buildImagePreview(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}