import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
        );

  Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: AppConfig.authTokenKey, value: token);
    } catch (_) {}
  }

  Future<String?> getToken() async {
    try {
      return await _storage.read(key: AppConfig.authTokenKey);
    } catch (_) {
      await clearAll();
      return null;
    }
  }

  Future<void> deleteToken() async {
    try {
      await _storage.delete(key: AppConfig.authTokenKey);
    } catch (_) {}
  }

  Future<void> saveUserJson(String userJson) async {
    try {
      await _storage.write(key: AppConfig.authUserKey, value: userJson);
    } catch (_) {}
  }

  Future<String?> getUserJson() async {
    try {
      return await _storage.read(key: AppConfig.authUserKey);
    } catch (_) {
      await clearAll();
      return null;
    }
  }

  Future<void> deleteUserJson() async {
    try {
      await _storage.delete(key: AppConfig.authUserKey);
    } catch (_) {}
  }

  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (_) {}
  }
}
