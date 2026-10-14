import 'package:supabase_flutter/supabase_flutter.dart'
    show OtpType, SupabaseClient, User;

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
  /// project requires email confirmation first (a code is emailed to them).
  Future<bool> signUp({required String email, required String password}) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
    );
    return response.session != null;
  }

  /// Confirms the sign-up with the code from the email. On success Supabase
  /// creates the session, and AuthGate shows the app automatically.
  Future<void> verifySignUpCode({
    required String email,
    required String code,
  }) async {
    await _client.auth.verifyOTP(
      type: OtpType.signup,
      email: email.trim(),
      token: code.trim(),
    );
  }

  /// Sends a fresh confirmation code.
  Future<void> resendSignUpCode({required String email}) async {
    await _client.auth.resend(type: OtpType.signup, email: email.trim());
  }

  Future<void> signOut() => _client.auth.signOut();
}