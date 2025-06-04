import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../models/post_model.dart';

abstract class PostDataSource {
  Future<List<PostModel>> getUserPosts(int userId);
  Future<PostModel> createPost(String title, String body, int userId);
  Future<void> cachePosts(int userId, List<PostModel> posts);
  Future<List<PostModel>> getCachedPosts(int userId);
}

class PostDataSourceImpl implements PostDataSource {
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;
  static const String cachedPostsPrefix = 'CACHED_POSTS_';

  PostDataSourceImpl({
    required this.apiClient,
    required this.sharedPreferences,
  });

  @override
  Future<List<PostModel>> getUserPosts(int userId) async {
    print('[PostDataSource] getUserPosts called for userId=$userId');
    final response = await apiClient.get('/posts/user/$userId');
    print('[PostDataSource] getUserPosts API response: $response');
    final List<dynamic> postsJson = response['posts'];
    return postsJson.map((json) => PostModel.fromJson(json)).toList();
  }

  @override
  Future<PostModel> createPost(String title, String body, int userId) async {
    print('[PostDataSource] addPost called: userId=$userId, title=$title');
    final response = await apiClient.post('/posts/add', {
      'title': title,
      'body': body,
      'userId': userId,
    });
    print('[PostDataSource] addPost API response: $response');
    return PostModel.fromJson(response);
  }

  @override
  Future<void> cachePosts(int userId, List<PostModel> posts) async {
    final List<String> jsonPosts = posts.map((post) => json.encode(post.toJson())).toList();
    await sharedPreferences.setStringList('$cachedPostsPrefix$userId', jsonPosts);
  }

  @override
  Future<List<PostModel>> getCachedPosts(int userId) async {
    final jsonPosts = sharedPreferences.getStringList('$cachedPostsPrefix$userId');
    
    if (jsonPosts == null) {
      return [];
    }
    
    return jsonPosts
        .map((jsonPost) => PostModel.fromJson(json.decode(jsonPost)))
        .toList();
  }
}
