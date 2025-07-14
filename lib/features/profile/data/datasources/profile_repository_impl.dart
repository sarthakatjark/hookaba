import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hookaba/core/network/network_dio.dart';
import 'package:hookaba/core/utils/api_constants.dart';

class ProfileRepositoryImpl {
  final DioClient dioClient;
  final FlutterSecureStorage secureStorage;

  ProfileRepositoryImpl({required this.dioClient, required this.secureStorage});

  Future<Map<String, dynamic>?> fetchUserProfile(String userId) async {
    final response = await dioClient.get(ApiEndpoints.userById(userId));
    return response.data;
  }

  Future<Map<String, dynamic>?> fetchCurrentUserProfile() async {
    final response = await dioClient.get(ApiEndpoints.userMe);
    return response.data;
  }

  Future<void> logout() async {
    await secureStorage.delete(key: 'user_token');
  }
} 