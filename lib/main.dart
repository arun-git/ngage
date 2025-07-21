import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/auth_providers.dart';
import 'ui/auth/login_screen.dart';
import 'ui/widgets/platform_navigation.dart';
import 'ui/widgets/selectable_error_message.dart';
import 'ui/groups/create_group_screen.dart';
import 'ui/groups/groups_list_screen.dart';
import 'utils/error_handler.dart';
import 'utils/logger.dart';
import 'utils/responsive_theme.dart';
import 'utils/responsive_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize error handling system
  ErrorHandler.initialize();
  
  // Configure logger
  Logger().configure(
    minimumLevel: LogLevel.info,
    enableRemoteLogging: true,
    enableLocalStorage: true,
    maxLocalLogs: 1000,
  );
  
  // Initialize Firebase with platform-specific options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(
    const ProviderScope(
      child: NgageApp(),
    ),
  );
}

class NgageApp extends ConsumerWidget {
  const NgageApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Ngage Platform',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    
    switch (authState.state) {
      case AuthState.initial:
      case AuthState.loading:
        return const LoadingScreen();
      case AuthState.authenticated:
        return const HomePage();
      case AuthState.unauthenticated:
        return const LoginScreen();
      case AuthState.error:
        return ErrorScreen(message: authState.errorMessage ?? 'Unknown error');
    }
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading...'),
          ],
        ),
      ),
    );
  }
}



class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;
  
  final List<NavigationItem> _navigationItems = [
    const NavigationItem(
      icon: Icon(Icons.dashboard),
      label: 'Dashboard',
      tooltip: 'View dashboard',
    ),
    const NavigationItem(
      icon: Icon(Icons.group),
      label: 'Groups',
      tooltip: 'Manage groups',
    ),
    const NavigationItem(
      icon: Icon(Icons.event),
      label: 'Events',
      tooltip: 'View events',
    ),
    const NavigationItem(
      icon: Icon(Icons.leaderboard),
      label: 'Leaderboard',
      tooltip: 'View leaderboard',
    ),
    const NavigationItem(
      icon: Icon(Icons.person),
      label: 'Profile',
      tooltip: 'Manage profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final currentMember = ref.watch(currentMemberProvider);
    final memberProfiles = ref.watch(memberProfilesProvider);

    return PlatformNavigation(
      title: 'Ngage Platform',
      items: _navigationItems,
      selectedIndex: _selectedIndex,
      onItemSelected: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () {
            // TODO: Show notifications
          },
          tooltip: 'Notifications',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          tooltip: 'More options',
          onSelected: (value) {
            switch (value) {
              case 'logout':
                ref.read(authStateProvider.notifier).signOut();
                break;
              case 'settings':
                // TODO: Navigate to settings
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'settings',
              child: ListTile(
                leading: Icon(Icons.settings),
                title: Text('Settings'),
              ),
            ),
            const PopupMenuItem(
              value: 'logout',
              child: ListTile(
                leading: Icon(Icons.logout),
                title: Text('Logout'),
              ),
            ),
          ],
        ),
      ],
      body: _buildBody(context, currentUser, currentMember, memberProfiles),
      floatingActionButton: _selectedIndex == 1 // Groups tab
        ? PlatformFloatingActionButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CreateGroupScreen(),
                ),
              );
            },
            tooltip: 'Create Group',
            child: const Icon(Icons.add),
          )
        : null,
    );
  }
  
  Widget _buildBody(BuildContext context, currentUser, currentMember, memberProfiles) {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard(context, currentUser, currentMember, memberProfiles);
      case 1:
        return _buildGroups(context);
      case 2:
        return _buildEvents(context);
      case 3:
        return _buildLeaderboard(context);
      case 4:
        return _buildProfile(context, currentUser, currentMember);
      default:
        return _buildDashboard(context, currentUser, currentMember, memberProfiles);
    }
  }
  
  Widget _buildDashboard(BuildContext context, currentUser, currentMember, memberProfiles) {
    return SingleChildScrollView(
      padding: context.responsive.responsivePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to Ngage Platform',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: context.mediumSpacing),
          if (currentUser != null) ...[
            Card(
              child: Padding(
                padding: context.responsive.responsivePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: context.smallSpacing),
                    Text('Email: ${currentUser.email}'),
                    if (currentUser.phone != null) 
                      Text('Phone: ${currentUser.phone}'),
                  ],
                ),
              ),
            ),
            SizedBox(height: context.mediumSpacing),
          ],
          if (currentMember != null) ...[
            Card(
              child: Padding(
                padding: context.responsive.responsivePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Member Profile',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: context.smallSpacing),
                    Text('Name: ${currentMember.firstName} ${currentMember.lastName}'),
                    if (currentMember.title != null) 
                      Text('Title: ${currentMember.title}'),
                  ],
                ),
              ),
            ),
            SizedBox(height: context.mediumSpacing),
          ],
          Card(
            child: Padding(
              padding: context.responsive.responsivePadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Platform Overview',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: context.smallSpacing),
                  Text('Member Profiles: ${memberProfiles.length}'),
                  SizedBox(height: context.smallSpacing),
                  const Text(
                    'Multi-platform engagement platform for teams and competitions',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGroups(BuildContext context) {
    final currentMember = ref.watch(currentMemberProvider);
    
    if (currentMember == null) {
      return const Center(
        child: Text('Please complete your profile to access groups'),
      );
    }
    
    return GroupsListScreen(memberId: currentMember.id);
  }
  
  Widget _buildEvents(BuildContext context) {
    return const Center(
      child: Text('Events - Coming Soon'),
    );
  }
  
  Widget _buildLeaderboard(BuildContext context) {
    return const Center(
      child: Text('Leaderboard - Coming Soon'),
    );
  }
  
  Widget _buildProfile(BuildContext context, currentUser, currentMember) {
    return const Center(
      child: Text('Profile - Coming Soon'),
    );
  }
}

class ErrorScreen extends ConsumerWidget {
  final String message;

  const ErrorScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'An error occurred',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SelectableErrorMessage(
                message: message,
                title: 'Error Details',
                onRetry: () {
                  ref.read(authStateProvider.notifier).clearError();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
