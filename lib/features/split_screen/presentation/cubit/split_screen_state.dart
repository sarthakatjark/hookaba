import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum SplitScreenMode { single, dual }

class SplitScreenItem extends Equatable {
  final String? text;
  final TextStyle? textStyle;
  final ImageProvider? image;
  final bool isGif;

  const SplitScreenItem({this.text, this.textStyle, this.image, this.isGif = false});

  @override
  List<Object?> get props => [text, textStyle, image, isGif];
}

class SplitScreenState extends Equatable {
  final SplitScreenMode mode;
  final double splitRatio;
  final Color leftScreenColor;
  final Color rightScreenColor;
  final bool isLeftScreenActive;
  final double brightness;
  final List<Color> availableColors;
  final List<SplitScreenItem> splits;

  const SplitScreenState({
    this.mode = SplitScreenMode.single,
    this.splitRatio = 0.5,
    this.leftScreenColor = Colors.black,
    this.rightScreenColor = Colors.blue,
    this.isLeftScreenActive = true,
    this.brightness = 0.5,
    this.availableColors = const [
      Colors.white,
      Colors.red,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.purple,
    ],
    this.splits = const [SplitScreenItem(), SplitScreenItem()],
  });

  SplitScreenState copyWith({
    SplitScreenMode? mode,
    double? splitRatio,
    Color? leftScreenColor,
    Color? rightScreenColor,
    bool? isLeftScreenActive,
    double? brightness,
    List<Color>? availableColors,
    List<SplitScreenItem>? splits,
  }) {
    return SplitScreenState(
      mode: mode ?? this.mode,
      splitRatio: splitRatio ?? this.splitRatio,
      leftScreenColor: leftScreenColor ?? this.leftScreenColor,
      rightScreenColor: rightScreenColor ?? this.rightScreenColor,
      isLeftScreenActive: isLeftScreenActive ?? this.isLeftScreenActive,
      brightness: brightness ?? this.brightness,
      availableColors: availableColors ?? this.availableColors,
      splits: splits ?? this.splits,
    );
  }

  @override
  List<Object?> get props => [
        mode,
        splitRatio,
        leftScreenColor,
        rightScreenColor,
        isLeftScreenActive,
        brightness,
        availableColors,
        splits,
      ];
} 