import "package:flutter/material.dart";
import "package:khizanah/pages/home.dart";
import "package:khizanah/pages/themes.dart";

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppThemeData,
      home: Home(),
    );
  }
}
