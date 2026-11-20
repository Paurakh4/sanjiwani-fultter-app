import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:provider/provider.dart';

import '../../core/icons.dart';
import '../../core/l10n.dart';
import '../../core/tokens.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';

/// Password recovery by email link.
///
/// There is deliberately no in-app code step: PocketBase sends a signed link,
/// and a number the patient could type here would only look like security.
/// Patients who registered with a phone number have no email to receive that
/// link, so the screen says so and points at the clinic's number instead.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _busy = false;
  bool _sent = false;

  // Errors appear after the first submit, then clear as the field is fixed.
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      setState(() => _autoValidate = AutovalidateMode.onUserInteraction);
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);

    final l10n = L10n.of(context);
    try {
      await context.read<AppState>().requestPasswordReset(
        _emailController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _sent = true);
    } on ClientException catch (error) {
      if (!mounted) return;
      showAppSnack(
        context,
        error.statusCode == 0
            ? l10n.signInNetworkError
            : l10n.resetEmailUnknown('${error.response['message'] ?? ''}'),
      );
    } catch (_) {
      if (!mounted) return;
      showAppSnack(context, l10n.signInNetworkError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _backToLogin() => Navigator.of(context).popUntil((route) => route.isFirst);

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
          child: _sent
              ? _SentStep(key: const ValueKey('sent'), onBackToLogin: _backToLogin)
              : _requestForm(theme, scheme, l10n),
        ),
      ),
    );
  }

  Widget _requestForm(ThemeData theme, ColorScheme scheme, L10n l10n) {
    return Form(
      key: _formKey,
      autovalidateMode: _autoValidate,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppTokens.gutter, 4, AppTokens.gutter, 28),
        children: [
          Text(
            l10n.resetTitle,
            key: const ValueKey('heading'),
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.resetBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _send(),
            decoration: InputDecoration(
              hintText: l10n.emailHint,
              prefixIcon: const Icon(CoolIcons.envelopeSimple),
            ),
            validator: (value) {
              final text = (value ?? '').trim();
              if (text.isEmpty) return l10n.emailRequired;
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
                return l10n.emailInvalid;
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          Text(
            l10n.resetPhoneOnlyNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _busy ? null : _send,
              child: Text(_busy ? l10n.loading : l10n.resetSendLink),
            ),
          ),
        ],
      ),
    );
  }
}

class _SentStep extends StatelessWidget {
  const _SentStep({super.key, required this.onBackToLogin});

  final VoidCallback onBackToLogin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = L10n.of(context);

    return ListView(
      key: const ValueKey('sent'),
      padding: const EdgeInsets.fromLTRB(AppTokens.gutter, 4, AppTokens.gutter, 28),
      children: [
        Icon(CoolIcons.envelopeSimple, size: 56, color: scheme.primary),
        const SizedBox(height: 18),
        Text(l10n.resetSentTitle, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          l10n.resetSentBody,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: FilledButton(onPressed: onBackToLogin, child: Text(l10n.backToLogin)),
        ),
      ],
    );
  }
}
