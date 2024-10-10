import "package:flutter/material.dart";
import "package:khizanah/src/home.dart";
import "package:khizanah/src/theme.dart";

void main() async {
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
