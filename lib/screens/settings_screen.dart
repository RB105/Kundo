import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/appearance_cubit.dart';
import '../theme.dart';
import '../widgets/ios_ui.dart';

/// Account summary and the appearance switch (Automatic / Light / Dark).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static String _label(ThemeMode mode) => switch (mode) {
    ThemeMode.system => 'Automatic',
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
  };

  static IconData _icon(ThemeMode mode) => switch (mode) {
    ThemeMode.system => CupertinoIcons.circle_lefthalf_fill,
    ThemeMode.light => CupertinoIcons.sun_max_fill,
    ThemeMode.dark => CupertinoIcons.moon_fill,
  };

  static Color _badgeColor(ThemeMode mode) => switch (mode) {
    ThemeMode.system => const Color(0xFF8E8E93),
    ThemeMode.light => const Color(0xFFFF9500),
    ThemeMode.dark => const Color(0xFF5856D6),
  };

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return NavBarScrollScope(
      child: CupertinoPageScaffold(
        backgroundColor: colors.background,
        child: CustomScrollView(
          slivers: <Widget>[
            CupertinoSliverNavigationBar(
              largeTitle: const Text('Settings'),
              previousPageTitle: 'Lists',
              backgroundColor: colors.bar,
            ),
            SliverSafeArea(
              top: false,
              sliver: SliverToBoxAdapter(
                child: Column(
                  children: <Widget>[
                    CupertinoListSection.insetGrouped(
                      backgroundColor: colors.background,
                      children: <Widget>[
                        // The account row, roomier than the rest like the
                        // Apple Account row in iOS Settings.
                        CupertinoListTile(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            16,
                            14,
                            14,
                            14,
                          ),
                          leadingSize: 56,
                          leadingToTitle: 14,
                          leading: Container(
                            decoration: const BoxDecoration(
                              color: kBlue,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              CupertinoIcons.person_fill,
                              color: CupertinoColors.white,
                              size: 30,
                            ),
                          ),
                          title: const Text('Kundo', style: IosText.title3),
                          subtitle: Text(
                            'Stored on this device only',
                            style: IosText.subheadline.copyWith(
                              color: colors.secondaryLabel,
                            ),
                          ),
                        ),
                      ],
                    ),
                    BlocBuilder<AppearanceCubit, ThemeMode>(
                      builder: (BuildContext context, ThemeMode current) {
                        final AppearanceCubit cubit = context
                            .read<AppearanceCubit>();
                        return CupertinoListSection.insetGrouped(
                          backgroundColor: colors.background,
                          header: const Text('Appearance'),
                          // Inset sections leave the footer unstyled.
                          footer: Text(
                            'Automatic follows the light or dark setting of '
                            'your device.',
                            style: IosText.footnote.copyWith(
                              color: colors.secondaryLabel,
                            ),
                          ),
                          children: <Widget>[
                            for (final ThemeMode mode in ThemeMode.values)
                              CupertinoListTile(
                                padding: kRowPadding,
                                leading: IconBadge(
                                  _icon(mode),
                                  color: _badgeColor(mode),
                                  size: 28,
                                ),
                                title: Text(_label(mode)),
                                trailing: mode == current
                                    ? Icon(
                                        CupertinoIcons.checkmark_alt,
                                        color: colors.accent,
                                      )
                                    : null,
                                onTap: () => cubit.setMode(mode),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
