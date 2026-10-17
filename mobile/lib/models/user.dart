import '../l10n/app_localizations.dart';

class BillingSubscription {
  const BillingSubscription({
    this.provider,
    this.productId,
    this.periodEnd,
    this.willRenew = true,
  });

  final String? provider;
  final String? productId;
  final DateTime? periodEnd;
  final bool willRenew;

  bool get fromStore =>
      provider == 'app_store' ||
      provider == 'play_store' ||
      provider == 'test_store';

  factory BillingSubscription.fromJson(Map<String, dynamic> json) {
    return BillingSubscription(
      provider: json['provider'] as String?,
      productId: json['product_id'] as String?,
      periodEnd: DateTime.tryParse(
        json['current_period_end']?.toString() ?? '',
      ),
      willRenew: json['will_renew'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'provider': provider,
    'product_id': productId,
    'current_period_end': periodEnd?.toUtc().toIso8601String(),
    'will_renew': willRenew,
  };
}

class Billing {
  const Billing({
    required this.plan,
    this.source,
    this.trialEndsAt,
    this.subscription,
    this.projectLimit,
    this.historyDays,
    this.hasLimits = false,
  });

  final String plan;
  final String? source;
  final DateTime? trialEndsAt;
  final BillingSubscription? subscription;
  final int? projectLimit;
  final int? historyDays;
  final bool hasLimits;

  bool get isPro => plan == 'pro';

  /// Trial is Pro access, but the badge should say how many trial days remain.
  String badge(AppLocalizations l10n) {
    if (source == 'trial') return l10n.planTrial(trialDaysLeft ?? 0);
    return isPro ? l10n.planPro : l10n.planFree;
  }

  int? get trialDaysLeft {
    if (source != 'trial' || trialEndsAt == null) return null;
    final hours = trialEndsAt!.difference(DateTime.now()).inHours;
    if (hours <= 0) return 0;
    return (hours / 24).ceil();
  }

  factory Billing.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const Billing(plan: 'free');
    final trial = json['trial_ends_at'] as String?;
    final sub = json['subscription'];
    final limits = json['limits'];
    return Billing(
      plan: json['plan'] as String? ?? 'free',
      source: json['source'] as String?,
      trialEndsAt: trial == null ? null : DateTime.tryParse(trial),
      subscription:
          sub is Map
              ? BillingSubscription.fromJson(sub.cast<String, dynamic>())
              : null,
      projectLimit:
          limits is Map ? (limits['projects'] as num?)?.toInt() : null,
      historyDays:
          limits is Map ? (limits['history_days'] as num?)?.toInt() : null,
      hasLimits: limits is Map,
    );
  }

  Map<String, dynamic> toJson() => {
    'plan': plan,
    'source': source,
    'trial_ends_at': trialEndsAt?.toUtc().toIso8601String(),
    if (subscription != null) 'subscription': subscription!.toJson(),
    if (hasLimits)
      'limits': {'projects': projectLimit, 'history_days': historyDays},
  };
}

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.emailVerified,
    required this.billing,
    this.hasPassword = true,
  });

  final int id;
  final String email;
  final String name;
  final bool emailVerified;
  final bool hasPassword;
  final Billing billing;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String,
      name: json['name'] as String? ?? '',
      emailVerified: json['email_verified'] as bool? ?? false,
      hasPassword: json['has_password'] as bool? ?? true,
      billing: Billing.fromJson(json['billing'] as Map<String, dynamic>?),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'email_verified': emailVerified,
    'has_password': hasPassword,
    'billing': billing.toJson(),
  };
}
