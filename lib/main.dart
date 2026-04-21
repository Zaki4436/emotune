import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'services/spotify_service.dart';
import 'song_detail_screen.dart';

// 🔥 ADD THESE IMPORTS (for ML)
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

void main() {
  runApp(const EmoTuneApp());
}

class EmoTuneApp extends StatelessWidget {
  const EmoTuneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: EmotionScreen(),
    );
  }
}

class EmotionScreen extends StatefulWidget {
  const EmotionScreen({super.key});

  @override
  State<EmotionScreen> createState() => _EmotionScreenState();
}

class _EmotionScreenState extends State<EmotionScreen> {
  File? _image;
  String emotion = "No emotion";
  bool isLoading = false;

  List songs = [];

  final picker = ImagePicker();
  final SpotifyService _spotifyService = SpotifyService();

  // 🔥 ML MODEL
  Interpreter? interpreter;

  final List<String> labels = [
    "Angry",
    "Disgust",
    "Fear",
    "Happy",
    "Neutral",
    "Sad",
    "Surprise"
  ];

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  Future<void> loadModel() async {
    interpreter = await Interpreter.fromAsset('assets/model/emotion_model.tflite');
  }

  // ===============================
  // 📸 PICK IMAGE
  // ===============================
  Future<void> pickImage(ImageSource source) async {
    final picked = await picker.pickImage(source: source);
    if (picked == null) return;

    File imageFile = File(picked.path);

    setState(() {
      _image = imageFile;
    });

    detectFace(imageFile); // 🔥 CALL ML PIPELINE
  }

  // ===============================
  // 🧠 FACE DETECTION
  // ===============================
  Future<void> detectFace(File file) async {
    final inputImage = InputImage.fromFile(file);

    final faceDetector = FaceDetector(
      options: FaceDetectorOptions(performanceMode: FaceDetectorMode.fast),
    );

    final faces = await faceDetector.processImage(inputImage);

    if (faces.isEmpty) {
      setState(() => emotion = "No face detected ❌");
      return;
    }

    final face = faces.first.boundingBox;

    img.Image? original = img.decodeImage(await file.readAsBytes());

    img.Image cropped = img.copyCrop(
      original!,
      x: face.left.toInt(),
      y: face.top.toInt(),
      width: face.width.toInt(),
      height: face.height.toInt(),
    );

    runModel(cropped);
  }

  // ===============================
  // 🤖 RUN MODEL
  // ===============================
  void runModel(img.Image image) {
    if (interpreter == null) return;

    img.Image resized = img.copyResize(image, width: 48, height: 48);

    var input = List.generate(
      1,
      (i) => List.generate(
        48,
        (y) => List.generate(48, (x) {
          var pixel = resized.getPixel(x, y);
          var gray = (pixel.r * 0.3 + pixel.g * 0.59 + pixel.b * 0.11) / 255.0;
          return [gray];
        }),
      ),
    );

    var output = List.generate(1, (i) => List.filled(labels.length, 0.0));

    interpreter!.run(input, output);

    int maxIndex = 0;
    double maxValue = output[0][0];

    for (int i = 0; i < labels.length; i++) {
      if (output[0][i] > maxValue) {
        maxValue = output[0][i];
        maxIndex = i;
      }
    }

    // 🔥 SET REAL EMOTION HERE
    setState(() {
      emotion = labels[maxIndex];
    });
  }

  // ===============================
  // 🎵 FETCH SONGS (BUTTON TRIGGER)
  // ===============================
  Future<void> fetchSongs() async {
    setState(() => isLoading = true);

    try {
      var fetchedSongs =
          await _spotifyService.getSongsByEmotion(emotion);

      setState(() {
        songs = fetchedSongs;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching songs: $e");
      setState(() => isLoading = false);
    }
  }

  // ===============================
  // 🎨 UI (UNCHANGED)
  // ===============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("EmoTune 🎧")),
      body: Column(
        children: [
          const SizedBox(height: 20),

          _image != null
              ? Image.file(_image!, height: 200)
              : const Text("No image selected"),

          const SizedBox(height: 10),

          Text(
            emotion,
            style: const TextStyle(fontSize: 18),
          ),

          const SizedBox(height: 10),

          ElevatedButton.icon(
            onPressed: (emotion == "No emotion" || isLoading)
                ? null
                : fetchSongs,
            icon: const Icon(Icons.music_note),
            label: const Text("Get Songs 🎧"),
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => pickImage(ImageSource.gallery),
                child: const Text("Gallery"),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: () => pickImage(ImageSource.camera),
                child: const Text("Camera"),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      var song = songs[index];

                      return ListTile(
                        leading: Image.network(
                          song['image'],
                          width: 50,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.music_note),
                        ),
                        title: Text(song['title']),
                        subtitle: Text(song['artist']),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SongDetailScreen(song: song),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}