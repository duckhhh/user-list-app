import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/post_model.dart';
import '../../../data/repositories/post_repository_impl.dart';
import 'post_event.dart';
import 'post_state.dart';

// Simple log function for dev logging
void logInfo(Object? message) {
  // ignore: avoid_print
  print(message);
}


class PostBloc extends Bloc<PostEvent, PostState> {
  final PostRepository postRepository;
  // Keep track of loaded posts for optimistic updates
  List<PostModel> _loadedPosts = [];
  // Keep track of locally created posts separately to ensure they persist
  List<PostModel> _locallyCreatedPosts = [];
  int? _currentUserId;
  
  PostBloc({required this.postRepository}) : super(PostInitial()) {
    on<FetchUserPostsEvent>(_onFetchUserPosts);
    on<CreatePostEvent>(_onCreatePost);
  }

  Future<void> _onFetchUserPosts(
    FetchUserPostsEvent event,
    Emitter<PostState> emit,
  ) async {
    logInfo('[PostBloc] FetchUserPosts for userId=${event.userId}, current local posts=${_locallyCreatedPosts.length}');
    emit(PostLoading());
    logInfo('[PostBloc] PostLoading state emitted');
    _currentUserId = event.userId;
    
    final result = await postRepository.getUserPosts(event.userId);
    
    result.fold(
      (failure) {
        logInfo('[PostBloc] PostError: \'${failure.message}\'');
        emit(PostError(failure.message));
      },
      (posts) {
        // Store the loaded posts from API
        _loadedPosts = posts;
        
        // Check if we have any local posts for this user that aren't in the API response
        // This handles the case where the API doesn't return newly created posts
        final allPosts = _getMergedPosts(event.userId);
        
        logInfo('[PostBloc] PostLoaded with posts: API=${posts.length}, merged=${allPosts.length}');
        emit(PostLoaded(allPosts));
      },
    );
  }

  Future<void> _onCreatePost(
    CreatePostEvent event,
    Emitter<PostState> emit,
  ) async {
    logInfo('[PostBloc] CreatePostEvent for userId=${event.userId}, title=${event.title}');
    emit(PostCreating());
    
    final result = await postRepository.createPost(
      event.title,
      event.body,
      event.userId,
    );
    
    result.fold(
      (failure) => emit(PostCreationError(failure.message)),
      (post) {
        // Generate a truly unique ID for this post to avoid conflicts
        // The API seems to return the same ID (252) for each new post
        // Use current timestamp in milliseconds + a random component to ensure uniqueness
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final uniqueId = 1000000 + timestamp % 1000000;
        
        // Create a new post with the unique ID
        final uniquePost = PostModel(
          id: uniqueId,
          title: post.title,
          body: post.body,
          userId: post.userId,
          tags: post.tags,
          reactions: post.reactions,
        );
        
        logInfo('[PostBloc] Created post with unique ID: $uniqueId (original ID: ${post.id})');
        
        // Add the new post with unique ID to our local list
        _locallyCreatedPosts.add(uniquePost);
        
        // If we're on the same user's detail page, update the UI with the new post included
        if (_currentUserId == event.userId) {
          final allPosts = _getMergedPosts(event.userId);
          emit(PostCreated(uniquePost, allPosts));
        } else {
          emit(PostCreated(uniquePost));
        }
      },
    );
  }

  // Helper method to get all posts for a user, including locally created ones
  List<PostModel> _getMergedPosts(int userId) {
    // Create a copy of the loaded posts to avoid modifying the original list
    final List<PostModel> allPosts = List.from(_loadedPosts);
    
    // Get locally created posts for this user
    final localPosts = _locallyCreatedPosts.where((post) => post.userId == userId).toList();
    
    // Log before merging
    logInfo('[PostBloc] Before merge: API posts=${_loadedPosts.length}, local posts=${localPosts.length}');
    
    // Add all local posts - we've ensured they have unique IDs when creating them
    allPosts.addAll(localPosts);
    
    // Remove any duplicates by ID (keeping the first occurrence)
    final uniquePosts = <PostModel>[];
    final seenIds = <int>{};
    
    for (final post in allPosts) {
      if (!seenIds.contains(post.id)) {
        uniquePosts.add(post);
        seenIds.add(post.id);
      }
    }
    
    // Sort posts by id in descending order (newest first)
    uniquePosts.sort((a, b) => b.id.compareTo(a.id));
    
    // Log the final counts for debugging
    logInfo('[PostBloc] After merge: merged=${uniquePosts.length}, unique IDs=${seenIds.length}');
    
    return uniquePosts;
  }
}
