import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Events
abstract class ThemeEvent {}

class ToggleThemeEvent extends ThemeEvent {}

class InitThemeEvent extends ThemeEvent {}

// States
class ThemeState {
  final ThemeMode themeMode;
  
  ThemeState(this.themeMode);
}

// Bloc
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  static const String themeKey = 'theme_mode';
  
  ThemeBloc() : super(ThemeState(ThemeMode.light)) {
    on<ToggleThemeEvent>(_onToggleTheme);
    on<InitThemeEvent>(_onInitTheme);
  }

  Future<void> _onToggleTheme(ToggleThemeEvent event, Emitter<ThemeState> emit) async {
    final newThemeMode = state.themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    emit(ThemeState(newThemeMode));
    
    // Save to preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(themeKey, newThemeMode.toString());
  }

  Future<void> _onInitTheme(InitThemeEvent event, Emitter<ThemeState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(themeKey);
    
    if (savedTheme != null) {
      if (savedTheme.contains('dark')) {
        emit(ThemeState(ThemeMode.dark));
      } else {
        emit(ThemeState(ThemeMode.light));
      }
    }
  }
}
