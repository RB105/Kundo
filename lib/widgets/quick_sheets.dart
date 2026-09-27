import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import '../data/background_store.dart';
import '../models/list_background.dart';
import '../models/task.dart';
import '../theme.dart';
import 'ios_ui.dart';
import 'list_background_view.dart';

/// The quick pickers To Do shows instead of dropping straight into a calendar.

/// Result of a quick-pick action sheet: a ready value, or null for "Pick…".
class _Quick<T> {
  const _Quick(this.value);

  final T? value;
}

Future<DateTime?> showDueDateSheet(BuildContext context) async {
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime tomorrow = today.add(const Duration(days: 1));
  final DateTime nextWeek = today.add(const Duration(days: 7));
  final DateFormat weekday = DateFormat('EEE');

  final _Quick<DateTime>? choice = await showActionSheet<_Quick<DateTime>>(
    context,
    title: 'Due Date',
    actions: <SheetAction<_Quick<DateTime>>>[
      SheetAction<_Quick<DateTime>>(
        'Today',
        _Quick<DateTime>(today),
        detail: weekday.format(today),
      ),
      SheetAction<_Quick<DateTime>>(
        'Tomorrow',
        _Quick<DateTime>(tomorrow),
        detail: weekday.format(tomorrow),
      ),
      SheetAction<_Quick<DateTime>>(
        'Next Week',
        _Quick<DateTime>(nextWeek),
        detail: weekday.format(nextWeek),
      ),
      const SheetAction<_Quick<DateTime>>(
        'Pick a Date…',
        _Quick<DateTime>(null),
      ),
    ],
  );

  if (choice == null) return null;
  if (choice.value != null) return choice.value;

  if (!context.mounted) return null;
  final DateTime? picked = await showDatePickerSheet(
    context,
    title: 'Due Date',
    mode: CupertinoDatePickerMode.date,
    initial: today,
    minimum: DateTime(now.year - 1),
    maximum: DateTime(now.year + 5, 12, 31),
  );
  return picked == null
      ? null
      : DateTime(picked.year, picked.month, picked.day);
}

Future<DateTime?> showReminderSheet(BuildContext context) async {
  final DateTime now = DateTime.now();
  final DateTime laterToday = DateTime(
    now.year,
    now.month,
    now.day,
    now.hour + 3,
  );
  final DateTime tomorrow = DateTime(now.year, now.month, now.day + 1, 9);
  final DateTime nextWeek = DateTime(now.year, now.month, now.day + 7, 9);

  final _Quick<DateTime>? choice = await showActionSheet<_Quick<DateTime>>(
    context,
    title: 'Remind Me',
    actions: <SheetAction<_Quick<DateTime>>>[
      SheetAction<_Quick<DateTime>>(
        'Later Today',
        _Quick<DateTime>(laterToday),
        detail: DateFormat('h:mm a').format(laterToday),
      ),
      SheetAction<_Quick<DateTime>>(
        'Tomorrow',
        _Quick<DateTime>(tomorrow),
        detail: DateFormat('EEE, h:mm a').format(tomorrow),
      ),
      SheetAction<_Quick<DateTime>>(
        'Next Week',
        _Quick<DateTime>(nextWeek),
        detail: DateFormat('EEE, h:mm a').format(nextWeek),
      ),
      const SheetAction<_Quick<DateTime>>(
        'Pick a Date & Time…',
        _Quick<DateTime>(null),
      ),
    ],
  );

  if (choice == null) return null;
  if (choice.value != null) return choice.value;

  if (!context.mounted) return null;
  // The wheel starts on the next whole hour, like the Reminders app.
  final DateTime start = DateTime(now.year, now.month, now.day, now.hour + 1);
  return showDatePickerSheet(
    context,
    title: 'Remind Me',
    mode: CupertinoDatePickerMode.dateAndTime,
    initial: start,
    minimum: DateTime(now.year - 1),
    maximum: DateTime(now.year + 5, 12, 31),
  );
}

Future<RepeatRule?> showRepeatSheet(BuildContext context) {
  return showActionSheet<RepeatRule>(
    context,
    title: 'Repeat',
    actions: <SheetAction<RepeatRule>>[
      for (final RepeatRule rule in RepeatRule.values)
        if (rule != RepeatRule.none) SheetAction<RepeatRule>(rule.label, rule),
    ],
  );
}

/// What the user picked in the theme sheet. A null field means "unchanged".
class ThemeChoice {
  const ThemeChoice({this.themeIndex, this.background});

