import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cubit/appearance_cubit.dart';
import 'cubit/todo_cubit.dart';
import 'data/background_store.dart';
import 'data/todo_repository.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BackgroundStore.instance.init();
  final TodoRepository repository = TodoRepository();
  await repository.init();
  runApp(TodoApp(repository: repository));
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key, required this.repository});

  final TodoRepository repository;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TodoCubit>(
          create: (_) => TodoCubit(repository)..load(),
        ),
        BlocProvider<AppearanceCubit>(
          create: (_) => AppearanceCubit(repository),
        ),
      ],
      child: BlocBuilder<AppearanceCubit, ThemeMode>(
        builder: (BuildContext context, ThemeMode mode) => MaterialApp(
          title: 'Kundo',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(Brightness.light),
          darkTheme: buildAppTheme(Brightness.dark),
          themeMode: mode,
          // iOS switches appearance at once; the Cupertino widgets snap to the
          // new brightness anyway, so a cross-fade would only half-animate.
          themeAnimationDuration: Duration.zero,
          // Screens are Cupertino pages, which (unlike a Material Scaffold) do
          // not set a text style of their own.
          builder: (BuildContext context, Widget? child) => DefaultTextStyle(
            style: CupertinoTheme.of(context).textTheme.textStyle,
            child: child!,
          ),
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
