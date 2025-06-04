# User List App

A Flutter application implementing user management with the BLoC pattern, integrating DummyJSON APIs for users, posts, and todos. The app follows clean architecture principles and includes features like pagination, search, infinite scrolling, local caching, error handling, and theme switching.

## Features

- **User Listing**: Display users with pagination, search, and infinite scrolling
- **User Details**: Show detailed user information, posts, and todos
- **Create Posts**: Add new posts for users (stored locally)
- **Offline Support**: Cache data for offline access
- **Theme Switching**: Toggle between light and dark themes
- **Pull-to-Refresh**: Update data with pull-to-refresh gesture
- **Error Handling**: Graceful handling of network and server errors

## Architecture

The app follows a clean architecture approach with the following layers:

### Core
- **Network**: API client and network connectivity check
- **Theme**: Theme management with BLoC pattern
- **Utils**: Error handling and utility classes
- **DI**: Dependency injection with service locator

### Data
- **Models**: Data models for users, posts, and todos
- **DataSources**: API and cache implementations
- **Repositories**: Implementation of data access with offline support

### Presentation
- **BLoC**: State management for users, posts, todos, and theme
- **Screens**: User interface screens
- **Widgets**: Reusable UI components

## State Management

The app uses the BLoC (Business Logic Component) pattern for state management with the following components:

- **UserBloc**: Handles fetching users with pagination, searching, and user details
- **PostBloc**: Manages fetching and creating posts
- **TodoBloc**: Handles fetching todos
- **ThemeBloc**: Manages theme switching and persistence

## Dependencies

- **flutter_bloc** and **equatable**: State management
- **http**: API requests
- **internet_connection_checker**: Network status
- **shared_preferences**: Offline caching
- **cached_network_image**: Efficient image loading
- **flutter_spinkit**: Loading indicators
- **pull_to_refresh**: Pull-to-refresh and infinite scrolling
- **dartz**: Functional programming constructs

## Getting Started

### Prerequisites

- Flutter SDK (compatible with Dart SDK ^3.8.1)
- Android Studio / VS Code with Flutter extensions

### Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/user_list_app.git
```

2. Navigate to the project directory
```bash
cd user_list_app
```

3. Install dependencies
```bash
flutter pub get
```

4. Run the app
```bash
flutter run
```

## API Integration

The app integrates with the DummyJSON API for:
- Users: https://dummyjson.com/users
- Posts: https://dummyjson.com/posts/user/{userId}
- Todos: https://dummyjson.com/todos/user/{userId}

## Screenshots

[Include screenshots here]

## Future Enhancements

- Unit and widget testing
- Advanced filtering options
- User authentication
- Analytics integration
- Localization support
