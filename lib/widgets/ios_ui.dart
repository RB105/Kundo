import 'package:flutter/cupertino.dart';

import '../theme.dart';

/// The iOS building blocks every screen shares: icon badges, pressable rows,
/// modal sheets, action sheets, alerts and the date picker.

/// Padding of list rows: taller than the 44pt minimum, as rows are in iOS
/// Settings, so icons and text do not sit tight against their card.
const EdgeInsetsDirectional kRowPadding =
    EdgeInsetsDirectional.fromSTEB(20, 12, 14, 12);

/// White glyph on a colored rounded square, the way iOS Settings draws the
/// icon of a row.
class IconBadge extends StatelessWidget {
  const IconBadge(this.icon, {super.key, required this.color, this.size = 30});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.24),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: CupertinoColors.white, size: size * 0.6),
    );
  }
}

/// A surface that darkens while a finger rests on it, like a pressed table
/// cell. iOS rows highlight; they do not ripple.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.color,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius = BorderRadius.zero,
  });

  final Color color;
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius borderRadius;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final Color overlay = AppColors.of(context).pressedOverlay;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _pressed ? Color.alphaBlend(overlay, widget.color) : widget.color,
          borderRadius: widget.borderRadius,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Wraps a page whose scroll view carries a [CupertinoSliverNavigationBar],
/// working around a Flutter bug in that bar (seen on Flutter 3.44).
///
/// When scrolling stops with the large title half collapsed, the bar snaps it
/// open or shut with `position.animateTo`, from a listener on
/// `isScrollingNotifier`. That listener also fires inside
/// `ScrollPosition.hold()` when a finger lands on the list mid-snap, so the
/// snap replaces the hold before [Scrollable] has stored it. If the back swipe
/// then wins the gesture, Scrollable cancels its dead hold and fails the
/// `'_hold == null'` assertion. A finger on the list stops it anyway, so the
/// snap is skipped while the list is held.
class NavBarScrollScope extends StatefulWidget {
  const NavBarScrollScope({super.key, required this.child});

  /// The page. Its scroll view picks the controller up as the primary one,
  /// which also keeps the status-bar tap scrolling it to the top.
  final Widget child;

  @override
  State<NavBarScrollScope> createState() => _NavBarScrollScopeState();
}

class _NavBarScrollScopeState extends State<NavBarScrollScope> {
  final ScrollController _controller = _HoldAwareScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PrimaryScrollController(
      controller: _controller,
      automaticallyInheritForPlatforms: TargetPlatform.values.toSet(),
      child: widget.child,
    );
  }
}

class _HoldAwareScrollController extends ScrollController {
  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return _HoldAwareScrollPosition(
      physics: physics,
      context: context,
      initialPixels: initialScrollOffset,
      keepScrollOffset: keepScrollOffset,
      oldPosition: oldPosition,
      debugLabel: debugLabel,
    );
  }
}

class _HoldAwareScrollPosition extends ScrollPositionWithSingleContext {
  _HoldAwareScrollPosition({
    required super.physics,
    required super.context,
    super.initialPixels,
    super.keepScrollOffset,
    super.oldPosition,
    super.debugLabel,
  });

  @override
  Future<void> animateTo(
    double to, {
    required Duration duration,
    required Curve curve,
  }) {
    if (activity is HoldScrollActivity) return Future<void>.value();
    return super.animateTo(to, duration: duration, curve: curve);
  }
}

/// A text button for bars and sheet headers.
class BarButton extends StatelessWidget {
  const BarButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.bold = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      minimumSize: const Size(44, 44),
      onPressed: onPressed,
      child: Text(label, style: bold ? IosText.headline : IosText.body),
    );
  }
}

/// Body of a modal popup: rounded top corners and a header bar with a
/// centered title, [leading] on the left and a "Done" button (or [trailing])
/// on the right.
class IosSheet extends StatelessWidget {
  const IosSheet({
    super.key,
    required this.title,
    required this.child,
    this.leading,
    this.trailing,
    this.color,
  });

  final String title;
  final Widget child;
  final Widget? leading;
  final Widget? trailing;

  /// Defaults to the grouped background, so inset cards stand out on it.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration: BoxDecoration(
        color: color ?? colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              height: 52,
              child: NavigationToolbar(
                leading: leading,
                middle: Text(title, style: IosText.headline),
                trailing: trailing ??
                    BarButton(
                      'Done',
                      bold: true,
                      onPressed: () => Navigator.pop(context),
                    ),
              ),
            ),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}

