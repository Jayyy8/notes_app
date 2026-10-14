import 'dart:async';

import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart'
    show
    AutofillHints,
    FilteringTextInputFormatter,
    LengthLimitingTextInputFormatter,
    TextInputFormatter;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_colors.dart';
import '../../core/errors.dart';
import '../../state/core_providers.dart';

/// Must match "Email OTP Length" in your Supabase dashboard.
const int kOtpLength = 8;

/// Supabase allows one email per address roughly every 60 seconds.
const int _resendSeconds = 60;

/// Asks for the code that was emailed after sign up.
class VerifyCodeView extends ConsumerStatefulWidget {
  const VerifyCodeView({super.key, required this.email, required this.onBack});

  final String email;
  final VoidCallback onBack;

  @override
  ConsumerState<VerifyCodeView> createState() => _VerifyCodeViewState();
}

class _VerifyCodeViewState extends ConsumerState<VerifyCodeView> {
  final TextEditingController _code = TextEditingController();
  final FocusNode _focus = FocusNode();
  Timer? _timer;
  int _cooldown = 0;

  bool _verifying = false;
  bool _resending = false;
  String? _error;
  String? _info;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_refresh);
    // The first email was just sent, so start the resend countdown right away.
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _focus.removeListener(_refresh);
    _focus.dispose();
    _code.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _startCooldown() {
    _timer?.cancel();
    _cooldown = _resendSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _cooldown--);
      if (_cooldown <= 0) timer.cancel();
    });
  }

  void _onChanged(String value) {
    setState(() => _error = null);
    // Verify as soon as the last digit is typed, pasted or autofilled.
    if (value.length == kOtpLength) _verify();
  }

  Future<void> _verify() async {
    if (_verifying) return;
    final code = _code.text.trim();
    if (code.length != kOtpLength) {
      setState(
            () => _error = 'Enter the $kOtpLength-digit code from your email.',
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _verifying = true;
      _error = null;
      _info = null;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .verifySignUpCode(email: widget.email, code: code);
      // On success AuthGate swaps this screen for the app.
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = friendlyError(e);
          _code.clear();
        });
        _focus.requestFocus();
      }
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    if (_resending || _cooldown > 0) return;
    setState(() {
      _resending = true;
      _error = null;
      _info = null;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .resendSignUpCode(email: widget.email);
      if (mounted) {
        setState(() {
          _info = 'A new code is on its way.';
          _code.clear();
          _startCooldown();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resendLabel = _resending
        ? 'Sending...'
        : (_cooldown > 0 ? 'Resend code in ${_cooldown}s' : 'Resend code');

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
                        CupertinoIcons.mail_solid,
                        size: 36,
                        color: CupertinoColors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Check your email',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: primaryLabel(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We sent a $kOtpLength-digit code to\n${widget.email}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: secondaryLabel(context),
                    ),
                  ),
                  const SizedBox(height: 28),
                  // The visible boxes are drawn from the text; an invisible field
                  // on top receives the typing, pasting and autofill.
                  Stack(
                    children: <Widget>[
                      _CodeBoxes(
                        code: _code.text,
                        focused: _focus.hasFocus,
                        hasError: _error != null,
                      ),
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0,
                          child: CupertinoTextField(
                            controller: _code,
                            focusNode: _focus,
                            autofocus: true,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            autofillHints: const <String>[
                              AutofillHints.oneTimeCode,
                            ],
                            enableInteractiveSelection: false,
                            showCursor: false,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(kOtpLength),
                            ],
                            onChanged: _onChanged,
                            onSubmitted: (_) => _verify(),
                          ),
                        ),
                      ),
                    ],
                  ),
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
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 50,
                    child: AdaptiveButton(
                      onPressed: _verify,
                      label: _verifying ? 'Verifying...' : 'Verify',
                      style: AdaptiveButtonStyle.filled,
                      size: AdaptiveButtonSize.large,
                      color: kAccent,
                      enabled: !_verifying,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 44,
                    child: AdaptiveButton(
                      onPressed: _resend,
                      label: resendLabel,
                      style: AdaptiveButtonStyle.plain,
                      color: kAccent,
                      enabled: !_resending && _cooldown <= 0,
                    ),
                  ),
                  SizedBox(
                    height: 44,
                    child: AdaptiveButton(
                      onPressed: widget.onBack,
                      label: 'Use a different email',
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

class _CodeBoxes extends StatelessWidget {
  const _CodeBoxes({
    required this.code,
    required this.focused,
    required this.hasError,
  });

  final String code;
  final bool focused;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final activeIndex = code.length < kOtpLength ? code.length : kOtpLength - 1;

    return Row(
      children: <Widget>[
        for (var i = 0; i < kOtpLength; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _CodeBox(
                char: i < code.length ? code[i] : '',
                active: focused && i == activeIndex,
                hasError: hasError,
              ),
            ),
          ),
      ],
    );
  }
}

class _CodeBox extends StatelessWidget {
  const _CodeBox({
    required this.char,
    required this.active,
    required this.hasError,
  });

  final String char;
  final bool active;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final Color border = hasError
        ? CupertinoColors.systemRed.resolveFrom(context)
        : (active ? kAccent : CupertinoColors.separator.resolveFrom(context));

    return Container(
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: cardBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: active || hasError ? 2 : 1),
      ),
      child: Text(
        char,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: primaryLabel(context),
        ),
      ),
    );
  }
}