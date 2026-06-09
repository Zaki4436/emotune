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

class _HomeScreenState
    extends State<HomeScreen> {

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

      if (mounted) {

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(

          const SnackBar(
            content: Text(
              "No face detected",
            ),
          ),
        );
      }

      return;
    }

    setState(() {

      detectedEmotion =
          emotion;

      selectedEmotion =
          emotion;
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

      if (mounted) {

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(

          const SnackBar(
            content: Text(
              "No face detected",
            ),
          ),
        );
      }

      return;
    }

    setState(() {

      detectedEmotion =
          emotion;

      selectedEmotion =
          emotion;
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
  // MANUAL EMOTION
  // =========================

  void updateRecommendation(
      String emotion) {

    setState(() {

      selectedEmotion =
          emotion;
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
  // UI
  // =========================

  @override
  Widget build(
      BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          "Moodify",
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

          if (index == 1) {

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

      body: isLoading

          ? const Center(
        child:
        CircularProgressIndicator(),
      )

          : Column(

        children: [

          const SizedBox(
            height: 15,
          ),

          // =====================
          // CAMERA + GALLERY
          // =====================

          Row(

            mainAxisAlignment:
            MainAxisAlignment
                .center,

            children: [

              ElevatedButton.icon(

                onPressed:
                captureImage,

                icon:
                const Icon(
                  Icons
                      .camera_alt,
                ),

                label:
                const Text(
                  "Camera",
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              ElevatedButton.icon(

                onPressed:
                pickImage,

                icon:
                const Icon(
                  Icons.photo,
                ),

                label:
                const Text(
                  "Gallery",
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 10,
          ),

          // =====================
          // EMOTION BUTTONS
          // =====================

          const Text(
            "Select Emotion",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                "Happy", "Sad", "Angry", "Fear",
                "Neutral", "Surprise", "Disgust",
              ].map((emotion) {
                return ElevatedButton(
                  onPressed: () => updateRecommendation(emotion),
                  child: Text(emotion),
                );
              }).toList(),
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          if (selectedImage !=
              null)

            Image.file(
              selectedImage!,
              height: 180,
            ),

          if (selectedImage !=
              null)

            const SizedBox(
              height: 10,
            ),

          if (isAnalyzing)
            const Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 10),
                Text(
                  "Analyzing face...",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            )
          else
            Text(
              "Detected Emotion: "
                  "$detectedEmotion",

              style:
              const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}