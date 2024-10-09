import "dart:io";

import "package:flutter/material.dart";
import "package:khizanah/src/home.dart";
import "package:khizanah/src/logic.dart";
import "package:khizanah/src/theme.dart";

String pathToYTDLP = "";

void main() async {
  // yt-dlp is grouped with windows version of the app only (for now).
  if (await isYTDLPInstalled() || !Platform.isWindows)
    pathToYTDLP = "yt-dlp";
  else if (await File("${Platform.resolvedExecutable}\\deps\\yt-dlp.exe")
      .exists())
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
      home: pathToYTDLP != ""
          ? Home()
          : Directionality(
              textDirection: TextDirection.rtl,
              child: Text(
                "لم يتم العثور على تطبيق \nyt-dlp\n  على جهازك! رجاءًا أعد تثبيت تطبيق خزانة.",
                style: MediumTxt.copyWith(fontSize: 64),
              ),
            ),
    );
  }
}