/// One button of an action sheet. [detail] is shown after the label in the
/// secondary color, e.g. "Tomorrow  Sat".
class SheetAction<T> {
  const SheetAction(
    this.label,
    this.value, {
    this.detail,
    this.isDestructive = false,
  });

  final String label;
  final T value;
  final String? detail;
  final bool isDestructive;
}

/// iOS action sheet with a Cancel button. Returns the value of the tapped
/// action, or null when cancelled.
Future<T?> showActionSheet<T>(
  BuildContext context, {
  String? title,
  String? message,
  required List<SheetAction<T>> actions,
}) {
  return showCupertinoModalPopup<T>(
    context: context,
    builder: (BuildContext context) {
      final Color detailColor = AppColors.of(context).secondaryLabel;
      return CupertinoActionSheet(
        title: title == null ? null : Text(title),
        message: message == null ? null : Text(message),
        actions: <Widget>[
          for (final SheetAction<T> action in actions)
            CupertinoActionSheetAction(
              isDestructiveAction: action.isDestructive,
              onPressed: () => Navigator.pop(context, action.value),
              child: Text.rich(
                TextSpan(
                  text: action.label,
                  children: <InlineSpan>[
                    if (action.detail != null)
                      TextSpan(
                        text: '  ${action.detail}',
                        style: TextStyle(color: detailColor),
                      ),
                  ],
                ),
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      );
    },
  );
}

/// Alert asking to confirm a (by default destructive) action.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  String? message,
  required String confirmLabel,
  bool destructive = true,
}) async {
  final bool? ok = await showCupertinoDialog<bool>(
    context: context,
    builder: (BuildContext context) => CupertinoAlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: <Widget>[
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        CupertinoDialogAction(
          isDestructiveAction: destructive,
          isDefaultAction: !destructive,
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Alert with a single OK button.
Future<void> showInfoDialog(
  BuildContext context, {
  required String title,
  String? message,
}) {
  return showCupertinoDialog<void>(
    context: context,
    builder: (BuildContext context) => CupertinoAlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: <Widget>[
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

/// Alert with a text field, the iOS way of naming something. Returns the
/// trimmed text, or null when cancelled.
Future<String?> showTextPrompt(
  BuildContext context, {
  required String title,
  String? message,
  String initial = '',
  String placeholder = '',
  required String confirmLabel,
}) {
  return showCupertinoDialog<String>(
    context: context,
    builder: (BuildContext context) => _TextPromptDialog(
      title: title,
      message: message,
      initial: initial,
      placeholder: placeholder,
      confirmLabel: confirmLabel,
    ),
  );
}

class _TextPromptDialog extends StatefulWidget {
  const _TextPromptDialog({
    required this.title,
    required this.message,
    required this.initial,
    required this.placeholder,
    required this.confirmLabel,
  });

  final String title;
  final String? message;
  final String initial;
  final String placeholder;
  final String confirmLabel;

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final String text = _controller.text.trim();
    if (text.isEmpty) return;
    Navigator.pop(context, text);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (widget.message != null) Text(widget.message!),
          const SizedBox(height: 12),
          CupertinoTextField(
            controller: _controller,
            autofocus: true,
            placeholder: widget.placeholder,
            textCapitalization: TextCapitalization.sentences,
            clearButtonMode: OverlayVisibilityMode.editing,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _confirm(),
          ),
        ],
      ),
      actions: <Widget>[
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: _controller.text.trim().isEmpty ? null : _confirm,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

/// Wheel date (or date and time) picker in a sheet with Cancel and Done.
Future<DateTime?> showDatePickerSheet(
  BuildContext context, {
  required String title,
  required CupertinoDatePickerMode mode,
  required DateTime initial,
  DateTime? minimum,
  DateTime? maximum,
}) {
  DateTime selected = initial;
  return showCupertinoModalPopup<DateTime>(
    context: context,
    builder: (BuildContext context) => IosSheet(
      title: title,
      color: AppColors.of(context).card,
      leading: BarButton('Cancel', onPressed: () => Navigator.pop(context)),
      trailing: BarButton(
        'Done',
        bold: true,
        onPressed: () => Navigator.pop(context, selected),
      ),
      child: SizedBox(
        height: 216,
        child: CupertinoDatePicker(
          mode: mode,
          initialDateTime: initial,
          minimumDate: minimum,
          maximumDate: maximum,
          use24hFormat: MediaQuery.alwaysUse24HourFormatOf(context),
          onDateTimeChanged: (DateTime value) => selected = value,
        ),
      ),
    ),
  );
}