  final int? themeIndex;
  final ListBackground? background;
}

/// Color and background picker for a list.
Future<ThemeChoice?> showThemeSheet(
  BuildContext context, {
  required int selectedTheme,
  required ListBackground selectedBackground,
}) {
  return showCupertinoModalPopup<ThemeChoice>(
    context: context,
    builder: (BuildContext context) => _ThemeSheet(
      selectedTheme: selectedTheme,
      selectedBackground: selectedBackground,
    ),
  );
}

class _ThemeSheet extends StatelessWidget {
  const _ThemeSheet({
    required this.selectedTheme,
    required this.selectedBackground,
  });

  final int selectedTheme;
  final ListBackground selectedBackground;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final Color color = kListThemes[selectedTheme % kListThemes.length];

    return IosSheet(
      title: 'Change Theme',
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _header('Color', colors),
            _card(
              colors,
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: <Widget>[
                  for (int i = 0; i < kListThemes.length; i++)
                    _ColorDot(
                      color: kListThemes[i],
                      selected: i == selectedTheme,
                      ringColor: colors.label,
                      onTap: () =>
                          Navigator.pop(context, ThemeChoice(themeIndex: i)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _header('Background', colors),
            _card(
              colors,
              padding: EdgeInsets.zero,
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    BackgroundThumb(
                      background: const ListBackground.none(),
                      color: color,
                      selected: selectedBackground.isNone,
                      label: 'None',
                      onTap: () => Navigator.pop(
                        context,
                        const ThemeChoice(background: ListBackground.none()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    for (final BackgroundStyle style
                        in BackgroundStyle.values) ...<Widget>[
                      BackgroundThumb(
                        background: ListBackground.builtIn(style),
                        color: color,
                        selected: selectedBackground.style == style,
                        label: style.label,
                        onTap: () => Navigator.pop(
                          context,
                          ThemeChoice(
                            background: ListBackground.builtIn(style),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    _PhotoThumb(selected: selectedBackground.isPhoto),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'Built-in backgrounds are painted from the list color. A photo '
                'is copied into the app, so it keeps working offline.',
                style: IosText.footnote.copyWith(color: colors.secondaryLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _header(String text, AppColors colors) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 7),
    child: Text(
      text.toUpperCase(),
      style: IosText.footnote.copyWith(color: colors.secondaryLabel),
    ),
  );

  static Widget _card(
    AppColors colors,
    Widget child, {
    EdgeInsets padding = const EdgeInsets.all(16),
  }) => Container(
    width: double.infinity,
    padding: padding,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: colors.card,
      borderRadius: BorderRadius.circular(10),
    ),
    child: child,
  );
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.ringColor,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final Color ringColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      // The ring sits outside the dot with a gap, like the iOS color well.
      child: Container(
        width: 44,
        height: 44,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? ringColor : const Color(0x00000000),
            width: 2,
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: selected
              ? const Icon(
                  CupertinoIcons.checkmark_alt,
                  color: CupertinoColors.white,
                  size: 20,
                )
              : null,
        ),
      ),
    );
  }
}

/// Picks a picture from the gallery (mobile) or a file dialog (desktop) and
/// copies it into the app before handing the list its new background.
class _PhotoThumb extends StatefulWidget {
  const _PhotoThumb({required this.selected});

  final bool selected;

  @override
  State<_PhotoThumb> createState() => _PhotoThumbState();
}

class _PhotoThumbState extends State<_PhotoThumb> {
  bool _busy = false;

  Future<void> _pick() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final String? path = await pickBackgroundImage();
      if (path == null) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      final String fileName = await BackgroundStore.instance.import(path);
      if (!mounted) return;
      Navigator.pop(
        context,
        ThemeChoice(background: ListBackground.photo(fileName)),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      await showInfoDialog(
        context,
        title: 'Could Not Use That Image',
        message: '$error',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return GestureDetector(
      onTap: _pick,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 58,
            height: 78,
            decoration: BoxDecoration(
              color: colors.fill,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.selected ? colors.label : colors.separator,
                width: widget.selected ? 2 : 0.5,
              ),
            ),
            child: Center(
              child: _busy
                  ? const CupertinoActivityIndicator()
                  : Icon(
                      CupertinoIcons.photo_on_rectangle,
                      color: colors.secondaryLabel,
                    ),
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            width: 62,
            child: Text(
              'Photo',
              textAlign: TextAlign.center,
              style: IosText.caption2.copyWith(color: colors.secondaryLabel),
            ),
          ),
        ],
      ),
    );
  }
}
