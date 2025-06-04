import 'package:equatable/equatable.dart';

abstract class PostEvent extends Equatable {
  const PostEvent();

  @override
  List<Object?> get props => [];
}

class FetchUserPostsEvent extends PostEvent {
  final int userId;

  const FetchUserPostsEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class CreatePostEvent extends PostEvent {
  final String title;
  final String body;
  final int userId;

  const CreatePostEvent({
    required this.title,
    required this.body,
    required this.userId,
  });

  @override
  List<Object?> get props => [title, body, userId];
}
