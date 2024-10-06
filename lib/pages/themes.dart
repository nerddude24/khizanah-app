import 'package:flutter/material.dart';
import "package:google_fonts/google_fonts.dart";

final MediumTxt = TextStyle(fontSize: 28, color: Colors.white);
final SmallTxt = TextStyle(fontSize: 20, color: Colors.white);
final XSmallTxt =
    TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w700);

final AppThemeData = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Colors.red,
  textTheme: GoogleFonts.ibmPlexSansArabicTextTheme(),
  tooltipTheme:
      TooltipThemeData(textStyle: XSmallTxt.copyWith(color: Colors.black)),
);
