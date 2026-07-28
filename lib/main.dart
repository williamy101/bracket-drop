import 'package:flutter/material.dart';
import 'presentation/bracket_drop_screen.dart';

void main() {
  runApp(const BracketDropApp());
}

class BracketDropApp extends StatelessWidget {
  const BracketDropApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bracket Drop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const BracketDropScreen(),
    );
  }
}
