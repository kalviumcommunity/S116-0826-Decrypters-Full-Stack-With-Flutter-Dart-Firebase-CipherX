import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/firebase_auth_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/failures/auth_failure.dart';
import '../../domain/repositories/auth_repository.dart';

final firebaseAuthDataSourceProvider = Provider<FirebaseAuthDataSource>((ref) {
  return FirebaseAuthDataSource();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dataSource = ref.watch(firebaseAuthDataSourceProvider);
  return AuthRepositoryImpl(dataSource: dataSource);
});

final authStateProvider = StreamProvider<AuthUser?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(const AsyncValue.data(null));

  Future<bool> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      await _repository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      if (e is AuthFailure) {
        state = AsyncValue.error(e, st);
      } else {
        state = AsyncValue.error(UnknownAuthFailure(e.toString()), st);
      }
      return false;
    }
  }

  Future<bool> signUp({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      await _repository.signUpWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      if (e is AuthFailure) {
        state = AsyncValue.error(e, st);
      } else {
        state = AsyncValue.error(UnknownAuthFailure(e.toString()), st);
      }
      return false;
    }
  }

  Future<bool> sendPasswordResetEmail({required String email}) async {
    state = const AsyncValue.loading();
    try {
      await _repository.sendPasswordResetEmail(email: email);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      if (e is AuthFailure) {
        state = AsyncValue.error(e, st);
      } else {
        state = AsyncValue.error(UnknownAuthFailure(e.toString()), st);
      }
      return false;
    }
  }

  Future<bool> sendEmailVerification() async {
    state = const AsyncValue.loading();
    try {
      await _repository.sendEmailVerification();
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      if (e is AuthFailure) {
        state = AsyncValue.error(e, st);
      } else {
        state = AsyncValue.error(UnknownAuthFailure(e.toString()), st);
      }
      return false;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _repository.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      if (e is AuthFailure) {
        state = AsyncValue.error(e, st);
      } else {
        state = AsyncValue.error(UnknownAuthFailure(e.toString()), st);
      }
    }
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthController(repository);
});
