// lib/theme_manager.dart
import 'package:flutter/material.dart';

/// Global theme notifier you can change from any screen:
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);
