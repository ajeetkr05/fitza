import 'package:flutter/material.dart';
import '../app_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isPasswordHidden = true;

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1555C0);
    const darkText = Color(0xFF0B1B4D);
    const greyText = Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // Fitza logo area
                Row(
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      color: primaryBlue,
                      size: 48,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Fitza',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                const Text(
                  'Earn it, Every day',
                  style: TextStyle(
                    fontSize: 20,
                    color: primaryBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 44),

                // Placeholder illustration area
                Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF3FF),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.directions_run_rounded,
                      size: 120,
                      color: primaryBlue,
                    ),
                  ),
                ),

                const SizedBox(height: 42),

                const Text(
                  'Welcome back',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Log in to continue your fitness journey.',
                  style: TextStyle(
                    fontSize: 18,
                    color: greyText,
                  ),
                ),

                const SizedBox(height: 30),

                TextField(
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Email address',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: primaryBlue,
                        width: 2,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  obscureText: _isPasswordHidden,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordHidden
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordHidden = !_isPasswordHidden;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: primaryBlue,
                        width: 2,
                      ),
                    ),
                  ),
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(
                        color: primaryBlue,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AppShell(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Log In',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 26),

                Row(
                  children: const [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'or continue with',
                        style: TextStyle(color: greyText),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 20),

                _socialButton(
                  icon: Icons.g_mobiledata_rounded,
                  text: 'Continue with Google',
                ),

                const SizedBox(height: 14),

                _socialButton(
                  icon: Icons.apple,
                  text: 'Continue with Apple',
                ),

                const SizedBox(height: 24),

                Center(
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 16,
                        color: greyText,
                      ),
                      children: [
                        TextSpan(text: 'Don’t have an account? '),
                        TextSpan(
                          text: 'Sign Up',
                          style: TextStyle(
                            color: primaryBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _socialButton({
    required IconData icon,
    required String text,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: Icon(icon, size: 28),
        label: Text(
          text,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1F2937),
          side: const BorderSide(color: Color(0xFFD1D5DB)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}