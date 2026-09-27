import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';
import '../theme.dart';
import 'ios_ui.dart';

/// Human date the way To Do writes it under a task title.
String formatTaskDate(DateTime date) {
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime day = DateTime(date.year, date.month, date.day);
  final int diff = day.difference(today).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Tomorrow';
  if (diff == -1) return 'Yesterday';
  if (date.year == now.year) return DateFormat('EEE, MMM d').format(date);
  return DateFormat('EEE, MMM d, y').format(date);
}

bool isOverdue(DateTime due) {
  final DateTime now = DateTime.now();
  return DateTime(due.year, due.month, due.day)
      .isBefore(DateTime(now.year, now.month, now.day));
}

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.accent,
    required this.onToggle,
    required this.onStar,
    required this.onTap,
    this.onDelete,
    this.listLabel,
    this.showMyDayBadge = false,
  });

  final Task task;

  /// The list's color; lifted for dark mode before it is drawn on a card.
  final Color accent;
  final VoidCallback onToggle;
  final VoidCallback onStar;
  final VoidCallback onTap;

  /// Enables swipe-to-delete (after a confirmation) when set.
  final VoidCallback? onDelete;

  /// Name of the owning list — smart lists show it, a list shows nothing.
  final String? listLabel;
  final bool showMyDayBadge;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final Color tint = tintFor(accent, colors.brightness);
    final TextStyle metaStyle =
        IosText.footnote.copyWith(color: colors.secondaryLabel);
    final List<InlineSpan> meta = <InlineSpan>[];

    if (listLabel != null && listLabel!.isNotEmpty) {
      meta.add(TextSpan(text: listLabel));
    }
    if (showMyDayBadge && task.isInMyDay) {
      meta.add(_iconText(CupertinoIcons.sun_max, 'My Day', metaStyle));
    }
    if (task.steps.isNotEmpty) {
      meta.add(TextSpan(text: '${task.doneSteps} of ${task.steps.length}'));
    }
    if (task.dueDate != null) {
      final bool late = isOverdue(task.dueDate!) && !task.isCompleted;
      meta.add(_iconText(
        CupertinoIcons.calendar,
        formatTaskDate(task.dueDate!),
        late ? metaStyle.copyWith(color: colors.danger) : metaStyle,
      ));
    }
    if (task.reminder != null) {
      meta.add(_icon(CupertinoIcons.bell, metaStyle));
    }
    if (task.repeat != RepeatRule.none) {
      meta.add(_icon(CupertinoIcons.repeat, metaStyle));
    }
    if (task.hasNote) {
      meta.add(_icon(CupertinoIcons.doc_text, metaStyle));
    }

    const BorderRadius radius = BorderRadius.all(Radius.circular(10));

    Widget tile = Pressable(
      color: colors.card,
      borderRadius: radius,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 2, 8),
        child: Row(
          children: <Widget>[
            CheckCircle(
              checked: task.isCompleted,
              color: tint,
              borderColor: colors.tertiaryLabel,
              onTap: onToggle,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    task.title,
                    style: IosText.body.copyWith(
                      height: 1.25,
                      color: task.isCompleted
                          ? colors.secondaryLabel
                          : colors.label,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (meta.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 3),
                    Text.rich(
                      TextSpan(style: metaStyle, children: _joined(meta)),
                    ),
                  ],
                ],
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(44, 44),
              onPressed: onStar,
              child: Icon(
                task.isImportant ? CupertinoIcons.star_fill : CupertinoIcons.star,
                size: 22,
                color: task.isImportant ? tint : colors.secondaryLabel,
              ),
            ),
          ],
        ),
      ),
    );

    if (onDelete != null) {
      tile = Dismissible(
        key: ValueKey<String>('task-${task.id}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (_) => showConfirmDialog(
          context,
          title: 'Delete "${task.title}"?',
          message: 'This task will be permanently deleted.',
          confirmLabel: 'Delete',
        ),
        onDismissed: (_) => onDelete!(),
        background: Container(
          decoration: BoxDecoration(color: colors.danger, borderRadius: radius),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 22),
          child: const Icon(CupertinoIcons.trash, color: CupertinoColors.white),
        ),
        child: tile,
      );
    }

    return Padding(padding: const EdgeInsets.only(bottom: 6), child: tile);
  }

  /// Joins the meta items with dots. The no-break space keeps each dot on
  /// the line of the item before it when the row wraps.
  static List<InlineSpan> _joined(List<InlineSpan> items) => <InlineSpan>[
        for (int i = 0; i < items.length; i++) ...<InlineSpan>[
          if (i > 0) const TextSpan(text: '\u00A0· '),
          items[i],
        ],
      ];

  static InlineSpan _icon(IconData icon, TextStyle style) => WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Icon(icon, size: 13, color: style.color),
      );

  /// Icon and label as one unit, so a wrap never separates them.
  static InlineSpan _iconText(IconData icon, String text, TextStyle style) =>
      WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 13, color: style.color),
            const SizedBox(width: 3),
            Text(text, style: style),
          ],
        ),
      );
}

/// The round completion toggle used by tasks and steps.
class CheckCircle extends StatelessWidget {
  const CheckCircle({
    super.key,
    required this.checked,
    required this.color,
    required this.borderColor,
    required this.onTap,
    this.size = 24,
  });

  final bool checked;
  final Color color;
  final Color borderColor;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    // Light list colors (lifted for dark mode) need a dark check mark.
    final Color mark = color.computeLuminance() > 0.5
        ? CupertinoColors.black
        : CupertinoColors.white;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      // A comfortable touch target around the small circle.
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: checked ? color : const Color(0x00000000),
            border: Border.all(
              color: checked ? color : borderColor,
              width: 1.5,
            ),
          ),
          child: checked
              ? Icon(CupertinoIcons.checkmark_alt, size: size * 0.7, color: mark)
              : null,
        ),
      ),
    );
  }
}
