import 'package:equatable/equatable.dart';
import '../../../data/models/post_model.dart';

abstract class PostState extends Equatable {
  const PostState();
  
  @override
  List<Object?> get props => [];
}

class PostInitial extends PostState {}

class PostLoading extends PostState {}

class PostLoaded extends PostState {
  final List<PostModel> posts;

  const PostLoaded(this.posts);

  @override
  List<Object?> get props => [posts];
}

class PostError extends PostState {
  final String message;

  const PostError(this.message);

  @override
  List<Object?> get props => [message];
}

class PostCreating extends PostState {}

class PostCreated extends PostState {
  final PostModel post;
  final List<PostModel>? updatedPosts;

  const PostCreated(this.post, [this.updatedPosts]);

  @override
  List<Object?> get props => [post, updatedPosts];
}

class PostCreationError extends PostState {
  final String message;

  const PostCreationError(this.message);

  @override
  List<Object?> get props => [message];
}
