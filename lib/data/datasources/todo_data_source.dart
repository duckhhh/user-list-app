import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../models/todo_model.dart';

abstract class TodoDataSource {
  Future<List<TodoModel>> getUserTodos(int userId);
  Future<void> cacheTodos(int userId, List<TodoModel> todos);
  Future<List<TodoModel>> getCachedTodos(int userId);
}

class TodoDataSourceImpl implements TodoDataSource {
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;
  static const String cachedTodosPrefix = 'CACHED_TODOS_';

  TodoDataSourceImpl({
    required this.apiClient,
    required this.sharedPreferences,
  });

  @override
  Future<List<TodoModel>> getUserTodos(int userId) async {
    final response = await apiClient.get('/todos/user/$userId');
    final List<dynamic> todosJson = response['todos'];
    return todosJson.map((json) => TodoModel.fromJson(json)).toList();
  }

  @override
  Future<void> cacheTodos(int userId, List<TodoModel> todos) async {
    final List<String> jsonTodos = todos.map((todo) => json.encode(todo.toJson())).toList();
    await sharedPreferences.setStringList('$cachedTodosPrefix$userId', jsonTodos);
  }

  @override
  Future<List<TodoModel>> getCachedTodos(int userId) async {
    final jsonTodos = sharedPreferences.getStringList('$cachedTodosPrefix$userId');
    
    if (jsonTodos == null) {
      return [];
    }
    
    return jsonTodos
        .map((jsonTodo) => TodoModel.fromJson(json.decode(jsonTodo)))
        .toList();
  }
}
