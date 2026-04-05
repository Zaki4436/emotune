import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

void main() {
  runApp(EmoTuneApp());
}

class EmoTuneApp extends StatelessWidget {
  const EmoTuneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: EmotionScreen(),
    );
  }
}

class EmotionScreen extends StatefulWidget {
  const EmotionScreen({super.key});

  @override
  EmotionScreenState createState() => EmotionScreenState();
}

class EmotionScreenState extends State<EmotionScreen> {
  File? _image;
  String result = "No result";
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

  // Pick Image
  Future<void> pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked == null) return;

    File imageFile = File(picked.path);
    setState(() => _image = imageFile);

    detectFace(imageFile);
  }

  // Detect Face
  Future<void> detectFace(File file) async {
    final inputImage = InputImage.fromFile(file);

    final faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
      ),
    );

    final faces = await faceDetector.processImage(inputImage);

    if (faces.isEmpty) {
      setState(() => result = "No face detected ❌");
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

  // Run Model
  void runModel(img.Image image) {
    img.Image resized = img.copyResize(image, width: 48, height: 48);

    var input = List.generate(
        1,
        (i) => List.generate(
            48,
            (y) => List.generate(48, (x) {
                  var pixel = resized.getPixel(x, y);

                  var gray = (pixel.r * 0.3 +
                          pixel.g * 0.59 +
                          pixel.b * 0.11) /
                      255.0;

                  return [gray];
                })));

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

    setState(() {
      result = labels[maxIndex];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Emotion Detection"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _image != null
                ? Image.file(_image!, height: 200)
                : Text("No image selected"),

            SizedBox(height: 20),

            Text(
              result,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),

            SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => pickImage(ImageSource.gallery),
                  icon: Icon(Icons.photo),
                  label: Text("Gallery"),
                ),
                SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: () => pickImage(ImageSource.camera),
                  icon: Icon(Icons.camera_alt),
                  label: Text("Camera"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}