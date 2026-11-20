import 'package:flutter/material.dart';

import '../../core/icons.dart';
import '../../core/l10n.dart';
import '../../core/nepali.dart' as np;
import '../../core/tokens.dart';
import '../../widgets/common.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const _totalSteps = 3;

  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  int _step = 0; // 0 phone, 1 code, 2 new password, 3 done

  // Errors appear after the first submit, then clear as fields are fixed.
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String get _phoneDisplay {
    final digits = _phoneController.text.replaceAll(RegExp(r'[^0-9०-९]'), '');
    return L10n.of(context).digits(digits);
  }

  void _next() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      setState(() => _autoValidate = AutovalidateMode.onUserInteraction);
      return;
    }
    setState(() {
      _codeController.clear();
      _step += 1;
    });
  }

  void _finish() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      setState(() => _autoValidate = AutovalidateMode.onUserInteraction);
      return;
    }
    setState(() => _step = 3);
  }

  void _backToLogin() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = L10n.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(l10n.resetTitle),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: AppTokens.motionMedium,
          switchInCurve: AppTokens.ease,
          child: KeyedSubtree(
            key: ValueKey('step-$_step'),
            child: _step == 3
                ? _DoneStep(
                    onBackToLogin: _backToLogin,
                    onStart: () => setState(() => _step = 0),
                  )
                : Form(
                    key: _formKey,
                    autovalidateMode: _autoValidate,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppTokens.gutter,
                        4,
                        AppTokens.gutter,
                        28,
                      ),
                      children: [
                        Text(
                          l10n.stepOf(_step + 1, _totalSteps),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_step < 2)
                          Text(
                            _step == 0
                                ? l10n.resetBody
                                : l10n.codeSentNote(_phoneDisplay),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        if (_step < 2) const SizedBox(height: 20),
                        if (_step == 0)
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _next(),
                            decoration: InputDecoration(
                              hintText: l10n.phoneHint,
                              prefixIcon: const Icon(CoolIcons.phone),
                            ),
                            validator: (value) {
                              final digits = (value ?? '').replaceAll(
                                RegExp(r'[^0-9०-९]'),
                                '',
                              );
                              if (digits.length < 7) return l10n.phoneInvalid;
                              return null;
                            },
                          ),
                        if (_step == 1) _buildCodeField(theme),
                        if (_step == 2) ...[
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.next,
                            decoration: _passwordDecoration(scheme, l10n),
                            validator: (value) {
                              if ((value ?? '').isEmpty) {
                                return l10n.passwordRequired;
                              }
                              if ((value ?? '').length < 6) {
                                return l10n.passwordShort;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _confirmController,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _finish(),
                            decoration: _passwordDecoration(
                              scheme,
                              l10n,
                              hint: l10n.confirmPasswordHint,
                            ),
                            validator: (value) {
                              if (value != _passwordController.text) {
                                return l10n.passwordMismatch;
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _step == 2 ? _finish : _next,
                            child: Text(
                              _step == 0
                                  ? l10n.sendCode
                                  : _step == 1
                                  ? l10n.verifyCode
                                  : l10n.resetPassword,
                            ),
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

  Widget _buildCodeField(ThemeData theme) {
    final l10n = L10n.of(context);
    return TextFormField(
      controller: _codeController,
      keyboardType: TextInputType.number,
      maxLength: 4,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _next(),
      textAlign: TextAlign.center,
      style: theme.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 14,
      ),
      decoration: InputDecoration(
        hintText: '••••',
        counterText: '',
        prefixIcon: Center(
          widthFactor: 1,
          child: CoolSvgIcon(
            'key-round',
            size: 22,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      validator: (value) {
        final digits = np.asciiDigits(value ?? '').replaceAll(
          RegExp(r'[^0-9]'),
          '',
        );
        if (digits.length != 4) return l10n.codeInvalid;
        return null;
      },
    );
  }

  InputDecoration _passwordDecoration(
    ColorScheme scheme,
    L10n l10n, {
    String? hint,
  }) {
    return InputDecoration(
      hintText: hint ?? l10n.newPasswordHint,
      prefixIcon: Center(
        widthFactor: 1,
        child: CoolSvgIcon('lock-round', size: 22, color: scheme.onSurfaceVariant),
      ),
      suffixIcon: IconButton(
        onPressed: () => setState(() => _obscure = !_obscure),
        icon: CoolSvgIcon(
          _obscure ? 'eye-round' : 'eye-off-round',
          size: 22,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _DoneStep extends StatelessWidget {
  const _DoneStep({required this.onBackToLogin, required this.onStart});

  final VoidCallback onBackToLogin;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = L10n.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.gutter,
        4,
        AppTokens.gutter,
        28,
      ),
      children: [
        const SizedBox(height: 48),
        Center(
          child: TonalIcon(
            icon: CoolIcons.checkCircleFill,
            size: 76,
            iconSize: 34,
            background: scheme.primaryContainer,
            foreground: scheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.resetDoneTitle,
          style: theme.textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.resetDoneBody,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onBackToLogin,
            child: Text(l10n.backToLogin),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onStart,
            child: Text(l10n.forgotPassword),
          ),
        ),
      ],
    );
  }
}
