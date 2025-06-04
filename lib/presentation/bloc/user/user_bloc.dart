import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/user_repository_impl.dart';
import 'user_event.dart';
import 'user_state.dart';

// Simple log function for dev logging
void logInfo(Object? message) {
  // ignore: avoid_print
  print(message);
}

class UserBloc extends Bloc<UserEvent, UserState> {
  final UserRepository userRepository;
  static const int _limit = 10;
  
  UserBloc({required this.userRepository}) : super(UserInitial()) {
    on<FetchUsersEvent>(_onFetchUsers);
    on<FetchMoreUsersEvent>(_onFetchMoreUsers);
    on<SearchUsersEvent>(_onSearchUsers);
    on<FetchUserDetailsEvent>(_onFetchUserDetails);
    on<RestorePreviousStateEvent>(_onRestorePreviousState);
  }

  Future<void> _onFetchUsers(
    FetchUsersEvent event,
    Emitter<UserState> emit,
  ) async {
    logInfo('[UserBloc] FetchUsersEvent: refresh=${event.refresh}');
    
    // Always emit loading state to ensure UI updates
    emit(UserLoading());
    logInfo('[UserBloc] UserLoading state emitted');
    
    final result = await userRepository.getUsers(
      limit: _limit,
      skip: 0,
    );
    
    logInfo('[UserBloc] getUsers result received');
    
    result.fold(
      (failure) {
        logInfo('[UserBloc] Error: ${failure.message}');
        emit(UserError(failure.message));
      },
      (data) {
        final List<dynamic> usersJson = data['users'];
        final users = usersJson.map((json) => UserModel.fromJson(json)).toList();
        final total = data['total'];
        final skip = data['skip'];
        final limit = data['limit'];
        
        final hasReachedMax = users.length >= total;
        
        logInfo('[UserBloc] Emitting UserLoaded with ${users.length} users, total=$total');
        emit(UserLoaded(
          users: users,
          total: total,
          skip: skip,
          limit: limit,
          hasReachedMax: hasReachedMax,
        ));
        logInfo('[UserBloc] UserLoaded state emitted successfully');
      },
    );
  }

  Future<void> _onFetchMoreUsers(
    FetchMoreUsersEvent event,
    Emitter<UserState> emit,
  ) async {
    logInfo('[UserBloc] FetchMoreUsersEvent');
    if (state is UserLoaded) {
      final currentState = state as UserLoaded;
      
      // Don't fetch more if we've reached the max or if we're currently searching
      if (currentState.hasReachedMax || currentState.searchQuery != null) {
        logInfo('[UserBloc] Skipping fetch more: hasReachedMax=${currentState.hasReachedMax}, searchQuery=${currentState.searchQuery}');
        return;
      }
      
      final result = await userRepository.getUsers(
        limit: _limit,
        skip: currentState.skip + _limit,
        search: currentState.searchQuery,
      );
      logInfo('[UserBloc] getUsers result received for more users');
      
      result.fold(
        (failure) => emit(UserError(failure.message)),
        (data) {
          final List<dynamic> usersJson = data['users'];
          final newUsers = usersJson.map((json) => UserModel.fromJson(json)).toList();
          final total = data['total'];
          final skip = data['skip'];
          final limit = data['limit'];
          
          // If no new users returned, we've reached the max
          if (newUsers.isEmpty) {
            logInfo('[UserBloc] No new users returned, reached max');
            emit(currentState.copyWith(hasReachedMax: true));
            logInfo('[UserBloc] UserLoaded state emitted with hasReachedMax=true');
            return;
          }
          
          logInfo('[UserBloc] Emitting UserLoaded with ${currentState.users.length + newUsers.length} total users');
          emit(UserLoaded(
            users: [...currentState.users, ...newUsers],
            total: total,
            skip: skip,
            limit: limit,
            hasReachedMax: skip + limit >= total,
            searchQuery: currentState.searchQuery,
          ));
          logInfo('[UserBloc] UserLoaded state emitted successfully');
        },
      );
    }
  }

  Future<void> _onSearchUsers(
    SearchUsersEvent event,
    Emitter<UserState> emit,
  ) async {
    logInfo('[UserBloc] SearchUsersEvent: query=${event.query}');
    emit(UserLoading());
    logInfo('[UserBloc] UserLoading state emitted');
    
    // If search query is empty, fetch all users
    if (event.query.isEmpty) {
      add(const FetchUsersEvent());
      return;
    }
    
    logInfo('[UserBloc] Searching users with query: ${event.query}');
    final result = await userRepository.getUsers(
      limit: _limit,
      skip: 0,
      search: event.query,
    );
    logInfo('[UserBloc] Search results received');
    
    result.fold(
      (failure) => emit(UserError(failure.message)),
      (data) {
        final List<dynamic> usersJson = data['users'];
        final users = usersJson.map((json) => UserModel.fromJson(json)).toList();
        final total = data['total'];
        final skip = data['skip'];
        final limit = data['limit'];
        
        final hasReachedMax = users.length >= total;
        
        emit(UserLoaded(
          users: users,
          total: total,
          skip: skip,
          limit: limit,
          hasReachedMax: hasReachedMax,
          searchQuery: event.query,
        ));
      },
    );
  }

  Future<void> _onFetchUserDetails(
    FetchUserDetailsEvent event,
    Emitter<UserState> emit,
  ) async {
    // Store current state if it's UserLoaded
    UserState? previousState;
    if (state is UserLoaded) {
      previousState = state;
    }
    
    emit(UserDetailLoading());
    
    final result = await userRepository.getUserById(event.userId);
    
    result.fold(
      (failure) {
        emit(UserDetailError(failure.message));
        // Restore previous state if it exists
        if (previousState != null) {
          emit(previousState);
        }
      },
      (user) => emit(UserDetailLoaded(user, previousState: previousState)),
    );
  }

  void _onRestorePreviousState(
    RestorePreviousStateEvent event,
    Emitter<UserState> emit,
  ) {
    if (state is UserDetailLoaded) {
      final currentState = state as UserDetailLoaded;
      if (currentState.previousState != null && currentState.previousState is UserLoaded) {
        emit(currentState.previousState!);
      } else {
        emit(UserLoading());
        add(const FetchUsersEvent());
      }
    }
  }
}
