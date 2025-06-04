import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../models/user_model.dart';

abstract class UserDataSource {
  Future<Map<String, dynamic>> getUsers({int limit = 10, int skip = 0, String? search});
  Future<UserModel> getUserById(int id);
  Future<void> cacheUsers(List<UserModel> users);
  Future<List<UserModel>> getCachedUsers();
}

class UserDataSourceImpl implements UserDataSource {
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;
  static const String cachedUsersKey = 'CACHED_USERS';

  UserDataSourceImpl({
    required this.apiClient,
    required this.sharedPreferences,
  });

  @override
  Future<Map<String, dynamic>> getUsers({int limit = 10, int skip = 0, String? search}) async {
    final queryParams = {
      'limit': limit.toString(),
      'skip': skip.toString(),
    };
    
    if (search != null && search.isNotEmpty) {
      queryParams['q'] = search;
      return await apiClient.get('/users/search', queryParams: queryParams);
    } else {
      return await apiClient.get('/users', queryParams: queryParams);
    }
  }

  @override
  Future<UserModel> getUserById(int id) async {
    final response = await apiClient.get('/users/$id');
    return UserModel.fromJson(response);
  }

  @override
  Future<void> cacheUsers(List<UserModel> users) async {
    final List<String> jsonUsers = users.map((user) => json.encode(user.toJson())).toList();
    await sharedPreferences.setStringList(cachedUsersKey, jsonUsers);
  }

  @override
  Future<List<UserModel>> getCachedUsers() async {
    final jsonUsers = sharedPreferences.getStringList(cachedUsersKey);
    
    if (jsonUsers == null) {
      return [];
    }
    
    return jsonUsers
        .map((jsonUser) => UserModel.fromJson(json.decode(jsonUser)))
        .toList();
  }
}
