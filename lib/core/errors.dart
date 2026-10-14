import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException;

/// Turns any thrown object into a short message that is safe to show to users.
String friendlyError(Object error) {
  if (error is AuthException) return error.message;
  if (error is PostgrestException) return error.message;
  if (error is StateError) return error.message;

  final text = error.toString();
  if (text.contains('SocketException') ||
      text.contains('ClientException') ||
      text.contains('Failed host lookup') ||
      text.contains('TimeoutException')) {
    return 'No internet connection. Please try again.';
  }
  return 'Something went wrong. Please try again.';
}