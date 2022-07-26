import 'dart:io' as io;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class ObjectDetectorView extends StatefulWidget {
  @override
  _ObjectDetectorView createState() => _ObjectDetectorView();
}

class _ObjectDetectorView extends State<ObjectDetectorView> {
  late ObjectDetector _objectDetector; //object for ObjectDetector
  bool _canProcess = false; //flag
  bool _isBusy = false; //flag

  String?
      _text; // Text for saving the objects find in the image after detection process(can be null).
  File? _image; // Selected Image file.
  String? _path;

  @override
  void initState() {
    super.initState();
    _initializeDetector();
  }

  @override
  void dispose() {
    _canProcess = false;
    _objectDetector.close(); //It will Release Resource.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 126, 211, 123),
        title: const Text("Object Detection"),
      ),
      body: ListView(shrinkWrap: true, children: [
        _image != null
            ? SizedBox(
                height: 400,
                width: 400,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    Image.file(_image!),
                  ],
                ),
              )
            : SizedBox(
                height: 50,
                width: 50,
              ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              primary:
                  Color.fromARGB(255, 126, 211, 123), // background// foreground
            ),
            child: Text('Select From Gallery'),
            onPressed: () => _getImage(),
          ),
        ),
        if (_image != null)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('\n${_text ?? ''}'),
          ),
      ]),
    );
  }

//Initializing the model.
  void _initializeDetector() async {
    const path = 'assets/model/object_labeler.tflite';
    final modelPath = await _getModel(path); //Call for local stored model.
    final options = LocalObjectDetectorOptions(
      mode: DetectionMode.singleImage,
      modelPath: modelPath,
      classifyObjects: true,
      multipleObjects: true,
    );
    _objectDetector = ObjectDetector(options: options);
    _canProcess = true;
  }

//This function will open gallery for picking up the image.
  Future _getImage() async {
    setState(() {
      _image = null;
      _path = null;
    });
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _processPickedFile(pickedFile);
    }
    setState(() {});
  }

//Convert the $pickedFile path into an Inputimage format.
  Future _processPickedFile(XFile? pickedFile) async {
    final path = pickedFile?.path;
    if (path == null) {
      return;
    }
    setState(() {
      _image = File(path);
    });
    _path = path;
    final inputImage = InputImage.fromFilePath(path);
    processImage(inputImage);
  }

//This function will do the process of object detection.
  Future<void> processImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    setState(() {
      _text = '';
    });
    final objects = await _objectDetector.processImage(inputImage);

    String text = 'Objects found: ${objects.length}\n\n';

    //for storing all objects in $text
    for (final object in objects) {
      text += 'Object: ${object.labels.map((e) => e.text)}\n\n';
    }

    _text = text;
    _isBusy = false;

    if (mounted) {
      setState(() {});
    }
  }

//Returns the path of the local stored model.
  Future<String> _getModel(String assetPath) async {
    if (io.Platform.isAndroid) {
      return 'flutter_assets/$assetPath';
    }
    final path = '${(await getApplicationSupportDirectory()).path}/$assetPath';
    await io.Directory(dirname(path)).create(recursive: true);
    final file = io.File(path);
    if (!await file.exists()) {
      final byteData = await rootBundle.load(assetPath);
      await file.writeAsBytes(byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    }
    return file.path;
  }
}
