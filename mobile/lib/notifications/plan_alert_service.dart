import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../features/plan/plan_repository.dart';
import '../features/plan/plan_time.dart';
import '../l10n/app_localizations.dart';
import 'plan_alerts.dart';

final planAlertServiceProvider = Provider<PlanAlertService>((ref) {
  return PlanAlertService(FlutterLocalNotificationsPlugin());
});

class PlanAlertService {
  PlanAlertService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;
  var _ready = false;
  var _asked = false;

  Future<void> sync(PlanRepository repo, Locale locale) async {
    try {
      final now = DateTime.now();
      final day = await repo.range(
        ymd(now),
        ymd(now.add(const Duration(hours: 24))),
      );
      final hours = await repo.hours();
      final l10n = lookupAppLocalizations(locale);
      final alerts = planAlerts(
        plans: day.plans,
        notifyBeforeMin: hours.notifyBeforeMin,
        now: now,
        startTitle: l10n.notifyStartTitle,
        endTitle: l10n.notifyEndTitle,
        body: l10n.notifyBody,
        nextLine: l10n.notifyNext,
      );
      await replace(alerts, channelName: l10n.notifyChannel);
    } catch (_) {}
  }

  Future<void> clear() async {
    try {
      await _ensureReady();
      await _plugin.cancelAll();
    } catch (_) {}
  }

  Future<void> replace(
    List<PlanAlert> alerts, {
    required String channelName,
  }) async {
    await _ensureReady();
    await _askOnce();
    await _plugin.cancelAll();
    final mode = await _scheduleMode();
    for (final alert in alerts) {
      await _schedule(alert, channelName, mode);
    }
  }

  Future<void> _schedule(
    PlanAlert alert,
    String channelName,
    AndroidScheduleMode mode,
  ) async {
    final when = tz.TZDateTime.from(alert.when, tz.local);
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'plans',
        channelName,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );
    try {
      await _plugin.zonedSchedule(
        alert.id,
        alert.title,
        alert.body,
        when,
        details,
        androidScheduleMode: mode,
      );
    } catch (_) {
      if (mode == AndroidScheduleMode.inexactAllowWhileIdle) return;
      await _plugin.zonedSchedule(
        alert.id,
        alert.title,
        alert.body,
        when,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<AndroidScheduleMode> _scheduleMode() async {
    final android =
        _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    final exact = await android?.canScheduleExactNotifications();
    if (exact == false) return AndroidScheduleMode.inexactAllowWhileIdle;
    return AndroidScheduleMode.exactAllowWhileIdle;
  }

  Future<void> _askOnce() async {
    if (_asked) return;
    _asked = true;
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: false, sound: true);
  }

  Future<void> _ensureReady() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _ready = true;
  }
}
