import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_bloc.dart';
import 'presentation/bloc/post/post_bloc.dart';
import 'presentation/bloc/todo/todo_bloc.dart';
import 'presentation/bloc/user/user_bloc.dart';
import 'presentation/bloc/user/user_event.dart';
import 'presentation/screens/user_list_screen.dart' show UserListScreen, routeObserver;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  

  await ServiceLocator().init();
  

  final themeBloc = ServiceLocator().get<ThemeBloc>();
  themeBloc.add(InitThemeEvent());
  

  final userBloc = ServiceLocator().get<UserBloc>();

  userBloc.add(const FetchUsersEvent());
  
  runApp(MyApp(
    themeBloc: themeBloc,
    userBloc: userBloc,
    postBloc: ServiceLocator().get<PostBloc>(),
    todoBloc: ServiceLocator().get<TodoBloc>(),
  ));
}

class MyApp extends StatelessWidget {
  final ThemeBloc themeBloc;
  final UserBloc userBloc;
  final PostBloc postBloc;
  final TodoBloc todoBloc;

  const MyApp({
    super.key,
    required this.themeBloc,
    required this.userBloc,
    required this.postBloc,
    required this.todoBloc,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeBloc>.value(value: themeBloc),
        BlocProvider<UserBloc>.value(value: userBloc),
        BlocProvider<PostBloc>.value(value: postBloc),
        BlocProvider<TodoBloc>.value(value: todoBloc),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, state) {
          return MaterialApp(
            title: 'User List App',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: state.themeMode,

            navigatorObservers: [routeObserver],
            home: const UserListScreen(),
          );
        },
      ),
    );
  }
}

