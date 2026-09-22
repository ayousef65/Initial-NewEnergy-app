import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({required this.controller, super.key});

  final AppController controller;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _identifierController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _registerMode = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _identifierController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _brandHeader()),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(
                                value: false,
                                icon: Icon(Icons.login),
                                label: Text('تسجيل الدخول'),
                              ),
                              ButtonSegment(
                                value: true,
                                icon: Icon(Icons.person_add_alt_1_outlined),
                                label: Text('حساب جديد'),
                              ),
                            ],
                            selected: {_registerMode},
                            showSelectedIcon: false,
                            onSelectionChanged: (selection) {
                              setState(() {
                                _registerMode = selection.first;
                                _formKey.currentState?.reset();
                              });
                            },
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _registerMode
                                ? 'إنشاء حساب الخدمة'
                                : 'مرحباً بعودتك',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _registerMode
                                ? 'أنشئ حساباً لحفظ الطلبات والتقارير والفواتير باسمك.'
                                : 'ادخل إلى سجل طلباتك ومتابعة الصيانة.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 22),
                          if (_registerMode) ...[
                            TextFormField(
                              key: const Key('register-name'),
                              controller: _nameController,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.name],
                              decoration: const InputDecoration(
                                labelText: 'الاسم الكامل',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: _requiredValidator,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              key: const Key('register-email'),
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              textDirection: TextDirection.ltr,
                              autofillHints: const [AutofillHints.email],
                              decoration: const InputDecoration(
                                labelText: 'البريد الإلكتروني',
                                prefixIcon: Icon(Icons.alternate_email),
                              ),
                              validator: (value) {
                                final email = value?.trim() ?? '';
                                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                    .hasMatch(email)) {
                                  return 'أدخل بريداً إلكترونياً صحيحاً';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              key: const Key('register-phone'),
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              textDirection: TextDirection.ltr,
                              autofillHints: const [
                                AutofillHints.telephoneNumber,
                              ],
                              decoration: const InputDecoration(
                                labelText: 'رقم الهاتف',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                              validator: (value) {
                                final phone = (value ?? '').replaceAll(
                                  RegExp(r'\D'),
                                  '',
                                );
                                if (phone.length < 8 || phone.length > 15) {
                                  return 'أدخل رقم هاتف صحيحاً';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                          ] else ...[
                            TextFormField(
                              key: const Key('login-identifier'),
                              controller: _identifierController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              textDirection: TextDirection.ltr,
                              autofillHints: const [
                                AutofillHints.username,
                                AutofillHints.email,
                              ],
                              decoration: const InputDecoration(
                                labelText: 'البريد أو رقم الهاتف',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: _requiredValidator,
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextFormField(
                            key: const Key('auth-password'),
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: _registerMode
                                ? TextInputAction.next
                                : TextInputAction.done,
                            textDirection: TextDirection.ltr,
                            autofillHints: [
                              _registerMode
                                  ? AutofillHints.newPassword
                                  : AutofillHints.password,
                            ],
                            onFieldSubmitted: _registerMode
                                ? null
                                : (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: 'كلمة المرور',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword
                                    ? 'إظهار كلمة المرور'
                                    : 'إخفاء كلمة المرور',
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if ((value ?? '').isEmpty) {
                                return 'أدخل كلمة المرور';
                              }
                              if (_registerMode && (value?.length ?? 0) < 10) {
                                return 'استخدم 10 أحرف على الأقل';
                              }
                              return null;
                            },
                          ),
                          if (_registerMode) ...[
                            const SizedBox(height: 12),
                            TextFormField(
                              key: const Key('register-confirmation'),
                              controller: _confirmationController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              textDirection: TextDirection.ltr,
                              autofillHints: const [AutofillHints.newPassword],
                              onFieldSubmitted: (_) => _submit(),
                              decoration: const InputDecoration(
                                labelText: 'تأكيد كلمة المرور',
                                prefixIcon: Icon(Icons.lock_reset_outlined),
                              ),
                              validator: (value) =>
                                  value != _passwordController.text
                                  ? 'كلمتا المرور غير متطابقتين'
                                  : null,
                            ),
                          ] else
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                onPressed: widget.controller.isAuthBusy
                                    ? null
                                    : _showPasswordReset,
                                child: const Text('نسيت كلمة المرور؟'),
                              ),
                            ),
                          const SizedBox(height: 10),
                          AsyncButton(
                            label: _registerMode ? 'إنشاء الحساب' : 'دخول آمن',
                            icon: _registerMode
                                ? Icons.person_add_alt_1
                                : Icons.login,
                            busy: widget.controller.isAuthBusy,
                            onPressed: _submit,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _brandHeader() {
    return ColoredBox(
      color: AppColors.brand,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 34, 24, 30),
        child: Column(
          children: [
            Image.asset(
              'assets/newenergy_logo.png',
              height: 58,
              fit: BoxFit.contain,
              semanticLabel: 'New Energy',
            ),
            const SizedBox(height: 18),
            const Text(
              'خدمة سيارتك الكهربائية في مكان واحد',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    return (value?.trim().isEmpty ?? true) ? 'هذا الحقل مطلوب' : null;
  }

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final result = _registerMode
        ? await widget.controller.register(
            displayName: _nameController.text,
            email: _emailController.text,
            phone: _phoneController.text,
            password: _passwordController.text,
            passwordConfirmation: _confirmationController.text,
          )
        : await widget.controller.login(
            _identifierController.text,
            _passwordController.text,
          );

    if (!mounted || result.success) return;
    showAppMessage(context, result.message, isError: true);
  }

  Future<void> _showPasswordReset() async {
    final resetController = TextEditingController(
      text: _identifierController.text,
    );
    final identifier = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('استعادة كلمة المرور'),
        content: TextField(
          controller: resetController,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          textDirection: TextDirection.ltr,
          decoration: const InputDecoration(
            labelText: 'البريد أو رقم الهاتف',
            prefixIcon: Icon(Icons.alternate_email),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, resetController.text),
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
    resetController.dispose();
    if (identifier == null || !mounted) return;

    final result = await widget.controller.requestPasswordReset(identifier);
    if (!mounted) return;
    showAppMessage(context, result.message, isError: !result.success);
  }
}
