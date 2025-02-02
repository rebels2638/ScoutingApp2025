import 'package:flutter/material.dart';
import 'scouting.dart'; // Ensure this points to your ScoutingPage file

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Scouting App 2025', // Updated tab title
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ScoutingPage(),  // Directly use ScoutingPage as home
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scouting App 2025'), // Updated AppBar title
      ),
      body: ScoutingPage(),
    );
  }
}