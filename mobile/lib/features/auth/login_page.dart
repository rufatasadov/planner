import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/auth_controller.dart';
import '../../auth/auth_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';
import '../../widgets/keyboard_sheet.dart';
import '../../widgets/logo.dart';
import 'auth_scaffold.dart';
import 'auth_widgets.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _register = false;
  var _busy = false;
  var _obscure = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _email.text.isNotEmpty || _password.text.isNotEmpty) {
        return;
      }
      FocusManager.instance.primaryFocus?.unfocus();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
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
      final auth = ref.read(authControllerProvider.notifier);
      if (_register) {
        await auth.register(
          _name.text.trim(),
          _email.text.trim(),
          _password.text,
        );
      } else {
        await auth.login(_email.text.trim(), _password.text);
      }
    } catch (e) {
      if (mounted) {
        setState(
          () =>
              _error = apiErrorMessage(e, l10n.networkError, l10n.genericError),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _setMode(bool register) {
    if (_register == register) return;
    setState(() {
      _register = register;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AuthScaffold(
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: AppLogo(size: 64)),
            const SizedBox(height: 14),
            const Center(child: Wordmark()),
            const SizedBox(height: 8),
            Text(
              _register ? l10n.welcomeRegisterHint : l10n.welcomeLoginHint,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: mutedColor(context),
                height: 1.4,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 22),
            AuthCard(
              child: Form(
                key: _form,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AuthModeSwitch(
                        register: _register,
                        loginLabel: l10n.login,
                        registerLabel: l10n.register,
                        onChanged: _setMode,
                      ),
                      const SizedBox(height: 18),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        alignment: Alignment.topCenter,
                        child:
                            _register
                                ? Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: TextFormField(
                                    controller: _name,
                                    textCapitalization:
                                        TextCapitalization.words,
                                    textInputAction: TextInputAction.next,
                                    scrollPadding: fieldScrollPadding,
                                    autofillHints: const [AutofillHints.name],
                                    decoration: InputDecoration(
                                      hintText: l10n.name,
                                      prefixIcon: const Icon(
                                        Icons.person_outline,
                                      ),
                                      floatingLabelBehavior:
                                          FloatingLabelBehavior.never,
                                    ),
                                    validator:
                                        (v) =>
                                            (v == null || v.trim().isEmpty)
                                                ? l10n.nameRequired
                                                : null,
                                  ),
                                )
                                : const SizedBox(width: double.infinity),
                      ),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        scrollPadding: fieldScrollPadding,
                        autofillHints: const [AutofillHints.email],
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: InputDecoration(
                          hintText: l10n.email,
                          prefixIcon: const Icon(Icons.mail_outline),
                          floatingLabelBehavior: FloatingLabelBehavior.never,
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
                      TextFormField(
                        controller: _password,
                        obscureText: _obscure,
                        scrollPadding: fieldScrollPadding,
                        autofillHints: [
                          if (_register)
                            AutofillHints.newPassword
                          else
                            AutofillHints.password,
                        ],
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) {
                          if (_busy ||
                              (_email.text.trim().isEmpty &&
                                  _password.text.isEmpty)) {
                            return;
                          }
                          _submit();
                        },
                        decoration: InputDecoration(
                          hintText: l10n.password,
                          prefixIcon: const Icon(Icons.lock_outline),
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                          suffixIcon: IconButton(
                            onPressed:
                                () => setState(() => _obscure = !_obscure),
                            tooltip:
                                _obscure
                                    ? l10n.showPassword
                                    : l10n.hidePassword,
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator:
                            (v) =>
                                (v == null || v.length < 6)
                                    ? l10n.passwordTooShort
                                    : null,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 150),
                          opacity: _register ? 0 : 1,
                          child: TextButton(
                            onPressed:
                                _register
                                    ? null
                                    : () => context.push('/forgot-password'),
                            style: TextButton.styleFrom(
                              foregroundColor:
                                  Theme.of(context).colorScheme.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              minimumSize: const Size(0, 40),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(l10n.forgot),
                          ),
                        ),
                      ),
                      AuthErrorBanner(message: _error),
                      const SizedBox(height: 8),
                      AuthPrimaryButton(
                        label: _register ? l10n.createAccount : l10n.login,
                        busy: _busy,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
