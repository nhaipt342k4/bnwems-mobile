import '../../../../core/network/api_client.dart';
import '../models/auth_user.dart';

class LoginResult {
  final String token;
  final AuthUser user;

  LoginResult({required this.token, required this.user});
}

class AuthApiService {
  final ApiClient _apiClient;

  AuthApiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<LoginResult> login(String username, String password) async {
    final response = await _apiClient.fetchData<Map<String, dynamic>>(
      '/auth/login',
      method: 'POST',
      body: {
        'username': username,
        'password': password,
      },
    );

    final token = response['token']?.toString() ?? '';
    final userMap = response['user'] as Map<String, dynamic>;
    final user = AuthUser.fromDtoJson(userMap);

    return LoginResult(token: token, user: user);
  }

  Future<AuthUser> getProfile() async {
    final response = await _apiClient.fetchData<Map<String, dynamic>>('/auth/profile');
    return AuthUser.fromDtoJson(response);
  }

  Future<AuthUser> updateProfile({
    String? fullName,
    String? phone,
    String? bio,
    String? avatarUrl,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['fullName'] = fullName;
    if (phone != null) body['phone'] = phone;
    if (bio != null) body['bio'] = bio;
    if (avatarUrl != null) body['avatarUrl'] = avatarUrl;

    final response = await _apiClient.fetchData<Map<String, dynamic>>(
      '/auth/profile',
      method: 'PUT',
      body: body,
    );
    return AuthUser.fromDtoJson(response);
  }

  Future<void> changePassword(String oldPassword, String newPassword, String confirmNewPassword) async {
    await _apiClient.fetchData(
      '/auth/change-password',
      method: 'PUT',
      body: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
        'confirmNewPassword': confirmNewPassword,
      },
    );
  }

  Future<void> forgotPassword(String username) async {
    await _apiClient.fetchData(
      '/auth/forgot-password',
      method: 'POST',
      body: {'username': username},
    );
  }
}
