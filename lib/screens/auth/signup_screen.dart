import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/icons.dart';
import '../../core/l10n.dart';
import '../../core/tokens.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  bool _acceptedTerms = false;

  // Errors appear only after the first submit, then clear as each field is fixed.
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      setState(() => _autoValidate = AutovalidateMode.onUserInteraction);
      return;
    }
    showAppSnack(context, L10n.of(context).signupDoneSnack);
    context.read<AppState>().signIn();
    // This page sits on top of the login gate, so drop back to it after signing
    // in; the gate swaps itself for the app shell.
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _showTerms() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final dialogL10n = L10n.of(dialogContext);
        return AlertDialog(
          title: Text(dialogL10n.termsDialogTitle),
          content: Text(dialogL10n.termsDialogBody),
          actions: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(dialogL10n.okay),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = L10n.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(l10n.createAccount),
      ),
      body: SafeArea(
        child: Form(
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
                l10n.signupBody,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: l10n.fullNameHint,
                  prefixIcon: const Icon(CoolIcons.user),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.nameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: l10n.emailHint,
                  prefixIcon: const Icon(CoolIcons.envelopeSimple),
                ),
                validator: (value) {
                  final text = (value ?? '').trim();
                  if (text.isEmpty) return null;
                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
                    return l10n.emailInvalid;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscure,
                textInputAction: TextInputAction.next,
                decoration: _passwordDecoration(scheme, l10n),
                validator: (value) {
                  if ((value ?? '').isEmpty) return l10n.passwordRequired;
                  if ((value ?? '').length < 6) return l10n.passwordShort;
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmController,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration:
                    _passwordDecoration(scheme, l10n, hint: l10n.confirmPasswordHint),
                validator: (value) {
                  if (value != _passwordController.text) {
                    return l10n.passwordMismatch;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              FormField<bool>(
                initialValue: _acceptedTerms,
                validator: (value) =>
                    value == true ? null : l10n.termsRequired,
                builder: (field) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: Checkbox(
                            value: _acceptedTerms,
                            onChanged: (value) {
                              setState(() => _acceptedTerms = value ?? false);
                              field.didChange(value ?? false);
                            },
                          ),
                        ),
                        Expanded(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(l10n.termsPrefix),
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  minimumSize: const Size(0, 40),
                                ),
                                onPressed: _showTerms,
                                child: Text(l10n.termsLink),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (field.hasError)
                      Padding(
                        padding: const EdgeInsets.only(left: 44),
                        child: Text(
                          field.errorText ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.error,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  child: Text(l10n.createAccount),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.haveAccountPrompt,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                          builder: (_) => const LoginScreen(),
                        ),
                      ),
                      child: Text(l10n.signIn),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _passwordDecoration(
    ColorScheme scheme,
    L10n l10n, {
    String? hint,
  }) {
    return InputDecoration(
      hintText: hint ?? l10n.passwordHint,
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
