import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/profile/presentation/providers/profile_providers.dart';

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  StreamSubscription? _authSubscription;
  StreamSubscription? _profileSubscription;

  RouterNotifier(this._ref) {
    _authSubscription = _ref.listen(authStateProvider.stream, (previous, next) {
      notifyListeners();
    });

    _profileSubscription = _ref.listen(userProfileProvider.stream, (previous, next) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _profileSubscription?.cancel();
    super.dispose();
  }
}
