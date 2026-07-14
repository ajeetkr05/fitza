import 'package:flutter/material.dart';

import '../../main.dart';
import '../../services/auth/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordHidden = true;
  bool _isConfirmPasswordHidden = true;
  bool _isSubmitting = false;

  FitzaThemeColors _colors(BuildContext context) {
    return Theme.of(context).extension<FitzaThemeColors>()!;
  }

  bool _isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  Color _authBackground(BuildContext context) {
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
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
    });

    try {
      await AuthService.instance.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyAuthErrorMessage(error),
          ),
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
    return RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(email);
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
        vertical: 14,
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
    final backgroundColor = _authBackground(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            scrollbars: false,
          ),
          child: SingleChildScrollView(
            keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              18,
              8,
              18,
              20,
            ),
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
                      ),
                      tooltip: 'Back',
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: fitzaColors.primaryText,
                        size: 28,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      'Create your account',
                      style: TextStyle(
                        color: fitzaColors.primaryText,
                        fontSize: 27,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Start tracking your progress every day.',
                      style: TextStyle(
                        color: fitzaColors.secondaryText,
                        fontSize: 13.5,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [
                        AutofillHints.email,
                        AutofillHints.newUsername,
                      ],
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

                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _isPasswordHidden,
                      enableSuggestions: false,
                      autocorrect: false,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [
                        AutofillHints.newPassword,
                      ],
                      style: TextStyle(
                        color: fitzaColors.primaryText,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: _inputDecoration(
                        hintText: 'Password',
                        icon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          tooltip: _isPasswordHidden
                              ? 'Show password'
                              : 'Hide password',
                          icon: Icon(
                            _isPasswordHidden
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: fitzaColors.secondaryText,
                            size: 22,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordHidden =
                                  !_isPasswordHidden;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if ((value ?? '').isEmpty) {
                          return 'Enter a password.';
                        }

                        if ((value ?? '').length < 6) {
                          return 'Use at least 6 characters.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 10),

                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _isConfirmPasswordHidden,
                      enableSuggestions: false,
                      autocorrect: false,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [
                        AutofillHints.newPassword,
                      ],
                      onFieldSubmitted: (_) {
                        if (!_isSubmitting) {
                          _createAccount();
                        }
                      },
                      style: TextStyle(
                        color: fitzaColors.primaryText,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: _inputDecoration(
                        hintText: 'Confirm password',
                        icon: Icons.lock_reset_outlined,
                        suffixIcon: IconButton(
                          tooltip: _isConfirmPasswordHidden
                              ? 'Show password'
                              : 'Hide password',
                          icon: Icon(
                            _isConfirmPasswordHidden
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: fitzaColors.secondaryText,
                            size: 22,
                          ),
                          onPressed: () {
                            setState(() {
                              _isConfirmPasswordHidden =
                                  !_isConfirmPasswordHidden;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if ((value ?? '').isEmpty) {
                          return 'Confirm your password.';
                        }

                        if (value != _passwordController.text) {
                          return 'Passwords do not match.';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed:
                            _isSubmitting ? null : _createAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              fitzaColors.primaryBlue,
                          foregroundColor:
                              fitzaColors.textOnBlue,
                          elevation: isDarkMode ? 0 : 3,
                          shadowColor:
                              fitzaColors.primaryBlue.withValues(
                            alpha: 0.22,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(15),
                          ),
                        ),
                        child: _isSubmitting
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child:
                                    CircularProgressIndicator(
                                  color:
                                      fitzaColors.textOnBlue,
                                  strokeWidth: 2.4,
                                ),
                              )
                            : Text(
                                'Create Account',
                                style: TextStyle(
                                  color:
                                      fitzaColors.textOnBlue,
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    Center(
                      child: TextButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 0,
                            vertical: 6,
                          ),
                          minimumSize: const Size(0, 0),
                          tapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text.rich(
                          TextSpan(
                            text: 'Already have an account? ',
                            style: TextStyle(
                              color:
                                  fitzaColors.secondaryText,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            children: [
                              TextSpan(
                                text: 'Log In',
                                style: TextStyle(
                                  color:
                                      fitzaColors.primaryBlue,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
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
  }
}