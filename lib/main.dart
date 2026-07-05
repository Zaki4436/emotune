import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'screens/search_song_screen.dart';
import 'database/database_service.dart';
import 'emotion/emotion_detector.dart';
import 'models/song.dart';
import 'recommendation/recommendation_engine.dart';
import 'screens/songs_list_screen.dart';
import 'screens/login_screen.dart';
import 'screens/settings_screen.dart';

Future<void> main() async{

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Moodify',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: StreamBuilder<User?>(
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
      ),
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

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.7), color],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, size: 48, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
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
      ),
    );
  }

  // =========================
  // UI
  // =========================

  @override
  Widget build(
      BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          "EmoTune",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade800, Colors.blue.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),

      bottomNavigationBar:
      BottomNavigationBar(

        type: BottomNavigationBarType.fixed,

        currentIndex: 0,

        items: const [

          BottomNavigationBarItem(

            icon: Icon(
              Icons.home,
            ),

            label: "Home",
          ),

          BottomNavigationBarItem(

            icon: Icon(
              Icons.search,
            ),

            label: "Search",
          ),

          BottomNavigationBarItem(

            icon: Icon(
              Icons.settings,
            ),

            label: "Settings",
          ),
        ],

        onTap:
            (index) {

          if (index == 0) {
            // Refresh the page
            setState(
              () {
                isLoading = true;
                selectedImage = null;
                detectedEmotion = "No Emotion";
                selectedEmotion = null;
              },
            );
            loadSongs();
          }
          else if (index == 1) {

            Navigator.push(

              context,

              MaterialPageRoute(

                builder:
                    (_) =>
                    const SearchSongScreen(),
              ),
            );
              } else if (index == 2) {

                Navigator.push(

                  context,

                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(),
                  ),
                );
          }
        },
      ),

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      "How are you feeling today?",
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    
                    // =====================
                    // CAMERA + GALLERY
                    // =====================
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionCard(
                            icon: Icons.camera_alt,
                            title: "Camera",
                            subtitle: "Take a photo",
                            color: Colors.blue.shade600,
                            onTap: captureImage,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionCard(
                            icon: Icons.photo_library,
                            title: "Gallery",
                            subtitle: "Upload photo",
                            color: Colors.purple.shade500,
                            onTap: pickImage,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    
                    // =====================
                    // EMOTION BUTTONS
                    // =====================
                    const Text(
                      "Or select your emotion manually",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        "Happy", "Sad", "Angry", "Fear",
                        "Neutral", "Surprise", "Disgust",
                      ].map((emotion) {
                        Color emotionColor = _getEmotionColor(emotion);
                        return InkWell(
                          onTap: () => updateRecommendation(emotion),
                          borderRadius: BorderRadius.circular(25),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: emotionColor.withOpacity(0.1),
                              border: Border.all(color: emotionColor, width: 1.5),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_getEmotionIcon(emotion), size: 20, color: emotionColor),
                                const SizedBox(width: 8),
                                Text(
                                  emotion,
                                  style: TextStyle(
                                    color: emotionColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 30),
                    
                    // =====================
                    // IMAGE PREVIEW
                    // =====================
                    if (selectedImage != null)
                      Card(
                        elevation: 4,
                        shadowColor: Colors.blue.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  selectedImage!,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (isAnalyzing)
                                const Column(
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 10),
                                    Text(
                                      "Analyzing face...",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    RichText(
                                      textAlign: TextAlign.center,
                                      text: TextSpan(
                                        style: const TextStyle(fontSize: 16, color: Colors.black),
                                        children: [
                                          const TextSpan(text: "Detected Emotion: "),
                                          TextSpan(
                                            text: detectedEmotion,
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: _getEmotionColor(detectedEmotion),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    if (detectedEmotion != "No Emotion" && detectedEmotion != "No Face")
                                      ElevatedButton(
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
                                        child: const Text("Get Songs"),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}