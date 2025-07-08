import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppFonts {
  static const String dashHorizon = 'DashHorizon';
  static const String audiowide = 'Audiowide';

  static TextStyle dashHorizonStyle({
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
  }) =>
      TextStyle(
        fontFamily: dashHorizon,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );

  static TextStyle audiowideStyle({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
  }) =>
      TextStyle(
        fontFamily: audiowide,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );

  // Orbitron for headings/titles
  static TextStyle orbitron({
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double? letterSpacing,
  }) =>
      GoogleFonts.orbitron(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );

  // Roboto for body/secondary text
  static TextStyle body({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double? letterSpacing,
  }) =>
      GoogleFonts.roboto(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );
}
