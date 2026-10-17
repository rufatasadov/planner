import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../billing/store_billing.dart';
import '../features/plan/plan_controller.dart';
import '../models/user.dart';
import 'auth_repository.dart';
import 'token_store.dart';

class Session {
  const Session({required this.user});

  final AppUser user;
}

/// A rejected token logs the user out. A network or server failure keeps the saved session.
bool isSessionRejected(int? status) => status == 401 || status == 403;

final authControllerProvider = AsyncNotifierProvider<AuthController, Session?>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<Session?> {
  var _epoch = 0;

  @override
  Future<Session?> build() async {
    final store = ref.read(tokenStoreProvider);
    final token = await store.readToken();
    if (token == null) return null;

    final cached = await store.readUser();
    if (cached != null) {
      final ticket = _epoch;
      Future<void>(() => _refresh(ticket));
      unawaited(_syncStore(cached));
      return Session(user: cached);
    }
    return _restoreFromNetwork();
  }

  Future<void> login(String email, String password) => _open(
    () => ref.read(authRepositoryProvider).login(email.trim(), password),
  );

  Future<void> register(String name, String email, String password) => _open(
    () => ref
        .read(authRepositoryProvider)
        .register(name.trim(), email.trim(), password),
  );

  Future<void> signInWithOAuth({
    required String provider,
    String? idToken,
    String? accessToken,
    String? name,
  }) => _open(
    () => ref
        .read(authRepositoryProvider)
        .oauth(
          provider: provider,
          idToken: idToken,
          accessToken: accessToken,
          name: name,
        ),
  );

  Future<void> logout() async {
    _epoch++;
    await ref.read(storeBillingProvider).logOut();
    await ref.read(tokenStoreProvider).clear();
    ref.invalidate(planControllerProvider);
    state = const AsyncData(null);
  }

  Future<void> deleteAccount({String? password, bool confirm = false}) async {
    await ref
        .read(authRepositoryProvider)
        .deleteAccount(password: password, confirm: confirm);
    await logout();
  }

  Future<void> refresh() => _refresh(_epoch);

  Future<void> _open(
    Future<({String token, AppUser user})> Function() call,
  ) async {
    final ticket = ++_epoch;
    final session = await call();
    await ref.read(tokenStoreProvider).save(session.token, session.user);
    if (ticket != _epoch) return;
    ref.invalidate(planControllerProvider);
    state = AsyncData(Session(user: session.user));
    unawaited(_syncStore(session.user));
  }

  Future<Session?> _restoreFromNetwork() async {
    try {
      final user = await ref.read(authRepositoryProvider).me();
      await ref.read(tokenStoreProvider).saveUser(user);
      unawaited(_syncStore(user));
      return Session(user: user);
    } on DioException catch (e) {
      if (isSessionRejected(e.response?.statusCode)) {
        await ref.read(tokenStoreProvider).clear();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _refresh(int ticket) async {
    try {
      final user = await ref.read(authRepositoryProvider).me();
      await ref.read(tokenStoreProvider).saveUser(user);
      if (ticket != _epoch) return;
      state = AsyncData(Session(user: user));
    } on DioException catch (e) {
      if (ticket != _epoch || !isSessionRejected(e.response?.statusCode)) {
        return;
      }
      await ref.read(tokenStoreProvider).clear();
      if (ticket != _epoch) return;
      state = const AsyncData(null);
    } catch (_) {}
  }

  Future<void> _syncStore(AppUser user) async {
    try {
      await ref.read(storeBillingProvider).identify(user.id.toString());
    } catch (_) {}
  }
}
