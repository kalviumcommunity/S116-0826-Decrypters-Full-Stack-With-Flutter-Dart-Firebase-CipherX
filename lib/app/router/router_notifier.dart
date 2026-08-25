import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/identity/presentation/providers/identity_providers.dart';

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (previous, next) {
      notifyListeners();
    });

    _ref.listen(currentUserProfileProvider, (previous, next) {
      notifyListeners();
    });

    _ref.listen(profileControllerProvider, (previous, next) {
      notifyListeners();
    });
  }
}
