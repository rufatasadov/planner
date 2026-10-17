import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/auth_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../../widgets/keyboard_sheet.dart';
import '../../widgets/logo.dart';
import 'auth_scaffold.dart';
import 'auth_widgets.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _email = TextEditingController();
  final _form = GlobalKey<FormState>();
  var _busy = false;
  String? _sentTo;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).forgotPassword(_email.text.trim());
      setState(() => _sentTo = _email.text.trim());
    } catch (e) {
      setState(
        () => _error = apiErrorMessage(e, l10n.networkError, l10n.genericError),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: AppLogo(size: 56)),
          const SizedBox(height: 18),
          AuthCard(
            child:
                _sentTo != null
                    ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Icon(
                          Icons.mark_email_read_outlined,
                          size: 28,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l10n.forgotTitle,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.forgotSent(_sentTo!),
                          style: TextStyle(
                            color: mutedColor(context),
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: Text(l10n.backToLogin),
                        ),
                      ],
                    )
                    : Form(
                      key: _form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.forgotTitle,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.forgotText,
                            style: TextStyle(
                              color: mutedColor(context),
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _email,
                            keyboardType: TextInputType.emailAddress,
                            scrollPadding: fieldScrollPadding,
                            autofillHints: const [AutofillHints.email],
                            autocorrect: false,
                            enableSuggestions: false,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _busy ? null : _submit(),
                            decoration: InputDecoration(
                              hintText: l10n.email,
                              prefixIcon: const Icon(Icons.mail_outline),
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.never,
                            ),
                            validator: (v) {
                              final value = v?.trim() ?? '';
                              if (!RegExp(
                                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                              ).hasMatch(value)) {
                                return l10n.invalidEmail;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          AuthErrorBanner(message: _error),
                          const SizedBox(height: 12),
                          AuthPrimaryButton(
                            label: l10n.sendLink,
                            busy: _busy,
                            onPressed: _submit,
                          ),
                          const SizedBox(height: 4),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            child: Text(l10n.backToLogin),
                          ),
                        ],
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
