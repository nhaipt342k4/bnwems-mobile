import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await _storage.write(key: AppConfig.authTokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: AppConfig.authTokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: AppConfig.authTokenKey);
  }

  Future<void> saveUserJson(String userJson) async {
    await _storage.write(key: AppConfig.authUserKey, value: userJson);
  }

  Future<String?> getUserJson() async {
    return await _storage.read(key: AppConfig.authUserKey);
  }

  Future<void> deleteUserJson() async {
    await _storage.delete(key: AppConfig.authUserKey);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
