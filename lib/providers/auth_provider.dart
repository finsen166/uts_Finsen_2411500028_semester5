// lib/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'view_state.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ViewState _state = ViewState.initial;
  String? _errorMessage;
  User? _user;

  ViewState get state => _state;
  String? get errorMessage => _errorMessage;
  User? get user => _user;
  bool get isAuthenticated => _user != null;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  AuthProvider() {
    _auth.authStateChanges().listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  void _setState(ViewState state, {String? error}) {
    _state = state;
    _errorMessage = error;
    notifyListeners();
  }

  Future<bool> register(String email, String password) async {
    _setState(ViewState.loading);
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      _user = credential.user;
      _setState(ViewState.loaded);
      return true;
    } on FirebaseAuthException catch (e) {
      _setState(ViewState.error, error: _getAuthErrorMessage(e.code));
      return false;
    } catch (e) {
      _setState(ViewState.error, error: 'Terjadi kesalahan: $e');
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _setState(ViewState.loading);
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      _user = credential.user;
      _setState(ViewState.loaded);
      return true;
    } on FirebaseAuthException catch (e) {
      _setState(ViewState.error, error: _getAuthErrorMessage(e.code));
      return false;
    } catch (e) {
      _setState(ViewState.error, error: 'Terjadi kesalahan: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _user = null;
    _setState(ViewState.initial);
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email sudah digunakan. Silakan gunakan email lain.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'weak-password':
        return 'Password terlalu lemah. Gunakan minimal 6 karakter.';
      case 'user-not-found':
        return 'Pengguna tidak ditemukan. Periksa email Anda.';
      case 'wrong-password':
        return 'Password salah. Silakan coba lagi.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      case 'network-request-failed':
        return 'Koneksi jaringan gagal. Periksa internet Anda.';
      case 'invalid-credential':
        return 'Email atau password salah.';
      default:
        return 'Autentikasi gagal: $code';
    }
  }
}
