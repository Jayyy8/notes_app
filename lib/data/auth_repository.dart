import 'package:supabase_flutter/supabase_flutter.dart'
    show SupabaseClient, User;

/// Thin wrapper around Supabase Auth.
class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  Future<void> signIn({required String email, required String password}) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Returns true when the user is signed in immediately, or false when the
  /// project requires email confirmation first.
  Future<bool> signUp({required String email, required String password}) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
    );
    return response.session != null;
  }

  Future<void> signOut() => _client.auth.signOut();
}