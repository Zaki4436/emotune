import 'dart:io';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class EmotionDetector {

  Interpreter? interpreter;

  final List<String> labels = [
    "Angry",
    "Disgust",
    "Fear",
    "Happy",
    "Neutral",
    "Sad",
    "Surprise",
  ];

  // ===============================
  // LOAD MODEL
  // ===============================
  Future<void> loadModel() async {

    interpreter =
        await Interpreter.fromAsset(
      'assets/model/emotion_model.tflite',
    );
  }

  // ===============================
  // DETECT EMOTION
  // ===============================
  Future<String> predictEmotion(
      File imageFile,
      ) async {

    try {

      // ==========================
      // FACE DETECTION
      // ==========================
      final inputImage =
          InputImage.fromFile(
        imageFile,
      );

      final faceDetector =
          FaceDetector(

        options:
        FaceDetectorOptions(

          performanceMode:
          FaceDetectorMode.fast,
        ),
      );

      final faces =
          await faceDetector
              .processImage(
        inputImage,
      );

      if (faces.isEmpty) {

        await faceDetector.close();

        return "No Face";
      }

      final face =
          faces.first.boundingBox;

      // ==========================
      // READ IMAGE
      // ==========================
      img.Image? original =
          img.decodeImage(
        await imageFile.readAsBytes(),
      );

      if (original == null) {

        await faceDetector.close();

        return "Neutral";
      }

      // ==========================
      // SAFE CROP
      // ==========================
      int x =
      face.left.toInt();

      int y =
      face.top.toInt();

      int width =
      face.width.toInt();

      int height =
      face.height.toInt();

      if (x < 0) x = 0;
      if (y < 0) y = 0;

      if (x + width >
          original.width) {

        width =
            original.width - x;
      }

      if (y + height >
          original.height) {

        height =
            original.height - y;
      }

      img.Image cropped =
      img.copyCrop(
        original,

        x: x,
        y: y,

        width: width,
        height: height,
      );

      // ==========================
      // RESIZE TO MODEL SIZE
      // ==========================
      img.Image resized =
      img.copyResize(

        cropped,

        width: 48,
        height: 48,
      );

      // ==========================
      // PREPARE INPUT
      // ==========================
      var input = List.generate(

        1,

            (_) => List.generate(

          48,

              (y) => List.generate(

            48,

                (x) {

              var pixel =
              resized.getPixel(
                x,
                y,
              );

              double gray =

                  (pixel.r * 0.3 +
                      pixel.g * 0.59 +
                      pixel.b * 0.11)

                      / 255.0;

              return [gray];
            },
          ),
        ),
      );

      // ==========================
      // OUTPUT
      // ==========================
      var output =
      List.generate(

        1,

            (_) => List.filled(
          labels.length,
          0.0,
        ),
      );

      // ==========================
      // RUN MODEL
      // ==========================
      interpreter!.run(
        input,
        output,
      );

      int maxIndex = 0;

      double maxValue =
      output[0][0];

      for (int i = 1;
      i < labels.length;
      i++) {

        if (output[0][i] >
            maxValue) {

          maxValue =
          output[0][i];

          maxIndex = i;
        }
      }

      await faceDetector.close();

      return labels[maxIndex];

    } catch (e) {

      print(
          "Emotion Detection Error: $e");

      return "Neutral";
    }
  }
}