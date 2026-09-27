import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/todo_cubit.dart';
import '../models/task.dart';
import '../models/todo_view.dart';
import '../theme.dart';
import '../widgets/ios_ui.dart';
import '../widgets/list_actions.dart';
import '../widgets/task_tile.dart';
import 'analytics_screen.dart';
import 'list_screen.dart';
import 'settings_screen.dart';
import 'task_detail_screen.dart';

enum _ListAction { rename, theme, delete }

/// The To Do home: smart lists on top, the user's own lists below.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _search = TextEditingController();
  bool _searching = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _push(Widget page) {
    Navigator.of(context).push(CupertinoPageRoute<void>(builder: (_) => page));
  }

  void _open(TodoView view) => _push(ListScreen(view: view));

  Future<void> _createList() async {
    final TodoCubit cubit = context.read<TodoCubit>();
    final String? name = await showTextPrompt(
      context,
      title: 'New List',
      placeholder: 'List name',
      confirmLabel: 'Create',
    );
    if (name == null) return;
    final TaskList list = cubit.addList(name);
    if (!mounted) return;
    _open(TodoView.list(list));
  }

  Future<void> _listOptions(TaskList list) async {
    final _ListAction? action = await showActionSheet<_ListAction>(
      context,
      title: list.title,
      actions: const <SheetAction<_ListAction>>[
        SheetAction<_ListAction>('Rename List', _ListAction.rename),
        SheetAction<_ListAction>('Change Theme', _ListAction.theme),
        SheetAction<_ListAction>(
          'Delete List',
          _ListAction.delete,
          isDestructive: true,
        ),
      ],
    );
    if (!mounted || action == null) return;

    switch (action) {
      case _ListAction.rename:
        await renameList(context, list);
      case _ListAction.theme:
        await changeListTheme(context, list);
      case _ListAction.delete:
        await confirmAndDeleteList(context, list);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);

    return NavBarScrollScope(
      child: CupertinoPageScaffold(
        backgroundColor: colors.background,
        child: BlocBuilder<TodoCubit, TodoState>(
          builder: (BuildContext context, TodoState state) {
            final TodoCubit cubit = context.read<TodoCubit>();
            return Column(
              children: <Widget>[
                Expanded(
                  child: CustomScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    slivers: <Widget>[
                      CupertinoSliverNavigationBar.search(
                        largeTitle: const Text('Lists'),
                        leading: _avatar(),
                        trailing: CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(44, 44),
                          onPressed: () => _push(const AnalyticsScreen()),
                          child: const Icon(CupertinoIcons.chart_bar),
                        ),
                        backgroundColor: colors.bar,
                        searchField: CupertinoSearchTextField(
                          controller: _search,
                          autofocus: _searching,
                          placeholder: 'Search tasks',
                          onChanged: (_) => setState(() {}),
                        ),
                        onSearchableBottomTap: (bool active) => setState(() {
                          _searching = active;
                          if (!active) _search.clear();
                        }),
                      ),
                      if (_searching)
                        ..._searchResults(cubit, colors)
                      else
                        ..._lists(cubit, state, colors),
                    ],
                  ),
                ),
                if (!_searching) _toolbar(colors),
              ],
            );
          },
        ),
      ),
    );
  }

  /// The account avatar; opens Settings, as the profile picture does in To Do.
  Widget _avatar() {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(44, 44),
      onPressed: () => _push(const SettingsScreen()),
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(color: kBlue, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: const Icon(
          CupertinoIcons.person_fill,
          color: CupertinoColors.white,
          size: 18,
        ),
      ),
    );
  }

  List<Widget> _lists(TodoCubit cubit, TodoState state, AppColors colors) {
    return <Widget>[
      SliverToBoxAdapter(
        child: CupertinoListSection.insetGrouped(
          backgroundColor: colors.background,
          children: <Widget>[
            for (final SmartList smart in SmartList.values)
              _ListRow(
                icon: smart.icon,
                color: smart.color,
                title: smart.title,
                count: cubit.openCount(TodoView.smart(smart)),
                onTap: () => _open(TodoView.smart(smart)),
              ),
          ],
        ),
      ),
      if (state.lists.isNotEmpty)
        SliverToBoxAdapter(
          child: CupertinoListSection.insetGrouped(
            backgroundColor: colors.background,
            header: const Text('My Lists'),
            children: <Widget>[
              for (final TaskList list in state.lists)
                _ListRow(
                  icon: CupertinoIcons.list_bullet,
                  color: kListThemes[list.themeIndex % kListThemes.length],
                  title: list.title,
                  count: cubit.openCount(TodoView.list(list)),
                  onTap: () => _open(TodoView.list(list)),
                  onLongPress: () => _listOptions(list),
                ),
            ],
          ),
        ),
      const SliverToBoxAdapter(child: SizedBox(height: 16)),
    ];
  }

  List<Widget> _searchResults(TodoCubit cubit, AppColors colors) {
    final String query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return const <Widget>[];

    final List<Task> found = cubit.state.tasks
        .where(
          (Task t) =>
              t.title.toLowerCase().contains(query) ||
              t.note.toLowerCase().contains(query),
        )
        .toList();

    if (found.isEmpty) {
      return <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 72, 32, 32),
            child: Column(
              children: <Widget>[
                Icon(
                  CupertinoIcons.search,
                  size: 44,
                  color: colors.secondaryLabel,
                ),
                const SizedBox(height: 12),
                Text(
                  'No Results for "${_search.text.trim()}"',
                  textAlign: TextAlign.center,
                  style: IosText.title3,
                ),
                const SizedBox(height: 6),
                Text(
                  'Check the spelling or try a new search.',
                  textAlign: TextAlign.center,
                  style: IosText.subheadline.copyWith(
                    color: colors.secondaryLabel,
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return <Widget>[
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        sliver: SliverList.list(
          children: <Widget>[
            for (final Task task in found) _searchTile(cubit, task),
          ],
        ),
      ),
    ];
  }

  Widget _searchTile(TodoCubit cubit, Task task) {
    final TaskList? list = cubit.listById(task.listId);
    final Color accent = list == null
        ? kBlue
        : kListThemes[list.themeIndex % kListThemes.length];

    return TaskTile(
      task: task,
      accent: accent,
      listLabel: list?.title ?? 'Tasks',
      showMyDayBadge: true,
      onToggle: () => cubit.toggleCompleted(task),
      onStar: () => cubit.toggleImportant(task),
      onDelete: () => cubit.deleteTask(task),
      onTap: () => _push(
        TaskDetailScreen(
          taskId: task.id,
          accent: accent,
          previousPageTitle: 'Lists',
        ),
      ),
    );
  }

  Widget _toolbar(AppColors colors) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bar,
        border: Border(top: BorderSide(color: colors.separator, width: 0)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 50,
          child: Row(
            children: <Widget>[
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                onPressed: _createList,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(CupertinoIcons.plus_circle_fill, size: 24),
                    SizedBox(width: 8),
                    Text('New List', style: IosText.headline),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.count,
    required this.onTap,
    this.onLongPress,
  });

  final IconData icon;
  final Color color;
  final String title;
  final int count;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: CupertinoListTile(
        padding: kRowPadding,
        leading: IconBadge(icon, color: color, size: 28),
        title: Text(title),
        additionalInfo: count > 0 ? Text('$count') : null,
        trailing: const CupertinoListTileChevron(),
        onTap: onTap,
      ),
    );
  }
}
