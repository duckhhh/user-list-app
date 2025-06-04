import 'package:equatable/equatable.dart';

abstract class TodoEvent extends Equatable {
  const TodoEvent();

  @override
  List<Object?> get props => [];
}

class FetchUserTodosEvent extends TodoEvent {
  final int userId;

  const FetchUserTodosEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}
