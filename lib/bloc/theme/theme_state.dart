import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class ThemeState extends Equatable {
  final bool isDarkMode;

  const ThemeState({this.isDarkMode = false});

  ThemeState copyWith({bool? isDarkMode}) {
    return ThemeState(isDarkMode: isDarkMode ?? this.isDarkMode);
  }

  // Colors for current theme
  Color get primaryColor => const Color(0xFF10b981);
  Color get backgroundColor => isDarkMode ? const Color(0xFF0f172a) : const Color(0xFFFFFFFF);
  Color get surfaceColor => isDarkMode ? const Color(0xFF1e293b) : const Color(0xFFf8f9fa);
  Color get textColor => isDarkMode ? Colors.white : const Color(0xFF1f2937);
  Color get secondaryTextColor => isDarkMode ? const Color(0xFF6ee7b7) : const Color(0xFF6b7280);
  Color get cardColor => isDarkMode ? const Color(0xFF1e293b) : Colors.white;
  Color get borderColor => isDarkMode ? const Color(0xFF10b981) : const Color(0xFFe5e7eb);
  
  LinearGradient get backgroundGradient => isDarkMode
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0f172a),
            Color(0xFF1e293b),
            Color(0xFF065f46),
          ],
        )
      : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFFFF),
            Color(0xFFf8f9fa),
            Color(0xFFe9ecef),
          ],
        );

  @override
  List<Object> get props => [isDarkMode];
}

