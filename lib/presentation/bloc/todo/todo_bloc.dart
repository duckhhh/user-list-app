import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/todo_model.dart';
import '../../../data/repositories/todo_repository_impl.dart';
import 'todo_event.dart';
import 'todo_state.dart';

// Simple log function for dev logging
void logInfo(Object? message) {
  // ignore: avoid_print
  print(message);
}

List<Map<String, dynamic>> _extractList(dynamic data, String key) {
  if (data is List) {
    return data.whereType<Map<String, dynamic>>().toList();
  } else if (data is Map && data[key] is List) {
    return (data[key] as List).whereType<Map<String, dynamic>>().toList();
  }
  return [];
}

class TodoBloc extends Bloc<TodoEvent, TodoState> {
  final TodoRepository todoRepository;
  
  TodoBloc({required this.todoRepository}) : super(TodoInitial()) {
    on<FetchUserTodosEvent>(_onFetchUserTodos);
  }

  Future<void> _onFetchUserTodos(
    FetchUserTodosEvent event,
    Emitter<TodoState> emit,
  ) async {
    logInfo('[TodoBloc] FetchUserTodosEvent for userId=${event.userId}');
    emit(TodoLoading());
    logInfo('[TodoBloc] Transitioning to TodoLoading state');
    
    final result = await todoRepository.getUserTodos(event.userId);
    result.fold(
      (failure) {
        logInfo('[TodoBloc] TodoError: \'${failure.message}\'');
        emit(TodoError(failure.message));
      },
      (data) {
        final todosList = _extractList(data, 'todos');
        logInfo('[TodoBloc] TodoLoaded with todos: count=${todosList.length}');
        final parsedTodos = todosList.map((json) => TodoModel.fromJson(json)).toList();
        emit(TodoLoaded(parsedTodos));
      },
    );
  }
}
