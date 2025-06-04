import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/todo_model.dart';
import '../../data/models/user_model.dart';
import '../bloc/post/post_bloc.dart';
import '../bloc/post/post_event.dart';
import '../bloc/post/post_state.dart';
import '../bloc/todo/todo_bloc.dart';
import '../bloc/todo/todo_event.dart';
import '../bloc/todo/todo_state.dart';
import '../bloc/user/user_bloc.dart';
import '../bloc/user/user_event.dart';
import '../bloc/user/user_state.dart';
import '../widgets/error_message.dart';
import '../widgets/loading_indicator.dart';
import 'create_post_screen.dart';

class UserDetailScreen extends StatefulWidget {
  final int userId;

  const UserDetailScreen({
    super.key,
    required this.userId,
  });

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Fetch user details
    context.read<UserBloc>().add(FetchUserDetailsEvent(widget.userId));
    
    // Fetch user posts
    context.read<PostBloc>().add(FetchUserPostsEvent(widget.userId));
    
    // Fetch user todos
    context.read<TodoBloc>().add(FetchUserTodosEvent(widget.userId));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // When the user pops back, ensure the previous screen refreshes its data
      onWillPop: () async {
        // This will be handled by the previous screen's async navigation
        return true;
      },
      child: Scaffold(
      appBar: AppBar(
        title: BlocBuilder<UserBloc, UserState>(
          builder: (context, state) {
            if (state is UserDetailLoaded) {
              return Text(state.user.fullName);
            }
            return const Text('User Details');
          },
        ),
      ),
      body: BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          if (state is UserDetailLoading) {
            return const LoadingIndicator();
          } else if (state is UserDetailLoaded) {
            return _buildUserDetails(state.user);
          } else if (state is UserDetailError) {
            return ErrorMessage(
              message: state.message,
              onRetry: () {
                context.read<UserBloc>().add(FetchUserDetailsEvent(widget.userId));
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: _buildFloatingActionButton(),
    ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () async {
        // Navigate to create post screen and wait for result
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreatePostScreen(userId: widget.userId),
          ),
        );
        
        // Check if the widget is still mounted before using context
        if (!mounted) return;
        
        // Refresh posts when returning from create post screen
        // This ensures we get the latest posts including the newly created one
        context.read<PostBloc>().add(FetchUserPostsEvent(widget.userId));
        
        // Show a success message if a post was created
        if (result == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post refreshed successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: const Icon(Icons.add),
    );
  }

  Widget _buildUserDetails(UserModel user) {
    return Column(
      children: [
        _buildUserHeader(user),
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Posts'),
            Tab(text: 'Todos'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPostsTab(),
              _buildTodosTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserHeader(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(user.image),
          ),
          const SizedBox(height: 16),
          Text(
            user.fullName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '@${user.username}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.email, size: 16),
              const SizedBox(width: 4),
              Text(user.email),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.phone, size: 16),
              const SizedBox(width: 4),
              Text(user.phone),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.business, size: 16),
              const SizedBox(width: 4),
              Text(user.company),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostsTab() {
    return BlocConsumer<PostBloc, PostState>(
      listener: (context, state) {
        // When a post is created, show a success message
        if (state is PostCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post created successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is PostLoading) {
          return const LoadingIndicator();
        } else if (state is PostLoaded) {
          if (state.posts.isEmpty) {
            return const Center(child: Text('No posts yet. Tap + to add one!'));
          }
          return ListView.builder(
            itemCount: state.posts.length,
            itemBuilder: (context, index) {
              final post = state.posts[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(
                    post.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(post.body),
                  ),
                  isThreeLine: post.body.length > 50,
                ),
              );
            },
          );
        } else if (state is PostCreated && state.updatedPosts != null) {
          // Show the updated posts list immediately after creating a post
          return ListView.builder(
            itemCount: state.updatedPosts!.length,
            itemBuilder: (context, index) {
              final post = state.updatedPosts![index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(
                    post.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(post.body),
                  ),
                  isThreeLine: post.body.length > 50,
                ),
              );
            },
          );
        } else if (state is PostError) {
          return ErrorMessage(
            message: state.message,
            onRetry: () {
              context.read<PostBloc>().add(FetchUserPostsEvent(widget.userId));
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildTodosTab() {
    return BlocBuilder<TodoBloc, TodoState>(
      builder: (context, state) {
        if (state is TodoLoading) {
          return const LoadingIndicator();
        } else if (state is TodoLoaded) {
          if (state.todos.isEmpty) {
            return const Center(
              child: Text('No todos found'),
            );
          }
          
          // Separate completed and incomplete todos
          final completedTodos = state.todos.where((todo) => todo.completed).toList();
          final incompleteTodos = state.todos.where((todo) => !todo.completed).toList();
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (incompleteTodos.isNotEmpty) ...[
                const Text(
                  'Pending',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...incompleteTodos.map((todo) => _buildTodoItem(todo)),
                const SizedBox(height: 16),
              ],
              if (completedTodos.isNotEmpty) ...[
                const Text(
                  'Completed',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...completedTodos.map((todo) => _buildTodoItem(todo)),
              ],
            ],
          );
        } else if (state is TodoError) {
          return ErrorMessage(
            message: state.message,
            onRetry: () {
              context.read<TodoBloc>().add(FetchUserTodosEvent(widget.userId));
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildTodoItem(TodoModel todo) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          todo.completed ? Icons.check_circle : Icons.radio_button_unchecked,
          color: todo.completed ? Colors.green : Colors.orange,
        ),
        title: Text(
          todo.todo,
          style: TextStyle(
            decoration: todo.completed ? TextDecoration.lineThrough : null,
            color: todo.completed ? Colors.grey : null,
          ),
        ),
      ),
    );
  }
}
