import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/profile/user_profile.dart';
import '../../services/auth/auth_service.dart';
import '../../services/profile/profile_firestore_service.dart';
import '../app_shell.dart';
import 'login_screen.dart';
import 'onboarding_profile_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _themeInitializedForUserId;
  bool _themeResetScheduled = false;

  void _initializeTheme({
    required String userId,
    required String storedThemeMode,
  }) {
    if (_themeInitializedForUserId == userId) {
      return;
    }

    _themeInitializedForUserId = userId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      FitzaThemeController.initializeFromProfile(
        storedThemeMode,
      );
    });
  }

  void _resetThemeAfterLogout() {
    if (_themeInitializedForUserId == null ||
        _themeResetScheduled) {
      return;
    }

    _themeInitializedForUserId = null;
    _themeResetScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _themeResetScheduled = false;

      if (!mounted) {
        return;
      }

      FitzaThemeController.resetToSystem();
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (authSnapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Could not check your login status. Please restart the app.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final currentUser = authSnapshot.data;

        if (currentUser == null) {
          _resetThemeAfterLogout();
          return const LoginScreen();
        }

        return StreamBuilder<UserProfile>(
          stream: ProfileFirestoreService.instance
              .getProfileStream(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState ==
                ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (profileSnapshot.hasError) {
              return const Scaffold(
                body: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Could not load your profile. Please restart the app.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }

            final profile = profileSnapshot.data;

            if (profile == null ||
                !profile.profileSetupCompleted) {
              return const OnboardingProfileScreen();
            }

            _initializeTheme(
              userId: currentUser.uid,
              storedThemeMode: profile.themeMode,
            );

            return const AppShell();
          },
        );
      },
    );
  }
}