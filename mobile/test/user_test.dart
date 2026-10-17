import 'package:flutter_test/flutter_test.dart';
import 'package:onelineplanner/auth/auth_controller.dart';
import 'package:onelineplanner/models/user.dart';

void main() {
  test('parses the /auth/me user and a live trial', () {
    final user = AppUser.fromJson({
      'id': 7,
      'email': 'a@b.co',
      'name': 'Ada',
      'email_verified': false,
      'billing': {
        'plan': 'pro',
        'source': 'trial',
        'trial_ends_at':
            DateTime.now()
                .add(const Duration(days: 9, hours: 2))
                .toIso8601String(),
      },
    });
    expect(user.emailVerified, isFalse);
    expect(user.billing.isPro, isTrue);
    expect(user.billing.trialDaysLeft, 10);
  });

  test('a saved user round-trips and an expired token is the only logout', () {
    final user =
        AppUser.fromJson({'id': 3, 'email': 'a@b.co', 'name': 'A'}).toJson();
    expect(AppUser.fromJson(user).email, 'a@b.co');
    expect(isSessionRejected(401), isTrue);
    expect(isSessionRejected(403), isTrue);
    expect(isSessionRejected(500), isFalse);
    expect(isSessionRejected(null), isFalse);
  });

  test('a missing billing block is the Free plan', () {
    final user = AppUser.fromJson({'id': 1, 'email': 'a@b.co', 'name': 'A'});
    expect(user.billing.plan, 'free');
    expect(user.billing.trialDaysLeft, isNull);
  });
}
