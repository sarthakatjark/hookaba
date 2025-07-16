import 'dart:typed_data';

import 'package:hive/hive.dart';

part 'local_program_model.g.dart';

@HiveType(typeId: 1)
class LocalProgramModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final Uint8List bmpBytes; // BMP representation of the image
  @HiveField(3)
  final Map<String, dynamic> jsonCommand;

  LocalProgramModel({
    required this.id,
    required this.name,
    required this.bmpBytes,
    required this.jsonCommand,
  });
} 