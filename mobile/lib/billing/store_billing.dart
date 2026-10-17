import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../config.dart';

final storeBillingProvider = Provider<StoreBilling>((ref) => StoreBilling());

class StoreOffer {
  const StoreOffer({
    required this.productId,
    required this.price,
    required this.package,
  });

  /// `pro_monthly` or `pro_yearly`. The price string always comes from the store.
  final String productId;
  final String price;
  final Package package;
}

enum StorePurchaseResult { purchased, cancelled, failed }

class StoreBilling {
  Future<void> _tail = Future<void>.value();
  var _ready = false;
  String? _userId;

  bool get enabled {
    if (kIsWeb) return false;
    return _key.isNotEmpty;
  }

  String get _key {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return revenueCatAppleKey;
      case TargetPlatform.android:
        return revenueCatGoogleKey;
      default:
        return '';
    }
  }

  Future<T> _queue<T>(Future<T> Function() action) {
    final run = _tail.then((_) => action());
    _tail = run.then((_) {}, onError: (_) {});
    return run;
  }

  Future<void> identify(String userId) {
    return _queue(() async {
      if (!enabled || userId.isEmpty) return;
      if (!_ready) {
        final configuration = PurchasesConfiguration(_key)..appUserID = userId;
        await Purchases.configure(configuration);
        _ready = true;
        _userId = userId;
        return;
      }
      if (_userId == userId) return;
      await Purchases.logIn(userId);
      _userId = userId;
    });
  }

  Future<void> logOut() {
    return _queue(() async {
      if (!_ready) return;
      try {
        await Purchases.logOut();
      } catch (_) {}
      _userId = null;
    });
  }

  Future<List<StoreOffer>> offers() {
    return _queue(() async {
      if (!enabled) return [];
      if (!_ready) {
        await Purchases.configure(PurchasesConfiguration(_key));
        _ready = true;
      }
      final offerings = await Purchases.getOfferings();
      final offers = <StoreOffer>[];
      for (final package in offerings.current?.availablePackages ?? const []) {
        final id = _productId(package);
        if (id == null) continue;
        offers.add(
          StoreOffer(
            productId: id,
            price: package.storeProduct.priceString,
            package: package,
          ),
        );
      }
      offers.sort((a, b) {
        if (a.productId == b.productId) return 0;
        return a.productId == 'pro_monthly' ? -1 : 1;
      });
      return offers;
    });
  }

  Future<StorePurchaseResult> buy(StoreOffer offer) {
    return _queue(() async {
      try {
        await Purchases.purchase(PurchaseParams.package(offer.package));
        return StorePurchaseResult.purchased;
      } on PlatformException catch (error) {
        if (_cancelled(error)) return StorePurchaseResult.cancelled;
        return StorePurchaseResult.failed;
      }
    });
  }

  Future<StorePurchaseResult> restore() {
    return _queue(() async {
      try {
        await Purchases.restorePurchases();
        return StorePurchaseResult.purchased;
      } on PlatformException catch (error) {
        if (_cancelled(error)) return StorePurchaseResult.cancelled;
        return StorePurchaseResult.failed;
      }
    });
  }

  String? _productId(Package package) {
    final raw =
        '${package.storeProduct.identifier} ${package.identifier}'
            .toLowerCase();
    if (raw.contains('year') ||
        raw.contains('annual') ||
        package.packageType == PackageType.annual) {
      return 'pro_yearly';
    }
    if (raw.contains('month') || package.packageType == PackageType.monthly) {
      return 'pro_monthly';
    }
    return null;
  }

  bool _cancelled(PlatformException error) {
    try {
      return PurchasesErrorHelper.getErrorCode(error) ==
          PurchasesErrorCode.purchaseCancelledError;
    } catch (_) {
      return false;
    }
  }
}
