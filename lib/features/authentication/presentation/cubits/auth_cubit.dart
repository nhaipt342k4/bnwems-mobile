import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/models/auth_user.dart';
import '../../data/services/auth_api_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthApiService _apiService;
  final SecureStorageService _storageService;

  AuthUser? _user;
  String? _token;

  AuthUser? get currentUser => _user;
  String? get currentToken => _token;

  AuthCubit({
    AuthApiService? apiService,
    SecureStorageService? storageService,
  })  : _apiService = apiService ?? AuthApiService(),
        _storageService = storageService ?? SecureStorageService(),
        super(AuthInitial());

  Future<void> checkAuthStatus() async {
    emit(AuthLoading());

    try {
      final savedToken = await _storageService.getToken();
      final savedUserJson = await _storageService.getUserJson();

      if (savedToken != null && savedToken.isNotEmpty) {
        _token = savedToken;
        if (savedUserJson != null && savedUserJson.isNotEmpty) {
          _user = AuthUser.decode(savedUserJson);
        }

        try {
          final profile = await _apiService.getProfile();
          _user = profile;
          await _storageService.saveUserJson(profile.encode());
        } catch (_) {
          // Offline fallback
        }

        if (_user != null) {
          emit(Authenticated(user: _user!, token: _token!));
        } else {
          emit(Unauthenticated());
        }
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(Unauthenticated(errorMessage: e.toString()));
    }
  }

  Future<bool> login(String username, String password) async {
    emit(AuthLoading());

    try {
      final result = await _apiService.login(username, password);
      _token = result.token;
      _user = result.user;

      await _storageService.saveToken(result.token);
      await _storageService.saveUserJson(result.user.encode());

      emit(Authenticated(user: _user!, token: _token!));
      return true;
    } catch (e) {
      emit(Unauthenticated(errorMessage: e.toString()));
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    await _storageService.clearAll();
    emit(Unauthenticated());
  }
}
