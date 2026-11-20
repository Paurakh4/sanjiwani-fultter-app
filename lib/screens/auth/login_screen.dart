import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:pocketbase/pocketbase.dart';

import '../../core/icons.dart';
import '../../core/l10n.dart';
import '../../core/tokens.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  // Errors appear only after the first submit, then clear as each field is fixed.
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _busy = false;

  Future<void> _signIn() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      setState(() => _autoValidate = AutovalidateMode.onUserInteraction);
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);

    final l10n = L10n.of(context);
    try {
      // The server accepts either handle, so the phone field is passed as the
      // identifier unchanged; an email typed there works too.
      await context.read<AppState>().signIn(
        _phoneController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      // This page can be reached either as the gate itself or pushed over the
      // sign-up form; only the first route holds the gate that swaps in the
      // app, so the stack has to be unwound before that can happen.
      Navigator.of(context).popUntil((route) => route.isFirst);
      showAppSnack(context, l10n.signInDoneSnack);
    } on ClientException catch (error) {
      if (!mounted) return;
      showAppSnack(context, _failureText(l10n, error));
    } catch (error) {
      if (!mounted) return;
      showAppSnack(context, l10n.signInNetworkError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static String _failureText(L10n l10n, ClientException error) =>
      error.statusCode == 0 ? l10n.signInNetworkError : l10n.signInFailed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = L10n.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.gutter,
                  24,
                  AppTokens.gutter,
                  28,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppWordmark(height: 40),
                    const SizedBox(height: 40),
                    Text(l10n.loginWelcomeTitle, style: theme.textTheme.displaySmall),
                    const SizedBox(height: 8),
                    Text(
                      l10n.loginWelcomeBody,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Form(
                      key: _formKey,
                      autovalidateMode: _autoValidate,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              hintText: l10n.phoneHint,
                              prefixIcon: const Icon(CoolIcons.phone),
                            ),
                            validator: (value) {
                              final text = (value ?? '').trim();
                              if (text.contains('@')) return null;
                              final digits = text.replaceAll(
                                RegExp(r'[^0-9०-९]'),
                                '',
                              );
                              if (digits.length < 7) return l10n.phoneInvalid;
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _signIn(),
                            decoration: InputDecoration(
                              hintText: l10n.passwordHint,
                              prefixIcon: Center(
                                widthFactor: 1,
                                child: CoolSvgIcon(
                                  'lock-round',
                                  size: 22,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              suffixIcon: IconButton(
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                                icon: CoolSvgIcon(
                                  _obscure ? 'eye-round' : 'eye-off-round',
                                  size: 22,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if ((value ?? '').isEmpty) {
                                return l10n.passwordRequired;
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ForgotPasswordScreen(),
                          ),
                        ),
                        child: Text(l10n.forgotPassword),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _busy ? null : _signIn,
                        child: Text(_busy ? l10n.loading : l10n.signIn),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.noAccountPrompt,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const SignupScreen(),
                              ),
                            ),
                            child: Text(l10n.createAccount),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
