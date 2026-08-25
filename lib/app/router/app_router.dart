import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/screens/access_denied_screen.dart';
import '../../features/auth/presentation/screens/email_verification_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/profile_loading_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/guard/presentation/screens/guard_home_screen.dart';
import '../../features/identity/domain/entities/user_profile.dart';
import '../../features/identity/presentation/providers/identity_providers.dart';
import '../../features/identity/presentation/screens/profile_screen.dart';
import '../../features/identity/presentation/screens/profile_setup_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/supervisor/presentation/screens/supervisor_dashboard_screen.dart';
import '../../features/admin/presentation/screens/guards/guard_list_screen.dart';
import '../../features/admin/presentation/screens/guards/guard_details_screen.dart';
import '../../features/admin/presentation/screens/guards/guard_form_screen.dart';
import '../../features/guards/domain/entities/guard.dart';
import '../navigation_shell.dart';
import 'router_notifier.dart';

abstract class AppRoutes {
  static const String initial = '/';
  static const String loading = '/loading';
  static const String accessDenied = '/access-denied';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verifyEmail = '/verify-email';
  static const String profileSetup = '/profile-setup';

  static const String adminDashboard = '/admin/dashboard';
  static const String adminGuards = '/admin/guards';
  static const String adminGuardDetails = '/admin/guards/details';
  static const String adminGuardCreate = '/admin/guards/create';
  static const String adminGuardEdit = '/admin/guards/edit';
  
  static const String supervisorDashboard = '/supervisor/dashboard';
  static const String guardHome = '/guard/home';

  static const String shift = '/guard/shift';
  static const String checkIn = '/guard/check-in';
  static const String incidents = '/guard/incidents';
  static const String profile = '/guard/profile';
}

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouterProvider = Provider<GoRouter>((ref) {
  final routerNotifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.initial,
    refreshListenable: routerNotifier,
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authStateProvider);

      if (authState.isLoading) {
        if (state.uri.path == AppRoutes.initial ||
            state.uri.path == AppRoutes.loading) {
          return null;
        }
        return AppRoutes.loading;
      }

      final authUser = authState.asData?.value;

      final isAuthRoute = [
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
        AppRoutes.verifyEmail,
      ].contains(state.uri.path);

      if (authUser == null) {
        if (!isAuthRoute) {
          return AppRoutes.login;
        }
        return null;
      }

      final profileControllerState = ref.read(profileControllerProvider);
      final profileFromController = profileControllerState.asData?.value;
      final currentUserProfileState = ref.read(currentUserProfileProvider);

      if (currentUserProfileState.isLoading && profileFromController == null) {
        if (state.uri.path == AppRoutes.loading) return null;
        return AppRoutes.loading;
      }

      final profile =
          profileFromController ?? currentUserProfileState.asData?.value;

      if (profile == null) {
        if (state.uri.path == AppRoutes.profileSetup) return null;
        return AppRoutes.profileSetup;
      }

      if (profile.status != UserStatus.active) {
        if (state.uri.path == AppRoutes.accessDenied) return null;
        return AppRoutes.accessDenied;
      }

      final role = profile.role;

      final isEntryRoute = isAuthRoute ||
          state.uri.path == AppRoutes.initial ||
          state.uri.path == AppRoutes.loading ||
          state.uri.path == AppRoutes.profileSetup;

      String allowedBasePath = '';
      String roleHome = '';
      if (role == UserRole.admin) {
        allowedBasePath = '/admin';
        roleHome = AppRoutes.adminDashboard;
      } else if (role == UserRole.supervisor) {
        allowedBasePath = '/supervisor';
        roleHome = AppRoutes.supervisorDashboard;
      } else if (role == UserRole.guard) {
        allowedBasePath = '/guard';
        roleHome = AppRoutes.guardHome;
      }

      if (isEntryRoute) {
        return roleHome;
      }

      if (!state.uri.path.startsWith(allowedBasePath) &&
          state.uri.path != AppRoutes.accessDenied) {
        return roleHome;
      }

      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.initial,
        builder: (BuildContext context, GoRouterState state) =>
            const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.loading,
        builder: (BuildContext context, GoRouterState state) =>
            const ProfileLoadingScreen(),
      ),
      GoRoute(
        path: AppRoutes.accessDenied,
        builder: (BuildContext context, GoRouterState state) =>
            const AccessDeniedScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (BuildContext context, GoRouterState state) =>
            const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (BuildContext context, GoRouterState state) =>
            const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (BuildContext context, GoRouterState state) =>
            const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (BuildContext context, GoRouterState state) =>
            const EmailVerificationScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileSetup,
        builder: (BuildContext context, GoRouterState state) =>
            const ProfileSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (BuildContext context, GoRouterState state) =>
            const AdminDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminGuards,
        builder: (BuildContext context, GoRouterState state) =>
            const GuardListScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminGuardDetails,
        builder: (BuildContext context, GoRouterState state) {
          final guard = state.extra as Guard;
          return GuardDetailsScreen(guard: guard);
        },
      ),
      GoRoute(
        path: AppRoutes.adminGuardCreate,
        builder: (BuildContext context, GoRouterState state) =>
            const GuardFormScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminGuardEdit,
        builder: (BuildContext context, GoRouterState state) {
          final guard = state.extra as Guard;
          return GuardFormScreen(existingGuard: guard);
        },
      ),
      GoRoute(
        path: AppRoutes.supervisorDashboard,
        builder: (BuildContext context, GoRouterState state) =>
            const SupervisorDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.guardHome,
        builder: (BuildContext context, GoRouterState state) =>
            const GuardHomeScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (
          BuildContext context,
          GoRouterState state,
          StatefulNavigationShell navigationShell,
        ) {
          return NavigationShell(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.shift,
                builder: (BuildContext context, GoRouterState state) =>
                    const PlaceholderPage(
                  title: 'Shift',
                  icon: Icons.shield_outlined,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.checkIn,
                builder: (BuildContext context, GoRouterState state) =>
                    const PlaceholderPage(
                  title: 'Check-In',
                  icon: Icons.location_on_outlined,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.incidents,
                builder: (BuildContext context, GoRouterState state) =>
                    const PlaceholderPage(
                  title: 'Incidents',
                  icon: Icons.warning_amber_outlined,
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.profile,
                builder: (BuildContext context, GoRouterState state) =>
                    const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
