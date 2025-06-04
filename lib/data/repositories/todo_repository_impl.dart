import 'package:dartz/dartz.dart';
import '../../core/network/network_info.dart';
import '../../core/utils/failure.dart';
import '../datasources/todo_data_source.dart';
import '../models/todo_model.dart';

abstract class TodoRepository {
  Future<Either<Failure, List<TodoModel>>> getUserTodos(int userId);
}

class TodoRepositoryImpl implements TodoRepository {
  final TodoDataSource todoDataSource;
  final NetworkInfo networkInfo;

  TodoRepositoryImpl({
    required this.todoDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<TodoModel>>> getUserTodos(int userId) async {
    if (await networkInfo.isConnected) {
      try {
        final todos = await todoDataSource.getUserTodos(userId);
        await todoDataSource.cacheTodos(userId, todos);
        return Right(todos);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      try {
        final cachedTodos = await todoDataSource.getCachedTodos(userId);
        if (cachedTodos.isNotEmpty) {
          return Right(cachedTodos);
        } else {
          return Left(CacheFailure(message: 'No cached todos available'));
        }
      } catch (e) {
        return Left(CacheFailure(message: e.toString()));
      }
    }
  }
}
