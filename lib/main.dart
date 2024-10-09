import "dart:io";

import "package:flutter/material.dart";
import "package:khizanah/src/home.dart";
import "package:khizanah/src/logic.dart";
import "package:khizanah/src/theme.dart";

String pathToYTDLP = "";

void main() async {
  if (await isYTDLPInstalled() || !Platform.isWindows)
    pathToYTDLP = "yt-dlp";
  else
    pathToYTDLP = "${Platform.resolvedExecutable}\\deps\\yt-dlp.exe";

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
