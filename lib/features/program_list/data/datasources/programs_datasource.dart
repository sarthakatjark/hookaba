import 'dart:convert'; // Added for base64Encode

import 'package:hookaba/core/utils/local_program_service.dart';
import 'package:hookaba/features/dashboard/data/datasources/dashboard_repository_impl.dart';
import 'package:hookaba/features/program_list/data/models/local_program_model.dart';

class ProgramDataSource {
  final LocalProgramService _service;
  final DashboardRepositoryImpl dashboardRepository;

  ProgramDataSource(this._service, this.dashboardRepository);

  List<LocalProgramModel> getProgramsPage(int page, int pageSize) {
    return _service.getProgramsPage(page, pageSize);
  }

  int getProgramCount() => _service.getProgramCount();

  Iterable<LocalProgramModel> get lazyPrograms => _service.lazyPrograms;

  LocalProgramModel? getProgram(String id) => _service.getProgram(id);

  Future<void> addProgram(LocalProgramModel program) => _service.addProgram(program);

  Future<void> updateProgram(LocalProgramModel program) => _service.updateProgram(program);

  Future<void> deleteProgram(String id) => _service.deleteProgram(id);

  Future<void> clearAllPrograms() => _service.clearAllPrograms();

  Future<void> sendProgramToDevice(LocalProgramModel program, {void Function(double progress)? onProgress}) async {
    final jsonCmd = program.jsonCommand;
    final pkts = jsonCmd['pkts_program'];
    final listRegion = pkts?['list_region'];
    final listItem = listRegion != null && listRegion.isNotEmpty
        ? listRegion[0]['list_item']
        : null;
    final item = listItem != null && listItem.isNotEmpty ? listItem[0] : null;

    final device = dashboardRepository.bleService.connectedDevice;
    if (device == null) throw Exception('No device connected');

    if (item != null && item['type_item'] == 'text') {
      await dashboardRepository.sendTextToBle(
        device,
        text: item['text'] ?? '',
        color: item['color'] ?? 0xFFFFFF,
        size: item['size'] ?? 16,
        bold: item['bold'],
        italic: item['italic'],
        spaceFont: item['space_font'],
        spaceLine: item['space_line'],
        alignHorizontal: item['align_horizontal'],
        alignVertical: item['align_vertical'],
        infoAnimate: item['info_animate'],
        stayingTime: pkts['property_pro']?['play_fixed_time']?.toDouble(),
      );
    } else {
      final isGif = jsonCmd.toString().contains('send_gif_src') || (jsonCmd['pkts_program']?['list_region']?[0]?['list_item']?[0]?['isGif'] == 1);
      if (isGif) {
        // For GIFs, just send the command (no progress possible)
        await dashboardRepository.sendImageOrGifViaJsBridge(jsonCmd, gifBase64: null);
      } else {
        // For images, send progress via sendTlvToBle
        final bmpBytes = program.bmpBytes;
        if (bmpBytes.isEmpty) throw Exception('No image data in program');
        // Simulate TLV upload with progress
        await dashboardRepository.sendTlvToBle(device, bmpBytes, onProgress: onProgress);
        final base64Image = base64Encode(bmpBytes);
        await dashboardRepository.sendImageOrGifViaJsBridge(jsonCmd, base64Image: base64Image);
      }
    }
  }
} 