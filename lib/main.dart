import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";
import "package:khizanah/pages/home.dart";

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: Colors.red,
          textTheme: GoogleFonts.ibmPlexSansArabicTextTheme()),
      home: Home(),
    );
  }
}
