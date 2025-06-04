import 'package:dartz/dartz.dart';
import '../../core/network/network_info.dart';
import '../../core/utils/failure.dart';
import '../datasources/user_data_source.dart';
import '../models/user_model.dart';

abstract class UserRepository {
  Future<Either<Failure, Map<String, dynamic>>> getUsers({int limit = 10, int skip = 0, String? search});
  Future<Either<Failure, UserModel>> getUserById(int id);
}

class UserRepositoryImpl implements UserRepository {
  final UserDataSource userDataSource;
  final NetworkInfo networkInfo;

  UserRepositoryImpl({
    required this.userDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, Map<String, dynamic>>> getUsers({
    int limit = 10,
    int skip = 0,
    String? search,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final result = await userDataSource.getUsers(
          limit: limit,
          skip: skip,
          search: search,
        );
        
        // Cache users if we're not searching and it's the first page
        if (search == null && skip == 0) {
          final users = (result['users'] as List)
              .map((user) => UserModel.fromJson(user))
              .toList();
          await userDataSource.cacheUsers(users);
        }
        
        return Right(result);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      try {
        // Only return cached users if we're not searching and it's the first page
        if (search == null && skip == 0) {
          final cachedUsers = await userDataSource.getCachedUsers();
          return Right({
            'users': cachedUsers,
            'total': cachedUsers.length,
            'skip': 0,
            'limit': cachedUsers.length,
          });
        } else {
          return Left(NetworkFailure(message: 'No internet connection'));
        }
      } catch (e) {
        return Left(CacheFailure(message: e.toString()));
      }
    }
  }

  @override
  Future<Either<Failure, UserModel>> getUserById(int id) async {
    if (await networkInfo.isConnected) {
      try {
        final user = await userDataSource.getUserById(id);
        return Right(user);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      try {
        final cachedUsers = await userDataSource.getCachedUsers();
        final user = cachedUsers.firstWhere((user) => user.id == id);
        return Right(user);
      } catch (e) {
        return Left(CacheFailure(message: 'User not found in cache'));
      }
    }
  }
}
