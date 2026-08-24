import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/email_verification_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/identity/presentation/screens/profile_screen.dart';
import '../../features/identity/presentation/screens/profile_setup_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../navigation_shell.dart';

abstract class AppRoutes {
  static const String initial = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verifyEmail = '/verify-email';
  static const String profileSetup = '/profile-setup';
  static const String profile = '/profile';
  static const String shift = '/guard/today-shift';
  static const String checkIn = '/guard/check-in';
  static const String incidents = '/guard/incidents';
}

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.initial,
  routes: <RouteBase>[
    GoRoute(
      path: AppRoutes.initial,
      builder: (BuildContext context, GoRouterState state) {
        return const SplashScreen();
      },
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (BuildContext context, GoRouterState state) {
        return const LoginScreen();
      },
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (BuildContext context, GoRouterState state) {
        return const RegisterScreen();
      },
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      builder: (BuildContext context, GoRouterState state) {
        return const ForgotPasswordScreen();
      },
    ),
    GoRoute(
      path: AppRoutes.verifyEmail,
      builder: (BuildContext context, GoRouterState state) {
        return const EmailVerificationScreen();
      },
    ),
    GoRoute(
      path: AppRoutes.profileSetup,
      builder: (BuildContext context, GoRouterState state) {
        return const ProfileSetupScreen();
      },
    ),
    GoRoute(
      path: AppRoutes.profile,
      builder: (BuildContext context, GoRouterState state) {
        return const ProfileScreen();
      },
    ),
    StatefulShellRoute.indexedStack(
      builder: (BuildContext context, GoRouterState state,
          StatefulNavigationShell navigationShell) {
        return NavigationShell(navigationShell: navigationShell);
      },
      branches: <StatefulShellBranch>[
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: AppRoutes.shift,
              builder: (BuildContext context, GoRouterState state) =>
                  const PlaceholderPage(
                      title: 'Shift', icon: Icons.shield_outlined),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: AppRoutes.checkIn,
              builder: (BuildContext context, GoRouterState state) =>
                  const PlaceholderPage(
                      title: 'Check-In', icon: Icons.location_on_outlined),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: AppRoutes.incidents,
              builder: (BuildContext context, GoRouterState state) =>
                  const PlaceholderPage(
                      title: 'Incidents', icon: Icons.warning_amber_outlined),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/guard/profile',
              builder: (BuildContext context, GoRouterState state) =>
                  const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
