import 'package:dartz/dartz.dart';
import '../../core/network/network_info.dart';
import '../../core/utils/failure.dart';
import '../datasources/post_data_source.dart';
import '../models/post_model.dart';

// Simple log func
void logInfo(Object? message) {
  //
  print(message);
}


abstract class PostRepository {
  Future<Either<Failure, List<PostModel>>> getUserPosts(int userId);
  Future<Either<Failure, PostModel>> createPost(String title, String body, int userId);
}

class PostRepositoryImpl implements PostRepository {
  final PostDataSource postDataSource;
  final NetworkInfo networkInfo;

  PostRepositoryImpl({
    required this.postDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<PostModel>>> getUserPosts(int userId) async {
    logInfo('[PostRepository] Fetching posts for userId=$userId');
    if (await networkInfo.isConnected) {
      try {
        final posts = await postDataSource.getUserPosts(userId);
        logInfo('[PostRepository] getUserPosts result: $posts');
        await postDataSource.cachePosts(userId, posts);
        return Right(posts);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      try {
        final cachedPosts = await postDataSource.getCachedPosts(userId);
        if (cachedPosts.isNotEmpty) {
          return Right(cachedPosts);
        } else {
          return Left(CacheFailure(message: 'No cached posts available'));
        }
      } catch (e) {
        return Left(CacheFailure(message: e.toString()));
      }
    }
  }

  @override
  Future<Either<Failure, PostModel>> createPost(String title, String body, int userId) async {
    if (await networkInfo.isConnected) {
      try {
        logInfo('[PostRepository] Creating post with title=$title, body=$body, userId=$userId');
        final post = await postDataSource.createPost(title, body, userId);
        logInfo('[PostRepository] createPost result: $post');
        
        
        final cachedPosts = await postDataSource.getCachedPosts(userId);
        cachedPosts.add(post);
        await postDataSource.cachePosts(userId, cachedPosts);
        
        return Right(post);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }
}
