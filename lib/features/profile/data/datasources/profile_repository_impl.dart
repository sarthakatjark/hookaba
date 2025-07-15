import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hookaba/core/network/network_dio.dart';
import 'package:hookaba/core/utils/api_constants.dart';
import 'package:hookaba/features/profile/domain/entities/profile_entity.dart';

class ProfileRepositoryImpl {
  final DioClient dioClient;
  final FlutterSecureStorage secureStorage;

  ProfileRepositoryImpl({required this.dioClient, required this.secureStorage});

  Future<ProfileEntity?> fetchUserProfile(String userId) async {
    final response = await dioClient.get(ApiEndpoints.userById(userId));
    if (response.data != null) {
      return ProfileEntity.fromJson(response.data);
    }
    return null;
  }

  Future<ProfileEntity?> fetchCurrentUserProfile() async {
    final response = await dioClient.get(ApiEndpoints.userMe);
    if (response.data != null) {
      return ProfileEntity.fromJson(response.data);
    }
    return null;
  }

  Future<void> logout() async {
    await secureStorage.delete(key: 'user_token');
  }
} 