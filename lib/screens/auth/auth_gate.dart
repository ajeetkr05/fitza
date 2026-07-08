import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/profile/user_profile.dart';
import '../../services/auth/auth_service.dart';
import '../../services/profile/profile_firestore_service.dart';
import '../app_shell.dart';
import 'login_screen.dart';
import 'onboarding_profile_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
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

        if (authSnapshot.data == null) {
          return const LoginScreen();
        }

        return StreamBuilder<UserProfile>(
          stream: ProfileFirestoreService.instance.getProfileStream(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
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

            if (profile == null || !profile.profileSetupCompleted) {
              return const OnboardingProfileScreen();
            }

            return const AppShell();
          },
        );
      },
    );
  }
}