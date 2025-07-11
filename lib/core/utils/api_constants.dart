class ApiEndpoints {
  // Base URL
  static const String baseUrl = "http://13.60.21.59:5000";

  // Auth Endpoints
  static const String authRequestOtp = "$baseUrl/auth/request-otp";
  static const String authVerifyOtp = "$baseUrl/auth/verify-otp";

  // User Endpoints
  static const String users = "$baseUrl/users"; // POST to create user
  static String userById(String userId) => "$baseUrl/users/$userId"; // GET user by ID

  // Library Endpoints
  static const String libraryUpload = "$baseUrl/library/upload"; // POST (form-data)
  static String libraryList({int page = 1, int perPage = 10}) => "$baseUrl/library?page=$page&per_page=$perPage";
}
