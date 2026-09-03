import 'package:flutter/material.dart';
import 'package:foodhub_mobile/models/user.dart';
import 'package:foodhub_mobile/screens/admin/admin_shell_screen.dart';
import 'package:foodhub_mobile/screens/login_screen.dart';
import 'package:foodhub_mobile/screens/main_shell_screen.dart';
import 'package:foodhub_mobile/screens/onboarding_screen.dart';
import 'package:foodhub_mobile/services/api_exception.dart';
import 'package:foodhub_mobile/services/auth_service.dart';
import 'package:foodhub_mobile/services/google_auth_service.dart';
import 'package:foodhub_mobile/widgets/favorite_toast.dart';
import 'package:foodhub_mobile/widgets/password_requirements.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSubmitting = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _passwordTouched = false;

  final _authService = AuthService();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final user = await _authService.signUp(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => user.role == 'admin'
              ? AdminShellScreen(user: user)
              : OnboardingScreen(user: user),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      showErrorToast(context, e.message);
    } catch (_) {
      if (!mounted) return;
      showErrorToast(context, 'Unable to create account.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// A brand-new Google sign-up has no profile data yet; a returning Google
  /// user does. There's no explicit "new account" flag from the API, so this
  /// is the signal used to decide whether to show the onboarding survey.
  bool _looksLikeFreshProfile(UserModel user) =>
      user.age == null &&
      user.weight == null &&
      (user.primaryGoal == null || user.primaryGoal!.isEmpty) &&
      user.dietaryRestrictions.isEmpty;

  Future<void> _signUpWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    try {
      final result = await GoogleAuthService.signIn();
      if (result == null) return; // user hủy
      if (!mounted) return;
      final user = await _authService.signInWithGoogle(
        token: result.token,
        tokenType: result.type,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => user.role == 'admin'
              ? AdminShellScreen(user: user)
              : (_looksLikeFreshProfile(user)
                    ? OnboardingScreen(user: user)
                    : MainShellScreen(initialUser: user)),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      showErrorToast(context, e.message);
    } catch (e) {
      if (!mounted) return;
      showErrorToast(context, e.toString());
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _isSubmitting || _isGoogleLoading;

    return Scaffold(
      backgroundColor: const Color(0xFF059669),
      body: Column(
        children: [
          // ── Compact hero ──────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Image.asset(
                        'assets/icons/app_icon.png',
                        fit: BoxFit.contain,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'FoodHub',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Text(
                        'Your personal recipe assistant',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Form section ──────────────────────────────────────────────
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF3F4F6),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Create account ✨',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Start your healthier eating journey',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 16),

                    AuthSocialButton(
                      onPressed: isLoading ? null : _signUpWithGoogle,
                      isLoading: _isGoogleLoading,
                      label: 'Sign up with Google',
                    ),
                    const SizedBox(height: 14),
                    const AuthOrDivider(),
                    const SizedBox(height: 14),

                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const _FieldLabel('Full name'),
                                    const SizedBox(height: 5),
                                    TextFormField(
                                      controller: _fullNameController,
                                      textCapitalization:
                                          TextCapitalization.words,
                                      decoration: authInputDecoration(
                                        hint: 'John Doe',
                                        icon: Icons.person_outline_rounded,
                                      ),
                                      validator: (v) {
                                        final name = v?.trim() ?? '';
                                        if (name.isEmpty) {
                                          return 'Please enter your full name.';
                                        }
                                        if (name.length < 2) {
                                          return 'Name must be at least 2 characters.';
                                        }
                                        if (name.length > 50) {
                                          return 'Name must be under 50 characters.';
                                        }
                                        if (!RegExp(
                                          r"^[a-zA-ZÀ-ỹ\s'\-]+$",
                                        ).hasMatch(name)) {
                                          return 'Name can only contain letters and spaces.';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const _FieldLabel('Email'),
                                    const SizedBox(height: 5),
                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: authInputDecoration(
                                        hint: 'you@example.com',
                                        icon: Icons.mail_outline_rounded,
                                      ),
                                      validator: (v) {
                                        final email = v?.trim() ?? '';
                                        if (email.isEmpty) {
                                          return 'Please enter your email.';
                                        }
                                        if (!RegExp(
                                          r'^[\w.+\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$',
                                        ).hasMatch(email)) {
                                          return 'Please enter a valid email address.';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 11),
                          const _FieldLabel('Password'),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration:
                                authInputDecoration(
                                  hint: '••••••••',
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
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                  ),
                                ),
                            onChanged: (_) =>
                                setState(() => _passwordTouched = true),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Please enter your password.';
                              }
                              if (v.length < 6) {
                                return 'Password must be at least 6 characters.';
                              }
                              return null;
                            },
                          ),
                          if (_passwordTouched) ...[
                            const SizedBox(height: 8),
                            PasswordRequirements(
                              password: _passwordController.text,
                            ),
                          ],
                          const SizedBox(height: 11),
                          const _FieldLabel('Confirm password'),
                          const SizedBox(height: 5),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration:
                                authInputDecoration(
                                  hint: '••••••••',
                                  icon: Icons.lock_outline_rounded,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 18,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                    onPressed: () => setState(
                                      () => _obscureConfirmPassword =
                                          !_obscureConfirmPassword,
                                    ),
                                  ),
                                ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Please confirm your password.';
                              }
                              if (v != _passwordController.text) {
                                return 'Passwords do not match.';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),
                    AuthGradientButton(
                      onPressed: isLoading ? null : _createAccount,
                      isLoading: _isSubmitting,
                      label: 'Create account',
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account?  ',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                          ),
                        ),
                        GestureDetector(
                          onTap: isLoading
                              ? null
                              : () => Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                ),
                          child: const Text(
                            'Sign in',
                            style: TextStyle(
                              color: Color(0xFF059669),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: Color(0xFF374151),
      ),
    );
  }
}
