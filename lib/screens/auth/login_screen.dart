import 'package:flutter/material.dart';

import '../../main.dart';
import '../../services/auth/auth_service.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordHidden = true;
  bool _isSubmitting = false;

  FitzaThemeColors _colors(BuildContext context) {
    return Theme.of(context).extension<FitzaThemeColors>()!;
  }

  bool _isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  Color _loginBackground(BuildContext context) {
    return _isDark(context)
        ? const Color(0xFF05080D)
        : const Color(0xFFFCFDFF);
  }

  Color _inputFillColor(BuildContext context) {
    return _isDark(context)
        ? const Color(0xFF202020)
        : const Color(0xFFF8FAFD);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await AuthService.instance.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyAuthErrorMessage(error)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailController.text.trim();

    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter your email address first.'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await AuthService.instance.sendPasswordReset(
        email: email,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyAuthErrorMessage(error)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      await AuthService.instance.signInWithGoogle();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyAuthErrorMessage(error)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      await AuthService.instance.signInWithApple();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyAuthErrorMessage(error)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    final fitzaColors = _colors(context);

    return InputDecoration(
      isDense: true,
      hintText: hintText,
      hintStyle: TextStyle(
        color: fitzaColors.secondaryText,
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: Icon(
        icon,
        color: fitzaColors.secondaryText,
        size: 22,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: _inputFillColor(context),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: fitzaColors.border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: fitzaColors.primaryBlue,
          width: 1.6,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Colors.red,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fitzaColors = _colors(context);
    final isDarkMode = _isDark(context);
    final backgroundColor = _loginBackground(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        bottom: true,
        child: Column(
          children: [
            _topHeroImage(isDarkMode: isDarkMode),

            Expanded(
              child: Container(
                width: double.infinity,
                color: backgroundColor,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 14),

                        Text(
                          'Welcome back',
                          style: TextStyle(
                            color: fitzaColors.primaryText,
                            fontSize: 25,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),

                        const SizedBox(height: 3),

                        Text(
                          'Log in to continue your fitness journey.',
                          style: TextStyle(
                            color: fitzaColors.secondaryText,
                            fontSize: 13.5,
                            height: 1.25,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          style: TextStyle(
                            color: fitzaColors.primaryText,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: _inputDecoration(
                            hintText: 'Email address',
                            icon: Icons.email_outlined,
                          ),
                          validator: (value) {
                            final email = value?.trim() ?? '';

                            if (email.isEmpty) {
                              return 'Enter your email address.';
                            }

                            if (!_isValidEmail(email)) {
                              return 'Enter a valid email address.';
                            }

                            return null;
                          },
                        ),

                        const SizedBox(height: 9),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: _isPasswordHidden,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _signIn(),
                          style: TextStyle(
                            color: fitzaColors.primaryText,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: _inputDecoration(
                            hintText: 'Password',
                            icon: Icons.lock_outline,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordHidden
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: fitzaColors.secondaryText,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordHidden = !_isPasswordHidden;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if ((value ?? '').isEmpty) {
                              return 'Enter your password.';
                            }

                            return null;
                          },
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed:
                                _isSubmitting ? null : _sendPasswordReset,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.only(
                                top: 7,
                                bottom: 5,
                              ),
                              minimumSize: const Size(0, 0),
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Forgot password?',
                              style: TextStyle(
                                color: fitzaColors.primaryBlue,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 3),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _signIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: fitzaColors.primaryBlue,
                              foregroundColor: fitzaColors.textOnBlue,
                              elevation: isDarkMode ? 0 : 3,
                              shadowColor: fitzaColors.primaryBlue
                                  .withValues(alpha: 0.22),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: _isSubmitting
                                ? SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: fitzaColors.textOnBlue,
                                      strokeWidth: 2.4,
                                    ),
                                  )
                                : Text(
                                    'Log In',
                                    style: TextStyle(
                                      color: fitzaColors.textOnBlue,
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 13),

                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: fitzaColors.border,
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                'or continue with',
                                style: TextStyle(
                                  color: fitzaColors.secondaryText,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: fitzaColors.border,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        _socialButton(
                          logoAsset: 'assets/images/auth/google_logo.png',
                          fallbackText: 'G',
                          text: 'Continue with Google',
                          onPressed: _signInWithGoogle,
                        ),

                        // Apple sign-in is kept in code but hidden from users for now.
                        // Enable this later if Apple login is required.
                        /*
                        const SizedBox(height: 8),

                        _socialButton(
                          logoAsset: isDarkMode
                              ? 'assets/images/auth/apple_logo_dark.png'
                              : 'assets/images/auth/apple_logo_light.png',
                          fallbackIcon: Icons.apple,
                          text: 'Continue with Apple',
                          onPressed: _signInWithApple,
                        ),
                        */

                        const SizedBox(height: 12),

                        Center(
                          child: TextButton(
                            onPressed: _isSubmitting
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const SignupScreen(),
                                      ),
                                    );
                                  },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 0,
                                vertical: 6,
                              ),
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text.rich(
                              TextSpan(
                                text: 'Don’t have an account? ',
                                style: TextStyle(
                                  color: fitzaColors.secondaryText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Sign Up',
                                    style: TextStyle(
                                      color: fitzaColors.primaryBlue,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const Spacer(),
                      ],
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

  Widget _topHeroImage({
    required bool isDarkMode,
  }) {
    final assetPath = isDarkMode
        ? 'assets/images/auth/login_hero_dark.png'
        : 'assets/images/auth/login_hero_light.png';

    return Container(
      width: double.infinity,
      color: _loginBackground(context),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.asset(
          assetPath,
          width: double.infinity,
          fit: BoxFit.fill,
          alignment: Alignment.topCenter,
          errorBuilder: (context, error, stackTrace) {
            final fitzaColors = _colors(context);

            return Center(
              child: Text(
                'Image not found:\n$assetPath',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: fitzaColors.primaryBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _socialButton({
    required String logoAsset,
    required String text,
    required VoidCallback onPressed,
    String? fallbackText,
    IconData? fallbackIcon,
  }) {
    final fitzaColors = _colors(context);

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: _isSubmitting ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor:
              _isDark(context) ? const Color(0xFF1A1A1A) : Colors.white,
          foregroundColor: fitzaColors.primaryText,
          side: BorderSide(
            color: fitzaColors.border,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              logoAsset,
              height: 23,
              width: 23,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                if (fallbackIcon != null) {
                  return Icon(
                    fallbackIcon,
                    size: 25,
                    color: fitzaColors.primaryText,
                  );
                }

                return SizedBox(
                  height: 23,
                  width: 23,
                  child: Center(
                    child: Text(
                      fallbackText ?? '',
                      style: TextStyle(
                        color: fitzaColors.primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 14),
            Text(
              text,
              style: TextStyle(
                color: fitzaColors.primaryText,
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}