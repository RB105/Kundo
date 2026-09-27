import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../cubit/todo_cubit.dart';
import '../models/analytics.dart';
import '../theme.dart';
import '../widgets/ios_ui.dart';

/// Monthly task activity: how much was started, how much was finished, and
/// which list it happened in.
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return NavBarScrollScope(
      child: CupertinoPageScaffold(
        backgroundColor: colors.background,
        child: BlocBuilder<TodoCubit, TodoState>(
          builder: (BuildContext context, TodoState state) {
            final Analytics data = buildAnalytics(
              tasks: state.tasks,
              lists: state.lists,
              month: _month,
            );

            return CustomScrollView(
              slivers: <Widget>[
                CupertinoSliverNavigationBar(
                  largeTitle: const Text('Stats'),
                  previousPageTitle: 'Lists',
                  backgroundColor: colors.bar,
                ),
                SliverSafeArea(
                  top: false,
                  sliver: SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList.list(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Text(
                            DateFormat('MMMM y').format(_month),
                            style: IosText.subheadline.copyWith(
                              color: colors.secondaryLabel,
                            ),
                          ),
                        ),
                        _summaryRow(data.selected, colors),
                        const SizedBox(height: 16),
                        _trendCard(data, colors),
                        const SizedBox(height: 16),
                        _listsCard(data, colors),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _summaryRow(MonthStats stats, AppColors colors) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _statCard(
            'Created',
            '${stats.created}',
            colors.accent,
            colors,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            'Completed',
            '${stats.completed}',
            colors.success,
            colors,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            'Done rate',
            '${(stats.rate * 100).round()}%',
            colors.purple,
            colors,
          ),
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color, AppColors colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(value, style: IosText.title2.copyWith(color: color)),
          const SizedBox(height: 2),
          Text(
            label,
            style: IosText.footnote.copyWith(color: colors.secondaryLabel),
          ),
        ],
      ),
    );
  }

  Widget _trendCard(Analytics data, AppColors colors) {
    final int peak = data.peak;
    final Color created = colors.accent.withValues(alpha: 0.4);

    return _card(
      colors,
      title: 'Last 6 Months',
      subtitle: 'Tap a month to break it down',
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 156,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                for (final MonthStats stats in data.months)
                  _monthColumn(stats, peak, created, colors),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _legendDot(created, 'Created', colors),
              const SizedBox(width: 18),
              _legendDot(colors.success, 'Completed', colors),
            ],
          ),
        ],
      ),
    );
  }

  Widget _monthColumn(
    MonthStats stats,
    int peak,
    Color createdColor,
    AppColors colors,
  ) {
    final bool selected = stats.month == _month;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _month = stats.month),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Text(
              '${stats.created}/${stats.completed}',
              style: IosText.caption2.copyWith(color: colors.secondaryLabel),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                _bar(stats.created / peak, createdColor),
                const SizedBox(width: 4),
                _bar(stats.completed / peak, colors.success),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                // The brand blue, not the lifted dark-mode accent: white text
                // stays readable on it in both appearances.
                color: selected ? kBlue : const Color(0x00000000),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                DateFormat('MMM').format(stats.month),
                style: IosText.caption.copyWith(
                  color: selected
                      ? CupertinoColors.white
                      : colors.secondaryLabel,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bar(double fraction, Color color) {
    return Container(
      width: 12,
      height: (fraction * 96).clamp(3.0, 96.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      ),
    );
  }

  Widget _legendDot(Color color, String label, AppColors colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: IosText.footnote.copyWith(color: colors.secondaryLabel),
        ),
      ],
    );
  }

  Widget _listsCard(Analytics data, AppColors colors) {
    return _card(
      colors,
      title: 'By List',
      subtitle: DateFormat('MMMM y').format(_month),
      child: data.lists.isEmpty
          ? Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'Nothing was created or completed in this month.',
                style: IosText.subheadline.copyWith(
                  color: colors.secondaryLabel,
                ),
              ),
            )
          : Column(
              children: <Widget>[
                for (final ListStats stats in data.lists)
                  _listRow(stats, colors),
              ],
            ),
    );
  }

  Widget _listRow(ListStats stats, AppColors colors) {
    final Color color = tintFor(stats.color, colors.brightness);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(stats.title, style: IosText.body),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: SizedBox(
                    height: 6,
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        ColoredBox(color: colors.fill),
                        FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: stats.rate,
                          child: ColoredBox(color: color),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                '${stats.completed}/${stats.created}',
                style: IosText.headline,
              ),
              const SizedBox(height: 2),
              Text(
                'done',
                style: IosText.caption2.copyWith(color: colors.secondaryLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card(
    AppColors colors, {
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: IosText.headline),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: IosText.footnote.copyWith(color: colors.secondaryLabel),
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
