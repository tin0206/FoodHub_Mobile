import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:foodhub_mobile/screens/login_screen.dart';
import 'package:foodhub_mobile/services/api_exception.dart';
import 'package:foodhub_mobile/services/auth_service.dart';
import 'package:foodhub_mobile/widgets/favorite_toast.dart';
import 'package:foodhub_mobile/widgets/password_requirements.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({
    super.key,
    required this.email,
    this.prefillOtp = '',
    this.popOnSuccess = false,
  });

  final String email;
  final String prefillOtp;
  /// True khi mở từ profile (đang đăng nhập) — pop về thay vì push LoginScreen.
  final bool popOnSuccess;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _otpController;
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isSubmitting = false;
  bool _resending = false;
  bool _otpVerified = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _passwordTouched = false;

  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _otpController = TextEditingController(text: widget.prefillOtp);
  }

  @override
  void dispose() {
    _otpController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _resend() async {
    if (_resending) return;
    setState(() => _resending = true);
    try {
      final result = await _authService.forgotPassword(email: widget.email);
      if (!mounted) return;
      if (result.otp != null && result.otp!.isNotEmpty) {
        _otpController.text = result.otp!;
      }
      setState(() => _otpVerified = false);
      showSuccessToast(context, 'A new code was sent to ${widget.email}.');
    } on ApiException catch (e) {
      if (!mounted) return;
      showErrorToast(context, e.message);
    } catch (_) {
      if (!mounted) return;
      showErrorToast(context, 'Unable to send reset code.');
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      _formKey.currentState?.validate();
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await _authService.verifyResetOtp(email: widget.email, otp: code);
      if (!mounted) return;
      setState(() => _otpVerified = true);
    } on ApiException catch (e) {
      if (!mounted) return;
      showErrorToast(context, e.message);
    } catch (_) {
      if (!mounted) return;
      showErrorToast(context, 'Invalid or expired reset code.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submit() async {
    if (!_otpVerified) {
      await _verifyOtp();
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await _authService.resetPassword(
        email: widget.email,
        otp: _otpController.text.trim(),
        newPassword: _passwordController.text,
      );
      if (!mounted) return;
      showSuccessToast(context, 'Password reset successfully.');
      if (widget.popOnSuccess) {
        Navigator.of(context).pop();
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      showErrorToast(context, e.message);
    } catch (_) {
      if (!mounted) return;
      showErrorToast(context, 'Failed to reset password. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF059669),
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Image.asset(
                        'assets/icons/app_icon.png',
                        fit: BoxFit.contain,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'FoodHub',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _otpVerified ? 'Create a new password' : 'Enter your reset code',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF3F4F6),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.07),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(22),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reset password',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _otpVerified
                              ? 'Code verified. Choose a new password for ${widget.email}'
                              : 'Enter the 6-digit code sent to ${widget.email}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (!_otpVerified) ..._otpFields() else ..._passwordFields(),
                        const SizedBox(height: 20),
                        _primaryButton(
                          loading: _isSubmitting,
                          label: _otpVerified
                              ? (_isSubmitting ? 'Resetting...' : 'Reset password')
                              : (_isSubmitting ? 'Verifying...' : 'Verify code'),
                          onPressed: _isSubmitting
                              ? null
                              : (_otpVerified ? _submit : _verifyOtp),
                        ),
                        if (!_otpVerified) ...[
                          const SizedBox(height: 14),
                          Center(
                            child: GestureDetector(
                              onTap: _resending ? null : _resend,
                              child: Text(
                                _resending ? 'Sending…' : "Didn't get a code? Resend",
                                style: const TextStyle(
                                  color: Color(0xFF059669),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Center(
                          child: GestureDetector(
                            onTap: () {
                              if (_otpVerified) {
                                setState(() => _otpVerified = false);
                              } else {
                                Navigator.of(context).pop();
                              }
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.arrow_back_rounded,
                                  size: 15,
                                  color: Color(0xFF059669),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _otpVerified ? 'Change code' : 'Back',
                                  style: const TextStyle(
                                    color: Color(0xFF059669),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
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
        ],
      ),
    );
  }

  List<Widget> _otpFields() {
    return [
      _label('Reset code'),
      const SizedBox(height: 6),
      TextFormField(
        controller: _otpController,
        keyboardType: TextInputType.number,
        maxLength: 6,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 8,
        ),
        decoration: _inputDecoration(
          hint: '000000',
          icon: Icons.pin_outlined,
        ).copyWith(counterText: ''),
        validator: (v) {
          if (_otpVerified) return null;
          final code = v?.trim() ?? '';
          if (!RegExp(r'^\d{6}$').hasMatch(code)) {
            return 'Enter the 6-digit code from your email.';
          }
          return null;
        },
      ),
    ];
  }

  List<Widget> _passwordFields() {
    return [
      _label('New password'),
      const SizedBox(height: 6),
      TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        onChanged: (_) => setState(() => _passwordTouched = true),
        decoration: _inputDecoration(
          hint: 'New password',
          icon: Icons.lock_outline_rounded,
        ).copyWith(
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 18,
              color: const Color(0xFF94A3B8),
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        validator: (v) {
          if (!_otpVerified) return null;
          if (v == null || v.isEmpty) return 'Please enter a new password.';
          if (v.length < 6) return 'Password must be at least 6 characters.';
          return null;
        },
      ),
      if (_passwordTouched) ...[
        const SizedBox(height: 8),
        PasswordRequirements(password: _passwordController.text),
      ],
      const SizedBox(height: 14),
      _label('Confirm password'),
      const SizedBox(height: 6),
      TextFormField(
        controller: _confirmController,
        obscureText: _obscureConfirm,
        decoration: _inputDecoration(
          hint: 'Confirm new password',
          icon: Icons.lock_outline_rounded,
        ).copyWith(
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirm
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 18,
              color: const Color(0xFF94A3B8),
            ),
            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ),
        validator: (v) {
          if (!_otpVerified) return null;
          if (v == null || v.isEmpty) return 'Please confirm your password.';
          if (v != _passwordController.text) return 'Passwords do not match.';
          return null;
        },
      ),
    ];
  }

  Widget _primaryButton({
    required bool loading,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: loading
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF047857)],
                ),
          color: loading ? const Color(0xFFD1D5DB) : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: loading
              ? []
              : [
                  BoxShadow(
                    color: const Color(0xFF059669).withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

Widget _label(String text) => Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF374151),
      ),
    );

InputDecoration _inputDecoration({required String hint, required IconData icon}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
    prefixIcon: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFEF4444)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
    ),
  );
}
