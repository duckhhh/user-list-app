import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../bloc/user/user_bloc.dart';
import '../bloc/user/user_event.dart';
import '../bloc/user/user_state.dart';
import '../widgets/error_message.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/theme_toggle.dart';
import '../widgets/user_list_item.dart';
import 'user_detail_screen.dart';

// Create a global RouteObserver that will be used to monitor route changes
final RouteObserver<ModalRoute<dynamic>> routeObserver = RouteObserver<ModalRoute<dynamic>>();

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> with RouteAware {
  final TextEditingController _searchController = TextEditingController();
  final RefreshController _refreshController = RefreshController();
  
  @override
  void initState() {
    super.initState();
    
    // Fetch users immediately
    context.read<UserBloc>().add(const FetchUsersEvent());
    
    // Also set up a post-frame callback to ensure UI is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // This will ensure users are fetched after the first frame is rendered
        print('UserListScreen: Post-frame callback triggered, fetching users again');
        context.read<UserBloc>().add(const FetchUsersEvent());
      }
    });
    
    // Set up a route observer to detect when returning from detail screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Add a listener to refresh when this screen becomes visible again
        routeObserver.subscribe(this, ModalRoute.of(context)!);
      }
    });
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _searchController.dispose();
    _refreshController.dispose();
    super.dispose();
  }
  
  // Called when the current route has been pushed
  @override
  void didPushNext() {
    // This is called when another route has been pushed on top of this one
    print('UserListScreen: didPushNext');
  }
  
  // Called when the current route has been popped off
  @override
  void didPop() {
    print('UserListScreen: didPop');
  }
  
  // Called when the current route has been popped to
  @override
  void didPopNext() {
    // This is called when we return to this screen (e.g., from detail screen)
    print('UserListScreen: didPopNext - Refreshing user list');
    if (mounted) {
      // Refresh the user list when we return to this screen
      context.read<UserBloc>().add(const FetchUsersEvent());
    }
  }

  void _onRefresh() {
    context.read<UserBloc>().add(const FetchUsersEvent(refresh: true));
    _refreshController.refreshCompleted();
  }

  void _onLoading() {
    context.read<UserBloc>().add(FetchMoreUsersEvent());
    _refreshController.loadComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User List'),
        actions: [
          BlocBuilder<UserBloc, UserState>(
            builder: (context, state) {
              if (state is UserLoaded && state.searchQuery != null) {
                return IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<UserBloc>().add(const FetchUsersEvent());
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const ThemeToggle(),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                if (value.length >= 2) {
                  context.read<UserBloc>().add(SearchUsersEvent(value));
                } else if (value.isEmpty) {
                  context.read<UserBloc>().add(const FetchUsersEvent());
                }
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<UserBloc, UserState>(
              builder: (context, state) {
                if (state is UserLoading) {
                  return const LoadingIndicator();
                } else if (state is UserLoaded) {
                  if (state.users.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.person_off, size: 60),
                          const SizedBox(height: 16),
                          Text(
                            state.searchQuery != null
                                ? 'No users found for "${state.searchQuery}"'
                                : 'No users found',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return SmartRefresher(
                    controller: _refreshController,
                    enablePullDown: true,
                    enablePullUp: !state.hasReachedMax,
                    onRefresh: _onRefresh,
                    onLoading: _onLoading,
                    header: const WaterDropHeader(),
                    footer: CustomFooter(
                      builder: (context, mode) {
                        Widget body;
                        if (mode == LoadStatus.idle) {
                          body = const Text("Pull up to load more");
                        } else if (mode == LoadStatus.loading) {
                          body = const CircularProgressIndicator();
                        } else if (mode == LoadStatus.failed) {
                          body = const Text("Load failed!");
                        } else if (mode == LoadStatus.canLoading) {
                          body = const Text("Release to load more");
                        } else {
                          body = const Text("No more data");
                        }
                        return SizedBox(
                          height: 55.0,
                          child: Center(child: body),
                        );
                      },
                    ),
                    child: ListView.builder(
                      itemCount: state.users.length,
                      itemBuilder: (context, index) {
                        final user = state.users[index];
                        return UserListItem(
                          user: user,
                          onTap: () async {
                            // Navigate to the detail screen and wait for it to complete
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserDetailScreen(userId: user.id),
                              ),
                            );
                            
                            // When returning from the detail screen, refresh the user list
                            if (mounted) {
                              print('Returned from user detail screen, refreshing user list');
                              context.read<UserBloc>().add(const FetchUsersEvent());
                            }
                          },
                        );
                      },
                    ),
                  );
                } else if (state is UserError) {
                  return ErrorMessage(
                    message: state.message,
                    onRetry: () {
                      context.read<UserBloc>().add(const FetchUsersEvent());
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
