import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'firebase_options.dart';
import 'screens/auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const FitzaApp());
}

class FitzaThemeController {
  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  static void setDarkModeEnabled(bool isEnabled) {
    themeMode.value = isEnabled ? ThemeMode.dark : ThemeMode.system;
  }
}

class FitzaApp extends StatelessWidget {
  const FitzaApp({super.key});

  static const Color primaryBlue = Color(0xFF1555C0);
  static const Color accentBlue = Color(0xFF42A5F5);
  static const Color successGreen = Color(0xFF2E7D32);

  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightInputSurface = Color(0xFFF9FBFE);
  static const Color lightPrimaryText = Color(0xFF0B1B4D);
  static const Color lightSecondaryText = Color(0xFF667085);
  static const Color lightBorder = Color(0xFFE1E7F0);

  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkInputSurface = Color(0xFF252525);
  static const Color darkPrimaryText = Color(0xFFF5F5F5);
  static const Color darkSecondaryText = Color(0xFFBDBDBD);
  static const Color darkBorder = Color(0xFF333333);

  ThemeData _lightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.light,
      primary: primaryBlue,
      secondary: accentBlue,
      surface: lightSurface,
      onSurface: lightPrimaryText,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: lightBackground,
      primaryColor: primaryBlue,
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBackground,
        foregroundColor: lightPrimaryText,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightInputSurface,
        hintStyle: const TextStyle(
          color: lightSecondaryText,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: const TextStyle(
          color: lightSecondaryText,
          fontWeight: FontWeight.w600,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFB7C1D3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: primaryBlue,
            width: 1.7,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: lightBorder,
      ),
      iconTheme: const IconThemeData(
        color: lightPrimaryText,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: lightPrimaryText),
        titleMedium: TextStyle(color: lightPrimaryText),
        titleSmall: TextStyle(color: lightPrimaryText),
        bodyLarge: TextStyle(color: lightPrimaryText),
        bodyMedium: TextStyle(color: lightPrimaryText),
        bodySmall: TextStyle(color: lightSecondaryText),
        labelLarge: TextStyle(color: lightPrimaryText),
        labelMedium: TextStyle(color: lightSecondaryText),
        labelSmall: TextStyle(color: lightSecondaryText),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF9BB7EA),
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      extensions: const [
        FitzaThemeColors(
          background: lightBackground,
          surface: lightSurface,
          inputSurface: lightInputSurface,
          primaryText: lightPrimaryText,
          secondaryText: lightSecondaryText,
          border: lightBorder,
          primaryBlue: primaryBlue,
          accentBlue: accentBlue,
          successGreen: successGreen,
          disabled: Color(0xFF757575),
          textOnBlue: Colors.white,
        ),
      ],
    );
  }

  ThemeData _darkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryBlue,
      brightness: Brightness.dark,
      primary: primaryBlue,
      secondary: accentBlue,
      surface: darkSurface,
      onSurface: darkPrimaryText,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkBackground,
      primaryColor: primaryBlue,
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: darkPrimaryText,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkInputSurface,
        hintStyle: const TextStyle(
          color: darkSecondaryText,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: const TextStyle(
          color: darkSecondaryText,
          fontWeight: FontWeight.w600,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: primaryBlue,
            width: 1.7,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: darkBorder,
      ),
      iconTheme: const IconThemeData(
        color: darkPrimaryText,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: darkPrimaryText),
        titleMedium: TextStyle(color: darkPrimaryText),
        titleSmall: TextStyle(color: darkPrimaryText),
        bodyLarge: TextStyle(color: darkPrimaryText),
        bodyMedium: TextStyle(color: darkPrimaryText),
        bodySmall: TextStyle(color: darkSecondaryText),
        labelLarge: TextStyle(color: darkPrimaryText),
        labelMedium: TextStyle(color: darkSecondaryText),
        labelSmall: TextStyle(color: darkSecondaryText),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF375C9F),
          disabledForegroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      extensions: const [
        FitzaThemeColors(
          background: darkBackground,
          surface: darkSurface,
          inputSurface: darkInputSurface,
          primaryText: darkPrimaryText,
          secondaryText: darkSecondaryText,
          border: darkBorder,
          primaryBlue: primaryBlue,
          accentBlue: accentBlue,
          successGreen: successGreen,
          disabled: Color(0xFF757575),
          textOnBlue: Colors.white,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: FitzaThemeController.themeMode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Fitza',
          theme: _lightTheme(),
          darkTheme: _darkTheme(),
          themeMode: themeMode,
          home: const AuthGate(),
        );
      },
    );
  }
}

@immutable
class FitzaThemeColors extends ThemeExtension<FitzaThemeColors> {
  final Color background;
  final Color surface;
  final Color inputSurface;
  final Color primaryText;
  final Color secondaryText;
  final Color border;
  final Color primaryBlue;
  final Color accentBlue;
  final Color successGreen;
  final Color disabled;
  final Color textOnBlue;

  const FitzaThemeColors({
    required this.background,
    required this.surface,
    required this.inputSurface,
    required this.primaryText,
    required this.secondaryText,
    required this.border,
    required this.primaryBlue,
    required this.accentBlue,
    required this.successGreen,
    required this.disabled,
    required this.textOnBlue,
  });

  @override
  FitzaThemeColors copyWith({
    Color? background,
    Color? surface,
    Color? inputSurface,
    Color? primaryText,
    Color? secondaryText,
    Color? border,
    Color? primaryBlue,
    Color? accentBlue,
    Color? successGreen,
    Color? disabled,
    Color? textOnBlue,
  }) {
    return FitzaThemeColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      inputSurface: inputSurface ?? this.inputSurface,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      border: border ?? this.border,
      primaryBlue: primaryBlue ?? this.primaryBlue,
      accentBlue: accentBlue ?? this.accentBlue,
      successGreen: successGreen ?? this.successGreen,
      disabled: disabled ?? this.disabled,
      textOnBlue: textOnBlue ?? this.textOnBlue,
    );
  }

  @override
  FitzaThemeColors lerp(
    ThemeExtension<FitzaThemeColors>? other,
    double t,
  ) {
    if (other is! FitzaThemeColors) {
      return this;
    }

    return FitzaThemeColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      inputSurface: Color.lerp(inputSurface, other.inputSurface, t)!,
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      border: Color.lerp(border, other.border, t)!,
      primaryBlue: Color.lerp(primaryBlue, other.primaryBlue, t)!,
      accentBlue: Color.lerp(accentBlue, other.accentBlue, t)!,
      successGreen: Color.lerp(successGreen, other.successGreen, t)!,
      disabled: Color.lerp(disabled, other.disabled, t)!,
      textOnBlue: Color.lerp(textOnBlue, other.textOnBlue, t)!,
    );
  }
}