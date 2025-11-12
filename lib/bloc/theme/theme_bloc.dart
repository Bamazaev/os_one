import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_event.dart';
import 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(const ThemeState()) {
    on<ThemeToggled>(_onThemeToggled);
    on<ThemeChanged>(_onThemeChanged);
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDarkMode = prefs.getBool('isDarkMode') ?? false;
      add(ThemeChanged(isDarkMode));
    } catch (e) {
      print('Error loading theme: $e');
    }
  }

  Future<void> _onThemeToggled(ThemeToggled event, Emitter<ThemeState> emit) async {
    final newMode = !state.isDarkMode;
    emit(state.copyWith(isDarkMode: newMode));
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', newMode);
    } catch (e) {
      print('Error saving theme: $e');
    }
  }

  void _onThemeChanged(ThemeChanged event, Emitter<ThemeState> emit) {
    emit(state.copyWith(isDarkMode: event.isDarkMode));
  }
}

