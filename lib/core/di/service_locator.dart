import 'package:http/http.dart' as http;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../data/datasources/post_data_source.dart';
import '../../data/datasources/todo_data_source.dart';
import '../../data/datasources/user_data_source.dart';
import '../../data/repositories/post_repository_impl.dart';
import '../../data/repositories/todo_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../presentation/bloc/post/post_bloc.dart';
import '../../presentation/bloc/todo/todo_bloc.dart';
import '../../presentation/bloc/user/user_bloc.dart';
import '../network/api_client.dart';
import '../network/network_info.dart';
import '../theme/theme_bloc.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  
  factory ServiceLocator() => _instance;
  
  ServiceLocator._internal();
  
  final Map<dynamic, dynamic> _dependencies = {};
  
  Future<void> init() async {
    // External dependencies
    final sharedPreferences = await SharedPreferences.getInstance();
    _dependencies['shared_preferences'] = sharedPreferences;
    _dependencies['http_client'] = http.Client();
    
    // Handle InternetConnectionChecker differently for web
    if (!kIsWeb) {
      _dependencies['connection_checker'] = InternetConnectionChecker();
    } else {
      // For web, we'll pass null and handle it in NetworkInfoImpl
      _dependencies['connection_checker'] = null;
    }
    
    // Core
    _dependencies['api_client'] = ApiClient(client: get<http.Client>());
    _dependencies[NetworkInfo] = NetworkInfoImpl(
      kIsWeb ? null : get('connection_checker'),
    );
    
    // Data sources
    _dependencies['user_data_source'] = UserDataSourceImpl(
      apiClient: get<ApiClient>(),
      sharedPreferences: get<SharedPreferences>(),
    );
    _dependencies['post_data_source'] = PostDataSourceImpl(
      apiClient: get<ApiClient>(),
      sharedPreferences: get<SharedPreferences>(),
    );
    _dependencies['todo_data_source'] = TodoDataSourceImpl(
      apiClient: get<ApiClient>(),
      sharedPreferences: get<SharedPreferences>(),
    );
    
    // Repositories
    _dependencies['user_repository'] = UserRepositoryImpl(
      userDataSource: get<UserDataSource>(),
      networkInfo: get<NetworkInfo>(),
    );
    _dependencies['post_repository'] = PostRepositoryImpl(
      postDataSource: get<PostDataSource>(),
      networkInfo: get<NetworkInfo>(),
    );
    _dependencies['todo_repository'] = TodoRepositoryImpl(
      todoDataSource: get<TodoDataSource>(),
      networkInfo: get<NetworkInfo>(),
    );
    
    // Blocs
    _dependencies['theme_bloc'] = ThemeBloc();
    _dependencies['user_bloc'] = UserBloc(userRepository: get<UserRepository>());
    _dependencies['post_bloc'] = PostBloc(postRepository: get<PostRepository>());
    _dependencies['todo_bloc'] = TodoBloc(todoRepository: get<TodoRepository>());
  }
  
  T get<T>([String? key]) {
    dynamic dependency;
    if (key != null) {
      dependency = _dependencies[key];
    } else {
      dependency = _dependencies.values.whereType<T>().firstOrNull;
    }
    if (dependency == null) {
      throw Exception('Dependency ${key ?? T.toString()} not found');
    }
    return dependency as T;
  }
}
