import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class FaceDetectionScreen extends StatefulWidget {
  @override
  _FaceDetectionScreenState createState() => _FaceDetectionScreenState();
}

class _FaceDetectionScreenState extends State<FaceDetectionScreen> {
  final FaceDetector faceDetector = GoogleMlKit.vision.faceDetector();
  List<Face> faces = [];
  late XFile? filePath;
  int imageWidth = 0;
  int imageHeight = 0;

  @override
  void dispose() {
    faceDetector.close();
    super.dispose();
  }

  void detectFaces() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return; // User canceled picking image

    final inputImage = InputImage.fromFilePath(pickedFile.path);

    var decodedImage =
        await decodeImageFromList(await pickedFile.readAsBytes());

    try {
      final List<Face> detectedFaces =
      await faceDetector.processImage(inputImage);

      setState(() {
        faces = detectedFaces;
        filePath = pickedFile;
        imageWidth = decodedImage.width;
        imageHeight = decodedImage.height;
      });
      
    } catch (e) {
      print("Error detecting faces: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    detectFaces();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    double canvasWidth = screenSize.width;
    double canvasHeight = 290;

    return Scaffold(
      appBar: AppBar(
        title: Text('Face Detection'),
      ),
      body: Center(
        child: Stack(
          children: [
            // Display your image here (you can use Image.network, Image.file, etc.)
            if (filePath != null) Image.file(File(filePath!.path)),

            // Draw circles around detected faces
            CustomPaint(
              painter: FacePainter(faces, imageWidth, imageHeight),
              size: Size(canvasWidth, canvasHeight),
            ),
          ],
        ),
      ),
    );
  }
}

class FacePainter extends CustomPainter {
  final List<Face> faces;
  int imgWidth;
  int imgHeight;
  FacePainter(this.faces, this.imgWidth, this.imgHeight);

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / imgWidth;
    final double scaleY = size.height / imgHeight;
    final Paint bluePaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Draw blue border to visualize the CustomPaint boundaries
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bluePaint);

    final Paint redPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (var face in faces) {
      final Rect rect = Rect.fromLTRB(
        face.boundingBox.left * scaleX,
        face.boundingBox.top * scaleY,
        face.boundingBox.right * scaleX,
        face.boundingBox.bottom * scaleY,
      );
      canvas.drawCircle(
          Offset(rect.center.dx, rect.center.dy), rect.width / 2, redPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
