import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/profile_repository_impl.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepositoryImpl repository;

  ProfileCubit({required this.repository}) : super(const ProfileState()) {
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final profile = await repository.fetchCurrentUserProfile();
      emit(state.copyWith(isLoading: false, profile: profile, error: null));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> logout() async {
    await repository.logout();
    // Optionally, emit a state or handle navigation
  }
}
