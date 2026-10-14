import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_colors.dart';
import '../../core/errors.dart';
import '../../state/core_providers.dart';

/// Email + password sign in / sign up, using Supabase Auth.
class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  bool _isSignUp = false;
  bool _loading = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _validate(String email, String password) {
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    if (password.length < 6) {
      return 'Your password needs at least 6 characters.';
    }
    if (_isSignUp && password != _confirm.text) {
      return 'Passwords do not match.';
    }
    return null;
  }

  void _toggleMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _error = null;
      _info = null;
      _confirm.clear();
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final email = _email.text.trim();
    final password = _password.text;
    final problem = _validate(email, password);
    if (problem != null) {
      setState(() {
        _error = problem;
        _info = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });

    final auth = ref.read(authRepositoryProvider);
    try {
      if (_isSignUp) {
        final signedIn = await auth.signUp(email: email, password: password);
        if (!signedIn && mounted) {
          // Email confirmation is switched on for this Supabase project.
          setState(() {
            _isSignUp = false;
            _password.clear();
            _confirm.clear();
            _info = 'Account created. Check your inbox to confirm your email, '
                'then sign in.';
          });
        }
      } else {
        await auth.signIn(email: email, password: password);
        // On success AuthGate swaps this page out automatically.
      }
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isSignUp ? 'Create account' : 'Welcome back';
    final subtitle = _isSignUp
        ? 'Sign up to keep your notes in sync.'
        : 'Sign in to see your notes.';
    final submitLabel = _loading
        ? 'Please wait...'
        : (_isSignUp ? 'Create Account' : 'Sign In');

    return AdaptiveScaffold(
      backgroundColor: groupedBackground(context),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: kAccent,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        CupertinoIcons.doc_text_fill,
                        size: 38,
                        color: CupertinoColors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: primaryLabel(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: secondaryLabel(context),
                    ),
                  ),
                  const SizedBox(height: 28),
                  AdaptiveTextField(
                    controller: _email,
                    placeholder: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    prefixIcon: const Icon(CupertinoIcons.mail),
                  ),
                  const SizedBox(height: 12),
                  AdaptiveTextField(
                    controller: _password,
                    placeholder: 'Password',
                    obscureText: true,
                    autocorrect: false,
                    textInputAction:
                    _isSignUp ? TextInputAction.next : TextInputAction.done,
                    onSubmitted: (_) {
                      if (!_isSignUp && !_loading) _submit();
                    },
                    prefixIcon: const Icon(CupertinoIcons.lock),
                  ),
                  if (_isSignUp) ...<Widget>[
                    const SizedBox(height: 12),
                    AdaptiveTextField(
                      controller: _confirm,
                      placeholder: 'Confirm password',
                      obscureText: true,
                      autocorrect: false,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        if (!_loading) _submit();
                      },
                      prefixIcon: const Icon(CupertinoIcons.lock),
                    ),
                  ],
                  if (_error != null) ...<Widget>[
                    const SizedBox(height: 14),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.systemRed.resolveFrom(context),
                      ),
                    ),
                  ],
                  if (_info != null) ...<Widget>[
                    const SizedBox(height: 14),
                    Text(
                      _info!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.systemGreen.resolveFrom(context),
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 50,
                    child: AdaptiveButton(
                      onPressed: _submit,
                      label: submitLabel,
                      style: AdaptiveButtonStyle.filled,
                      size: AdaptiveButtonSize.large,
                      enabled: !_loading,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 44,
                    child: AdaptiveButton(
                      onPressed: _loading ? () {} : _toggleMode,
                      label: _isSignUp
                          ? 'Already have an account? Sign In'
                          : 'New here? Create an account',
                      style: AdaptiveButtonStyle.plain,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}