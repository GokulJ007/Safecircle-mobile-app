import 'package:go_router/go_router.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/home/main_navigation_shell.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/journey/start_journey_screen.dart';
import '../screens/journey/active_journey_screen.dart';
import '../screens/journey/sos_screen.dart';
import '../screens/journey/fake_call_screen.dart';
import '../screens/history/journey_details_screen.dart';
import '../screens/contacts/contacts_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/map_screen.dart';
import '../screens/journey/place_search_screen.dart';

/// Central navigation configuration using GoRouter.
class AppRouter {
  AppRouter._();

  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String settings = '/settings';
  static const String startJourney = '/start-journey';
  static const String journey = '/journey';
  static const String sos = '/sos';
  static const String fakeCall = '/fake-call';
  static const String journeyDetails = '/journey-details/:id';
  static const String map = '/map';
  static const String placeSearch = '/place-search';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(
        path: splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: signup,
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: forgotPassword,
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: home,
        name: 'home',
        builder: (context, state) => const MainNavigationShell(),
      ),
      GoRoute(
        path: '/contacts',
        name: 'contacts_standalone',
        builder: (context, state) => const ContactsScreen(),
      ),
      GoRoute(
        path: '/history',
        name: 'history_standalone',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile_standalone',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: startJourney,
        name: 'start-journey',
        builder: (context, state) => const StartJourneyScreen(),
      ),
      GoRoute(
        path: journey,
        name: 'journey',
        builder: (context, state) => const ActiveJourneyScreen(),
      ),
      GoRoute(
        path: sos,
        name: 'sos',
        builder: (context, state) => const SosScreen(),
      ),
      GoRoute(
        path: fakeCall,
        name: 'fake-call',
        builder: (context, state) => const FakeCallScreen(),
      ),
      GoRoute(
        path: journeyDetails,
        name: 'journey-details',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return JourneyDetailsScreen(journeyId: id);
        },
      ),
      GoRoute(
        path: map,
        name: 'map',
        builder: (context, state) => const MapScreen(),
      ),
      GoRoute(
        path: placeSearch,
        name: 'place-search',
        builder: (context, state) => const PlaceSearchScreen(),
      ),
    ],
  );
}