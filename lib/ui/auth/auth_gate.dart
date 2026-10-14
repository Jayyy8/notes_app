import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthChangeEvent, AuthState, Session;

import '../../state/core_providers.dart';
import '../../state/notes_controller.dart';
import '../home/home_shell.dart';
import 'auth_page.dart';

/// Shows the sign-in screen or the app, following the Supabase session.
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  StreamSubscription<AuthState>? _subscription;
  Session? _session;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(supabaseClientProvider).auth;
    _session = auth.currentSession;
    _subscription = auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedOut) {
        // Drop the previous user's notes so they can never flash for the next one.
        ref.invalidate(notesControllerProvider);
      }
      if (!mounted) return;
      setState(() => _session = data.session);
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    if (session == null) return const AuthPage();
    return HomeShell(key: ValueKey<String>(session.user.id));
  }
}