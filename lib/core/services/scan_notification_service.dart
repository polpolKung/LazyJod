import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Manages scan progress & completion local notifications.
///
/// Shows an ongoing (non-dismissible) notification while scanning so Android
/// keeps the app alive in the background.  Dismisses automatically when
/// scanning finishes and replaces it with a tappable summary.
class ScanNotificationService {
  ScanNotificationService._();
  static final ScanNotificationService instance = ScanNotificationService._();

  static const int _progressId = 1001;
  static const int _doneId = 1002;
  static const String _channelId = 'lazyjod_scan';
  static const String _channelName = 'สแกนสลิป';
  static const String _channelDesc = 'แจ้งความคืบหน้าการสแกนสลิปธนาคาร';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Explicitly create notification channel with high importance
    final channel = const AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
      playSound: false,
      enableVibration: false,
      showBadge: true,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  /// Request runtime notification permission (Android 13+).
  Future<void> requestPermission() async {
    await _ensureInit();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  /// Show/update ongoing progress notification.
  Future<void> showProgress({
    required int current,
    required int total,
    required int foundSoFar,
  }) async {
    await _ensureInit();
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,          // non-dismissible while scanning
      showProgress: true,
      maxProgress: total,
      progress: current,
      onlyAlertOnce: true,    // don't sound/vibrate on every tick
      icon: '@mipmap/ic_launcher',
      channelShowBadge: true,
    );
    final details = NotificationDetails(android: androidDetails);
    await _plugin.show(
      _progressId,
      'Lazy Jod กำลังสแกนสลิปให้...',
      'กำลังสแกน $current/$total  •  พบสลิปแล้ว $foundSoFar รายการ',
      details,
    );
  }

  /// Dismiss the progress notification and show a tappable completion banner.
  Future<void> showDone({
    required int total,
    required int found,
  }) async {
    await _ensureInit();
    // Cancel the ongoing progress notification first
    await _plugin.cancel(_progressId);

    if (found == 0) return; // no notification if nothing found

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      autoCancel: true,
      icon: '@mipmap/ic_launcher',
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(
      _doneId,
      'สแกนเสร็จแล้ว! 🎉',
      'ตรวจ $total รูป พบสลิป $found รายการ — แตะเพื่อดูผล',
      details,
    );
  }

  /// Cancel all scan-related notifications (e.g. on explicit cancel).
  Future<void> cancelAll() async {
    await _ensureInit();
    await _plugin.cancel(_progressId);
    await _plugin.cancel(_doneId);
  }

  Future<void> _ensureInit() async {
    if (!_initialized) await init();
  }
}
