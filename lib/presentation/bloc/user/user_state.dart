import 'package:equatable/equatable.dart';
import '../../../data/models/user_model.dart';

abstract class UserState extends Equatable {
  const UserState();
  
  @override
  List<Object?> get props => [];
}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserLoaded extends UserState {
  final List<UserModel> users;
  final int total;
  final int skip;
  final int limit;
  final bool hasReachedMax;
  final String? searchQuery;

  const UserLoaded({
    required this.users,
    required this.total,
    required this.skip,
    required this.limit,
    required this.hasReachedMax,
    this.searchQuery,
  });

  UserLoaded copyWith({
    List<UserModel>? users,
    int? total,
    int? skip,
    int? limit,
    bool? hasReachedMax,
    String? searchQuery,
  }) {
    return UserLoaded(
      users: users ?? this.users,
      total: total ?? this.total,
      skip: skip ?? this.skip,
      limit: limit ?? this.limit,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [users, total, skip, limit, hasReachedMax, searchQuery];
}

class UserError extends UserState {
  final String message;

  const UserError(this.message);

  @override
  List<Object?> get props => [message];
}

class UserDetailLoading extends UserState {}

class UserDetailLoaded extends UserState {
  final UserModel user;
  final UserState? previousState;

  const UserDetailLoaded(this.user, {this.previousState});

  @override
  List<Object?> get props => [user, previousState];
}

class UserDetailError extends UserState {
  final String message;

  const UserDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
