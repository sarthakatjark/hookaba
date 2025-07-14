import 'package:flutter/material.dart';

import '../../data/datasources/profile_repository_impl.dart';

class ProfileCubit extends ChangeNotifier {
  final ProfileRepositoryImpl repository;

  bool isLoading = false;
  Map<String, dynamic>? profileData;
  String? error;

  ProfileCubit({required this.repository}) {
    // Automatically load profile on cubit creation
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      profileData = await repository.fetchCurrentUserProfile();
    } catch (e) {
      error = e.toString();
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    await repository.logout();
    // Optionally, notify listeners or handle navigation
    notifyListeners();
  }
} 