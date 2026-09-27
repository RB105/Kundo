import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kundo/models/list_background.dart';
import 'package:kundo/models/task.dart';
import 'package:kundo/widgets/list_background_view.dart';

void main() {
  group('ListBackground', () {
    test('encodes and decodes a built-in style', () {
      const ListBackground background =
          ListBackground.builtIn(BackgroundStyle.dunes);

      expect(background.encode(), 'builtin:dunes');
      expect(ListBackground.decode('builtin:dunes'), background);
    });

    test('encodes and decodes a photo', () {
      const ListBackground background = ListBackground.photo('bg_1.jpg');

      expect(background.encode(), 'file:bg_1.jpg');
      expect(ListBackground.decode('file:bg_1.jpg'), background);
      expect(background.isPhoto, isTrue);
    });

    test('no background encodes to null and survives bad data', () {
      expect(const ListBackground.none().encode(), isNull);
      expect(ListBackground.decode(null).isNone, isTrue);
      expect(ListBackground.decode('').isNone, isTrue);
      expect(ListBackground.decode('nonsense').isNone, isTrue);
      // A style written by a newer build must not crash an older one.
      expect(ListBackground.decode('builtin:hologram').isNone, isTrue);
      expect(ListBackground.decode('file:').isNone, isTrue);
    });
  });

  group('TaskList', () {
    test('keeps its background through a JSON round trip', () {
      final TaskList list = TaskList(
        id: 'l1',
        title: 'Work',
        themeIndex: 5,
        createdAt: DateTime(2026, 9, 24),
        background: 'builtin:night',
      );

      expect(TaskList.fromJson(list.toJson()).background, 'builtin:night');
      expect(list.copyWith(clearBackground: true).background, isNull);
      expect(
        TaskList.fromJson(<String, dynamic>{
          'id': 'l2',
          'title': 'Old list',
          'themeIndex': 0,
          'createdAt': DateTime(2026, 1, 1).toIso8601String(),
        }).background,
        isNull,
        reason: 'lists saved before backgrounds existed must still load',
      );
    });
  });

  group('photoAlignmentFor', () {
    test('a portrait phone keeps the top of the picture', () {
      expect(photoAlignmentFor(const Size(393, 852)), Alignment.topCenter);
    });

    test('a wide desktop window centres the picture', () {
      expect(photoAlignmentFor(const Size(1440, 900)), Alignment.center);
      // A phone turned sideways is a wide surface too.
      expect(photoAlignmentFor(const Size(852, 393)), Alignment.center);
    });
  });

  group('decodeWidthFor', () {
    test('decodes at the painted size, rounded up to a step', () {
      // iPhone at 3x: 393pt wide -> 1179px -> next 256 step.
      expect(decodeWidthFor(393, 3), 1280);
      // Same layout width on a 1x screen needs far fewer pixels.
      expect(decodeWidthFor(393, 1), 512);
    });

    test('a small window resize does not change the decode size', () {
      expect(decodeWidthFor(900, 2), decodeWidthFor(980, 2));
    });

    test('is clamped so a huge window cannot ask for an unbounded decode', () {
      expect(decodeWidthFor(6000, 3), 4096);
      expect(decodeWidthFor(10, 1), 256);
    });
  });
}
