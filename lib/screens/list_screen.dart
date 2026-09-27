import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../cubit/todo_cubit.dart';
import '../models/list_background.dart';
import '../models/task.dart';
import '../models/todo_view.dart';
import '../theme.dart';
import '../widgets/ios_ui.dart';
import '../widgets/list_actions.dart';
import '../widgets/list_background_view.dart';
import '../widgets/task_tile.dart';
import 'task_detail_screen.dart';

enum _MenuAction { rename, theme, completed, delete }

/// The task screen of a single list (smart or user created).
class ListScreen extends StatefulWidget {
  const ListScreen({super.key, required this.view});

  final TodoView view;

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final TextEditingController _input = TextEditingController();
  final FocusNode _inputFocus = FocusNode();
  bool _showCompleted = true;

  /// Whether tasks have scrolled under the navigation bar. The page itself is
  /// transparent, so a blur at rest would smear the list background.
  bool _scrolledUnder = false;

  bool _trackScroll(ScrollUpdateNotification notification) {
    if (notification.depth == 0) {
      final bool under = notification.metrics.extentBefore > 0;
      if (under != _scrolledUnder) setState(() => _scrolledUnder = under);
    }
    return false;
  }

  @override
  void dispose() {
    _input.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  /// The view can be renamed or re-themed while it is open.
  TodoView _currentView(TodoCubit cubit) {
    if (widget.view.list == null) return widget.view;
    final TaskList? fresh = cubit.listById(widget.view.list!.id);
    return fresh == null ? widget.view : TodoView.list(fresh);
  }

  /// Adds the typed task and keeps the keyboard up for the next one; an empty
  /// field closes the keyboard instead.
  void _submit(TodoView view) {
    final String text = _input.text;
    if (text.trim().isEmpty) {
      _inputFocus.unfocus();
      return;
    }
    context.read<TodoCubit>().addTask(view, text);
    _input.clear();
  }

  void _openTask(Task task, TodoView view) {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => TaskDetailScreen(
          taskId: task.id,
          accent: view.color,
          previousPageTitle: view.title,
        ),
      ),
    );
  }

  Future<void> _menu(TodoView view) async {
    final TaskList? list = view.list;
    if (list == null) return;

    final _MenuAction? action = await showActionSheet<_MenuAction>(
      context,
      title: list.title,
      actions: <SheetAction<_MenuAction>>[
        const SheetAction<_MenuAction>('Rename List', _MenuAction.rename),
        const SheetAction<_MenuAction>('Change Theme', _MenuAction.theme),
        SheetAction<_MenuAction>(
          _showCompleted ? 'Hide Completed Tasks' : 'Show Completed Tasks',
          _MenuAction.completed,
        ),
        const SheetAction<_MenuAction>(
          'Delete List',
          _MenuAction.delete,
          isDestructive: true,
        ),
      ],
    );
    if (!mounted || action == null) return;

    switch (action) {
      case _MenuAction.rename:
        await renameList(context, list);
      case _MenuAction.theme:
        await changeListTheme(context, list);
      case _MenuAction.completed:
        setState(() => _showCompleted = !_showCompleted);
      case _MenuAction.delete:
        final bool deleted = await confirmAndDeleteList(context, list);
        if (deleted && mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _suggestions() async {
    final TodoCubit cubit = context.read<TodoCubit>();
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext sheetContext) {
        return BlocBuilder<TodoCubit, TodoState>(
          bloc: cubit,
          builder: (BuildContext context, TodoState state) {
            final AppColors colors = AppColors.of(context);
            final List<Task> items = cubit.suggestions();
            return IosSheet(
              title: 'Suggestions',
              child: items.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                      child: Text(
                        'Nothing to suggest — every open task is already in '
                        'My Day.',
                        textAlign: TextAlign.center,
                        style: IosText.subheadline.copyWith(
                          color: colors.secondaryLabel,
                        ),
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      children: <Widget>[
                        CupertinoListSection.insetGrouped(
                          backgroundColor: colors.background,
                          margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          hasLeading: false,
                          children: <Widget>[
                            for (final Task task in items)
                              CupertinoListTile(
                                title: Text(task.title),
                                subtitle: Text(
                                  <String>[
                                    cubit.listById(task.listId)?.title ??
                                        'Tasks',
                                    if (task.dueDate != null)
                                      formatTaskDate(task.dueDate!),
                                  ].join(' · '),
                                ),
                                trailing: CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(44, 44),
                                  onPressed: () => cubit.toggleMyDay(task),
                                  child: const Icon(
                                    CupertinoIcons.plus_circle_fill,
                                    size: 26,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return NavBarScrollScope(
      child: BlocBuilder<TodoCubit, TodoState>(
        builder: (BuildContext context, TodoState state) {
          final TodoCubit cubit = context.read<TodoCubit>();
          final TodoView view = _currentView(cubit);
          final List<Task> tasks = cubit.tasksFor(view);
          final List<Task> open = tasks
              .where((Task t) => !t.isCompleted)
              .toList();
          final List<Task> done = tasks
              .where((Task t) => t.isCompleted)
              .toList();

          return ListBackgroundView(
            background: ListBackground.decode(view.list?.background),
            color: view.color,
            child: CupertinoPageScaffold(
              // The list background shows through the page.
              backgroundColor: const Color(0x00000000),
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: NotificationListener<ScrollUpdateNotification>(
                      onNotification: _trackScroll,
                      child: CustomScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        slivers: <Widget>[
                          _navBar(view),
                          SliverToBoxAdapter(
                            child: _subtitle(view, open.length),
                          ),
                          if (open.isEmpty && done.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: _emptyState(view),
                            )
                          else
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                              sliver: SliverList.list(
                                children: <Widget>[
                                  if (view.isPlanned)
                                    ..._plannedSections(cubit, view, open)
                                  else
                                    ...open.map(
                                      (Task t) => _tile(cubit, view, t),
                                    ),
                                  if (done.isNotEmpty) ...<Widget>[
                                    const SizedBox(height: 6),
                                    _completedHeader(done.length),
                                    if (_showCompleted)
                                      ...done.map(
                                        (Task t) => _tile(cubit, view, t),
                                      ),
                                  ],
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (view.canAddTasks) _addBar(view),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Large white title over the list color. The bar is clear at the top and
  /// turns into a blurred, darkened list color once tasks scroll under it.
  Widget _navBar(TodoView view) {
    final bool dark = AppColors.of(context).isDark;
    final Color barColor = Color.lerp(
      view.color,
      const Color(0xFF000000),
      dark ? 0.55 : 0.2,
    )!.withValues(alpha: 0.82);

    return CupertinoTheme(
      data: const CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: CupertinoColors.white,
      ),
      child: CupertinoSliverNavigationBar(
        largeTitle: Text(view.title),
        previousPageTitle: 'Lists',
        // The home bar is styled differently; a hero flight between the two
        // would flash the white title over the grouped background.
        transitionBetweenRoutes: false,
        brightness: Brightness.dark,
        backgroundColor: barColor,
        enableBackgroundFilterBlur: _scrolledUnder,
        border: null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (view.isMyDay)
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(44, 44),
                onPressed: _suggestions,
                child: const Icon(CupertinoIcons.lightbulb),
              ),
            if (view.list != null)
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(44, 44),
                onPressed: () => _menu(view),
                child: const Icon(CupertinoIcons.ellipsis_circle),
              ),
          ],
        ),
      ),
    );
  }

  Widget _subtitle(TodoView view, int openCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Text(
        view.isMyDay
            ? DateFormat('EEEE, MMMM d').format(DateTime.now())
            : '$openCount ${openCount == 1 ? 'task' : 'tasks'}',
        style: IosText.subheadline.copyWith(
          color: CupertinoColors.white.withValues(alpha: 0.85),
        ),
      ),
    );
  }

  Widget _tile(TodoCubit cubit, TodoView view, Task task) {
    return TaskTile(
      task: task,
      accent: view.color,
      listLabel: view.isSmart
          ? (cubit.listById(task.listId)?.title ?? 'Tasks')
          : null,
      showMyDayBadge: !view.isMyDay,
      onToggle: () => cubit.toggleCompleted(task),
      onStar: () => cubit.toggleImportant(task),
      onDelete: () => cubit.deleteTask(task),
      onTap: () => _openTask(task, view),
    );
  }

  /// Planned splits its tasks into date buckets, like the real app.
  List<Widget> _plannedSections(
    TodoCubit cubit,
    TodoView view,
    List<Task> open,
  ) {
    final Map<String, List<Task>> buckets = <String, List<Task>>{};
    for (final Task task in open) {
      buckets.putIfAbsent(_bucketOf(task.dueDate!), () => <Task>[]).add(task);
    }

    const List<String> order = <String>[
      'Earlier',
      'Today',
      'Tomorrow',
      'This week',
      'Later',
    ];

    return <Widget>[
      for (final String name in order)
        if (buckets[name] != null) ...<Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
            child: Text(
              name,
              style: IosText.headline.copyWith(color: CupertinoColors.white),
            ),
          ),
          ...buckets[name]!.map((Task t) => _tile(cubit, view, t)),
        ],
    ];
  }

  static String _bucketOf(DateTime due) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final int diff = DateTime(
      due.year,
      due.month,
      due.day,
    ).difference(today).inDays;
    if (diff < 0) return 'Earlier';
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff <= 7) return 'This week';
    return 'Later';
  }

  Widget _completedHeader(int count) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GestureDetector(
          onTap: () => setState(() => _showCompleted = !_showCompleted),
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 6, 12, 6),
            decoration: BoxDecoration(
              color: const Color(0x38000000),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AnimatedRotation(
                  turns: _showCompleted ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    CupertinoIcons.chevron_right,
                    size: 14,
                    color: CupertinoColors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Completed',
                  style: IosText.subheadline.copyWith(
                    color: CupertinoColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$count',
                  style: IosText.subheadline.copyWith(
                    color: CupertinoColors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState(TodoView view) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              view.icon,
              size: 56,
              color: CupertinoColors.white.withValues(alpha: 0.85),
            ),
            const SizedBox(height: 14),
            Text(
              view.canAddTasks
                  ? 'Add a task to get started'
                  : 'Tasks others assign to you will show up here once sharing is supported',
              textAlign: TextAlign.center,
              style: IosText.subheadline.copyWith(
                color: CupertinoColors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addBar(TodoView view) {
    final AppColors colors = AppColors.of(context);
    final Color tint = tintFor(view.color, colors.brightness);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
        child: Container(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.only(left: 14, right: 8),
          child: Row(
            children: <Widget>[
              Icon(CupertinoIcons.add, color: tint, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: CupertinoTextField.borderless(
                  controller: _input,
                  focusNode: _inputFocus,
                  placeholder: 'Add a Task',
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.done,
                  cursorColor: tint,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  style: IosText.body.copyWith(color: colors.label),
                  // Handled here so "done" adds the task without closing the
                  // keyboard; To Do is built for typing several in a row.
                  onEditingComplete: () => _submit(view),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
