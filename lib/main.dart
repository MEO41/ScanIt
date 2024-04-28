import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:scan_it/pages/home_page.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
 main()  {
  /// flutter run --dart-define=apiKey='Your GeminiAPI KEY'
  Gemini.init(
      apiKey: const String.fromEnvironment('apiKey'), enableDebugging: true);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      home: HomePage(),
    );
  }
}
