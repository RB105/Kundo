import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/todo_repository.dart';

/// Light, dark, or following the system ("Automatic" in Settings).
class AppearanceCubit extends Cubit<ThemeMode> {
  AppearanceCubit(this._repository) : super(_repository.loadThemeMode());

  final TodoRepository _repository;

  void setMode(ThemeMode mode) {
    if (mode == state) return;
    _repository.saveThemeMode(mode);
    emit(mode);
  }
}
