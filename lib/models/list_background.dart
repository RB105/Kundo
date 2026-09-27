import 'package:flutter/foundation.dart';

/// Built-in backgrounds. They are painted from the list's own theme color, so
/// they cost no asset bytes and fit any screen shape exactly.
enum BackgroundStyle { aurora, dunes, peaks, night, bokeh }

extension BackgroundStyleLabel on BackgroundStyle {
  String get label => switch (this) {
        BackgroundStyle.aurora => 'Aurora',
        BackgroundStyle.dunes => 'Dunes',
        BackgroundStyle.peaks => 'Peaks',
        BackgroundStyle.night => 'Night',
        BackgroundStyle.bokeh => 'Bokeh',
      };
}

/// What a list paints behind its tasks: nothing, a built-in style, or a photo
/// the user picked (stored inside the app, referenced by file name).
@immutable
class ListBackground {
  const ListBackground.none()
      : style = null,
        fileName = null;

  const ListBackground.builtIn(BackgroundStyle this.style) : fileName = null;

  const ListBackground.photo(String this.fileName) : style = null;

  final BackgroundStyle? style;
  final String? fileName;

  bool get isNone => style == null && fileName == null;

  bool get isPhoto => fileName != null;

  /// `null` means "no background" and is what gets stored for a plain list.
  String? encode() {
    if (style != null) return 'builtin:${style!.name}';
    if (fileName != null) return 'file:$fileName';
    return null;
  }

  static ListBackground decode(String? raw) {
    if (raw == null || raw.isEmpty) return const ListBackground.none();
    if (raw.startsWith('builtin:')) {
      final String name = raw.substring('builtin:'.length);
      for (final BackgroundStyle style in BackgroundStyle.values) {
        if (style.name == name) return ListBackground.builtIn(style);
      }
      // An unknown style means data from a newer build — fall back to plain.
      return const ListBackground.none();
    }
    if (raw.startsWith('file:')) {
      final String name = raw.substring('file:'.length);
      return name.isEmpty
          ? const ListBackground.none()
          : ListBackground.photo(name);
    }
    return const ListBackground.none();
  }

  @override
  bool operator ==(Object other) =>
      other is ListBackground &&
      other.style == style &&
      other.fileName == fileName;

  @override
  int get hashCode => Object.hash(style, fileName);
}
