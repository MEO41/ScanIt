import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  late Gemini gemini;
  String? searchedText, result;
  bool _loading = false;

  Uint8List? selectedImage;

  bool get loading => _loading;

  set loading(bool set) => setState(() => _loading = set );
  @override
  void initState(){
    super.initState();
    gemini = Gemini.instance;
    // open the camera automatically when the page is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      openCamera();
    });
  }

  Future<List<int>> compressImage(Uint8List imageBytes) async {
    try {
      List<int> compressedBytes = await FlutterImageCompress.compressWithList(
        imageBytes,
        minHeight: 800,
        minWidth: 600,
        quality: 95,
      );
      return compressedBytes;
    } catch (e) {
      // Handle compression error
      print('Compression error: $e');
      throw Exception('Image compression failed');
    }
  }

  Future<void> openCamera() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);

      if (photo != null) {
        photo.readAsBytes().then((value) async {
          // Check if the image size exceeds the limit
          if (value.length > 3194304) {
            // Resize and compress the image
            try {
              List<int> resizedAndCompressedBytes = await compressImage(value);
              setState(() {
                selectedImage = Uint8List.fromList(resizedAndCompressedBytes);
                if (selectedImage != null) {
                  loading = true;
                  sendToGemini();
                }
              });
            } catch (e) {
              // Handle compression error
              showErrorMessage('Image compression failed');
            }
          } else {
            setState(() {
              selectedImage = value;
              if (selectedImage != null) {
                loading = true;
                sendToGemini();
              }
            });
          }
        });
      }
    } catch (e) {
      // Handle image picking error
      showErrorMessage('Error picking image');
    }
  }

  void sendToGemini() {
    const searchedText =
        'What can you tell me more details about the ingredients and what is the usage of this ingredients in this product';
    gemini.textAndImage(
      text: searchedText,
      images: [selectedImage!],
    ).then((value) {
      if (value != null) {
        // Request was successful
        result = value.content?.parts?.last.text;
        loading = false;
      } else {
        // Handle Gemini API error
        showErrorMessage('Gemini API request failed');
      }
    }).catchError((error) {
      // Handle other errors that might occur
      print('Error: $error');
      showErrorMessage('An error occurred');
    });
  }

  void showErrorMessage(String message) {
    // Implement your logic to display an error message to the user
    print('Error: $message');
    loading = false;
    // You can use a SnackBar, AlertDialog, or any other UI element to show the error message
    // For example:
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Result'),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            onPressed: () {
              openCamera();
            },
          ),
        ],
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (selectedImage != null)
                    Expanded(
                      flex: 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: Image.memory(
                          selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  Expanded(
                    flex: 2,
                    child: loading
                        ? Padding(
                      
                        padding: const EdgeInsets.fromLTRB(100,0,100,0),
                        child: Lottie.asset('assets/lottie/NN.json'))
                        : result != null
                        ? Markdown(
                      data: result!,
                      padding:
                      const EdgeInsets.symmetric(horizontal: 12),
                    )
                        : const Center(
                      child: Text('Search something!'),
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
