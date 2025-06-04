import 'package:equatable/equatable.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

class FetchUsersEvent extends UserEvent {
  final bool refresh;

  const FetchUsersEvent({this.refresh = false});

  @override
  List<Object?> get props => [refresh];
}

class FetchMoreUsersEvent extends UserEvent {}

class SearchUsersEvent extends UserEvent {
  final String query;

  const SearchUsersEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class RestorePreviousStateEvent extends UserEvent {
  const RestorePreviousStateEvent();

  @override
  List<Object?> get props => [];
}

class FetchUserDetailsEvent extends UserEvent {
  final int userId;

  const FetchUserDetailsEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}
