import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:hookaba/features/program_list/data/models/local_program_model.dart';

class LocalProgramService {
  final Box<LocalProgramModel> _box = GetIt.I<Box<LocalProgramModel>>();

  /// Returns a page of programs for pagination (page starts at 0)
  List<LocalProgramModel> getProgramsPage(int page, int pageSize) {
    final start = page * pageSize;
    return _box.values.skip(start).take(pageSize).toList();
  }

  /// Returns the total number of programs
  int getProgramCount() => _box.length;

  /// Returns a lazy iterable for use in ListView.builder
  Box<LocalProgramModel> get box => _box;
  Iterable<LocalProgramModel> get lazyPrograms => _box.values;

  LocalProgramModel? getProgram(String id) {
    return _box.get(id);
  }

  Future<void> addProgram(LocalProgramModel program) async {
    await _box.put(program.id, program);
  }

  Future<void> updateProgram(LocalProgramModel program) async {
    await _box.put(program.id, program);
  }

  Future<void> deleteProgram(String id) async {
    await _box.delete(id);
  }

  Future<void> clearAllPrograms() async {
    await _box.clear();
  }
} 