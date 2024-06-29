import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tflite/flutter_tflite.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as devtools;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fruit Ripeness Detector',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black87, fontFamily: 'Poppins'),
          bodyMedium: TextStyle(color: Colors.black54, fontFamily: 'Poppins'),
        ),
        fontFamily: 'Poppins',
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? filePath;
  String fruitName = '';
  String ripenessStatus = '';
  List<Map<String, dynamic>> detectionHistory = [];

  Future<void> _tfLiteInit() async {
    String? res = await Tflite.loadModel(
      model: "assets/fruitmodel.tflite",
      labels: "assets/labels.txt",
      numThreads: 1,
      isAsset: true,
      useGpuDelegate: false,
    );
  }

  Future<void> pickImageGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    var imageFile = File(image.path);

    setState(() {
      filePath = imageFile;
    });

    var recognitions = await Tflite.runModelOnImage(
      path: image.path,
      imageMean: 0.0,
      imageStd: 255.0,
      numResults: 2,
      threshold: 0.2,
      asynch: true,
    );

    if (recognitions == null) {
      devtools.log("Recognitions is Null");
      return;
    }

    setState(() {
      double maxConfidence = recognitions[0]['confidence'];
      String fullLabel = recognitions[0]['label'].toString();

      if (maxConfidence < 0.5) {
        fruitName = 'Not a fruit';
        ripenessStatus = '';
      } else {
        List<String> labelParts = fullLabel.split(' ');

        if (labelParts.length > 1) {
          ripenessStatus = labelParts[0];
          fruitName = labelParts.sublist(1).join(' ');
        } else {
          fruitName = fullLabel; // In case the label doesn't contain a space
          ripenessStatus = '';
        }
      }

      detectionHistory.add({
        'label': fruitName,
        'imagePath': image.path,
      });
    });
  }

  Future<void> pickImageCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image == null) return;

    var imageFile = File(image.path);

    setState(() {
      filePath = imageFile;
    });

    var recognitions = await Tflite.runModelOnImage(
      path: image.path,
      imageMean: 0.0,
      imageStd: 255.0,
      numResults: 2,
      threshold: 0.2,
      asynch: true,
    );

    if (recognitions == null) {
      devtools.log("Recognitions is Null");
      return;
    }

    setState(() {
      double maxConfidence = recognitions[0]['confidence'];
      String fullLabel = recognitions[0]['label'].toString();

      if (maxConfidence < 0.4) {
        fruitName = 'Not a fruit';
        ripenessStatus = '';
      } else {
        List<String> labelParts = fullLabel.split(' ');

        if (labelParts.length > 1) {
          ripenessStatus = labelParts[0];
          fruitName = labelParts.sublist(1).join(' ');
        } else {
          fruitName = fullLabel; // In case the label doesn't contain a space
          ripenessStatus = '';
        }
      }

      detectionHistory.add({
        'label': fruitName,
        'imagePath': image.path,
      });
    });
  }

  void viewHistory() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Detection History'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: detectionHistory.length,
              itemBuilder: (BuildContext context, int index) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.file(
                      File(detectionHistory[index]['imagePath']),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    ListTile(
                      title: Text(
                        'Label: ${detectionHistory[index]['label']}',
                      ),
                    ),
                    Divider(),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> showFruitInformation() async {
    final String apiUrl =
        'https://en.wikipedia.org/api/rest_v1/page/summary/${fruitName.replaceAll(' ', '%20')}';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final String fruitInfo = jsonResponse['extract'];

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Information about $fruitName'),
              content: Text(fruitInfo),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Close'),
                ),
              ],
            );
          },
        );
      } else {
        devtools.log('Failed to fetch information from Wikipedia');
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('Failed to fetch information from Wikipedia'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Close'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      devtools.log('Error: $e');
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Failed to fetch information from Wikipedia'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Close'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
    Tflite.close();
  }

  @override
  void initState() {
    super.initState();
    _tfLiteInit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fruit Detection and Recognition"),
        backgroundColor: Colors.green[400]!,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset(
            'assets/background.jpg',
            fit: BoxFit.cover,
            opacity: const AlwaysStoppedAnimation(0.4),
          ),
          SingleChildScrollView(
            child: Center(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Container(
                            height: 300,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: filePath == null
                                ? Center(
                              child: Column(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image,
                                    size: 80,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No Image Selected',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                                : Image.file(
                              filePath!,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            fruitName.isEmpty
                                ? "Select an image to detect"
                                : fruitName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            ripenessStatus.isEmpty ? "" : ripenessStatus,
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          fruitName.isNotEmpty && fruitName != 'Not a fruit'
                              ? ElevatedButton(
                            onPressed: showFruitInformation,
                            child: Text('More Information'),
                          )
                              : Container(),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: viewHistory,
                            child: Text('View History'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: pickImageCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Take a Photo"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.green[400],
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: pickImageGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Pick from Gallery"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.green[400],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
