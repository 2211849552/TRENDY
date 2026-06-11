import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'l10n/app_strings.dart';
import 'services/api/api_exception.dart';
import 'services/api/password_reset_api.dart';
import 'theme/app_colors.dart';

enum _ResetStep { email, otp, newPassword }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static final _emailRegex = RegExp(r'^[\w.\-+]+@[\w.\-]+\.[a-zA-Z]{2,}$');

  final _passwordResetApi = PasswordResetApi();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  _ResetStep _step = _ResetStep.email;
  bool _isLoading = false;
  String _resetToken = '';

  @override
  void dispose() {
    _passwordResetApi.dispose();
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_isLoading) return;

    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty) {
      _showMessage(context.tr('login_email_required'), isError: true);
      return;
    }
    if (!_emailRegex.hasMatch(email)) {
      _showMessage(context.tr('login_email_invalid'), isError: true);
      return;
    }

    _emailController.text = email;

    setState(() => _isLoading = true);
    try {
      final message = await _passwordResetApi.sendOtp(email: email);
      if (!mounted) return;
      _otpController.clear();
      _showMessage(
        message.isNotEmpty ? message : context.tr('reset_otp_sent'),
        isError: false,
      );
      setState(() => _step = _ResetStep.otp);
    } on ApiException catch (e) {
      if (!mounted) return;
      _showMessage(
        e.message.isNotEmpty ? e.message : context.tr('reset_send_failed'),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_isLoading) return;

    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty || !_emailRegex.hasMatch(email)) return;

    setState(() => _isLoading = true);
    try {
      final message = await _passwordResetApi.sendOtp(email: email);
      if (!mounted) return;
      _otpController.clear();
      _showMessage(
        message.isNotEmpty ? message : context.tr('reset_otp_resent_new'),
        isError: false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      _showMessage(
        e.message.isNotEmpty ? e.message : context.tr('reset_send_failed'),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_isLoading) return;

    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      _showMessage(context.tr('verify_otp_invalid'), isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await _passwordResetApi.verifyOtp(
        email: _emailController.text.trim().toLowerCase(),
        otp: otp,
      );
      if (!mounted) return;
      _resetToken = result.token;
      _showMessage(
        result.message.isNotEmpty ? result.message : context.tr('reset_otp_verified'),
        isError: false,
      );
      setState(() => _step = _ResetStep.newPassword);
    } on ApiException catch (e) {
      if (!mounted) return;
      _showMessage(
        e.message.isNotEmpty ? e.message : context.tr('reset_verify_failed'),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (password.isEmpty || confirm.isEmpty) {
      _showMessage(context.tr('pwd_fill_all'), isError: true);
      return;
    }
    if (password.length < 8) {
      _showMessage(context.tr('pwd_short'), isError: true);
      return;
    }
    if (password != confirm) {
      _showMessage(context.tr('pwd_mismatch'), isError: true);
      return;
    }

    if (_resetToken.isEmpty) {
      _showMessage(context.tr('reset_session_expired'), isError: true);
      setState(() => _step = _ResetStep.otp);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final message = await _passwordResetApi.resetPassword(
        password: password,
        passwordConfirmation: confirm,
        resetToken: _resetToken,
        email: _emailController.text.trim().toLowerCase(),
      );
      if (!mounted) return;
      _showMessage(
        message.isNotEmpty ? message : context.tr('reset_success'),
        isError: false,
      );
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      final message = e.message.isNotEmpty ? e.message : context.tr('reset_failed');
      final sessionExpired = message.contains('انتهت صلاحية') ||
          message.toLowerCase().contains('expired');
      if (sessionExpired) {
        setState(() {
          _step = _ResetStep.email;
          _resetToken = '';
          _otpController.clear();
          _passwordController.clear();
          _confirmPasswordController.clear();
        });
      }
      _showMessage(message, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Cairo')),
        backgroundColor: isError ? Colors.redAccent.shade700 : Colors.green.shade700,
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white30),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white30),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case _ResetStep.email:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('forgot_pwd_subtitle'),
              style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
            ),
            const SizedBox(height: 32),
            Text(
              context.tr('email'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: _fieldDecoration(context.tr('hint_email')),
            ),
            const SizedBox(height: 32),
            _primaryButton(
              label: context.tr('send_otp_btn'),
              onPressed: _isLoading ? null : _sendOtp,
            ),
          ],
        );

      case _ResetStep.otp:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('reset_otp_subtitle'),
              style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
            ),
            const SizedBox(height: 8),
            Text(
              _emailController.text.trim(),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('verify_otp_label'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _fieldDecoration('000000').copyWith(counterText: ''),
            ),
            const SizedBox(height: 32),
            _primaryButton(
              label: context.tr('verify_otp_btn'),
              onPressed: _isLoading ? null : _verifyOtp,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isLoading ? null : _resendOtp,
              child: Text(
                context.tr('verify_resend_btn'),
                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );

      case _ResetStep.newPassword:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('reset_new_pwd_subtitle'),
              style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
            ),
            const SizedBox(height: 24),
            Text(
              context.tr('login_password'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: _fieldDecoration(context.tr('hint_password')),
            ),
            const SizedBox(height: 20),
            Text(
              context.tr('confirm_password'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: _fieldDecoration(context.tr('hint_password')),
            ),
            const SizedBox(height: 32),
            _primaryButton(
              label: context.tr('reset_pwd_btn'),
              onPressed: _isLoading ? null : _resetPassword,
            ),
          ],
        );
    }
  }

  Widget _primaryButton({required String label, required VoidCallback? onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
              )
            : Text(
                label,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Directionality(
                        textDirection: context.isRtl ? TextDirection.rtl : TextDirection.ltr,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('forgot_pwd_title'),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildStepContent(),
                            const SizedBox(height: 24),
                            Center(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  context.tr('back_to_login'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
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
          },
        ),
      ),
    );
  }
}
