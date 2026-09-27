import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data/background_store.dart';
import '../models/list_background.dart';
import '../theme.dart';
import 'background_painters.dart';

/// Paints a list's background and keeps the content on top of it readable.
///
/// A phone is tall (about 9:19.5) and a desktop window is wide (about 16:10),
/// so one picture can never fit both by scaling: it is always cropped with
/// [BoxFit.cover] and the crop is anchored where the subject usually sits —
/// the upper part in portrait, the middle in landscape.
class ListBackgroundView extends StatelessWidget {
  const ListBackgroundView({
    super.key,
    required this.background,
    required this.color,
    required this.child,
  });

  final ListBackground background;
  final Color color;
  final Widget child;

  /// Dark mode dims the list color and pictures, so the screen does not glow
  /// next to the rest of the dark interface.
  static const Color _darkDim = Color(0x61000000);

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    if (background.isNone) {
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              for (final Color stop in gradientOf(color))
                dark ? Color.alphaBlend(_darkDim, stop) : stop,
            ],
          ),
        ),
        child: child,
      );
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            // The flat theme color underneath: a photo decodes off the main
            // thread, and the list must not flash white while it does.
            ColoredBox(color: color),
            if (background.style != null)
              CustomPaint(
                painter: backgroundPainterFor(background.style!, color),
              ),
            if (background.isPhoto)
              Image.file(
                File(BackgroundStore.instance.pathOf(background.fileName!)),
                fit: BoxFit.cover,
                alignment: photoAlignmentFor(constraints.biggest),
                // Decode at the size actually painted. Without this a 12MP
                // photo would be held in memory at full resolution on a phone.
                cacheWidth: decodeWidthFor(
                  constraints.maxWidth,
                  MediaQuery.devicePixelRatioOf(context),
                ),
                filterQuality: FilterQuality.medium,
                gaplessPlayback: true,
                // The file can disappear (storage cleared, restored backup):
                // fall back to the plain color rather than an error box.
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            // Scrim: the white title and the task cards have to stay legible
            // over a photo that may be bright, dark or busy.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: background.isPhoto
                      ? const <Color>[
                          Color(0x8A000000),
                          Color(0x30000000),
                          Color(0x73000000),
                        ]
                      : const <Color>[
                          Color(0x30000000),
                          Color(0x12000000),
                          Color(0x3D000000),
                        ],
                  stops: const <double>[0, 0.45, 1],
                ),
              ),
            ),
            if (dark) const ColoredBox(color: _darkDim),
            child,
          ],
        );
      },
    );
  }
}

/// Where to anchor the crop of a photo.
///
/// A portrait phone shows a tall slice of a wide photo: anchoring at the top
/// keeps faces, skylines and horizons — which sit above the middle in most
/// pictures — inside the frame. A wide window already shows almost the whole
/// picture, so it is centred.
Alignment photoAlignmentFor(Size size) =>
    size.width > size.height ? Alignment.center : Alignment.topCenter;

/// Pixel width to decode an image at, rounded up to a step so that dragging a
/// desktop window does not trigger a fresh decode on every frame.
int decodeWidthFor(double logicalWidth, double devicePixelRatio) {
  const int step = 256;
  final int pixels = (logicalWidth * devicePixelRatio).ceil();
  final int stepped = (pixels / step).ceil() * step;
  return stepped.clamp(step, 4096).toInt();
}

/// Small preview of a background, used by the theme sheet.
class BackgroundThumb extends StatelessWidget {
  const BackgroundThumb({
    super.key,
    required this.background,
    required this.color,
    this.selected = false,
    this.label,
    this.onTap,
  });

  final ListBackground background;
  final Color color;
  final bool selected;
  final String? label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 58,
            height: 78,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? colors.label : colors.separator,
                width: selected ? 2 : 0.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  ColoredBox(color: color),
                  if (background.style != null)
                    CustomPaint(
                      painter: backgroundPainterFor(background.style!, color),
                    ),
                  if (background.isPhoto)
                    Image.file(
                      File(BackgroundStore.instance
                          .pathOf(background.fileName!)),
                      fit: BoxFit.cover,
                      cacheWidth: 180,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  if (selected)
                    const Center(
                      child: Icon(CupertinoIcons.checkmark_alt,
                          color: CupertinoColors.white, size: 24),
                    ),
                ],
              ),
            ),
          ),
          if (label != null) ...<Widget>[
            const SizedBox(height: 5),
            SizedBox(
              width: 62,
              child: Text(
                label!,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: IosText.caption2.copyWith(color: colors.secondaryLabel),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
