import "dart:async";
import "dart:io" show NetworkInterface, InternetAddressType;

import "package:flutter/foundation.dart" show kIsWeb;
import "package:flutter/material.dart";
import "package:internet_connection_checker_plus/internet_connection_checker_plus.dart"
    hide InternetStatus;

enum ConnectionStateStatus {
  connected, // متصل
  noAccess, // فاتح الواي فاي بس مفيش نت
  disconnected, // الواي فاي و الداتا مقفولين
}

Future<bool> get internetIsConnected async =>
    await InternetCheckerService.instance.checkInternetConnection() ==
    ConnectionStateStatus.connected;

class InternetCheckerService {
  final InternetConnection _checker;
  StreamSubscription<dynamic>? _subscription;

  static final InternetCheckerService instance =
      InternetCheckerService._internal();

  factory InternetCheckerService() => instance;

  InternetCheckerService._internal({InternetConnection? checker})
    : _checker = checker ?? InternetConnection() {
    _init();
  }

  /// الـ ValueNotifier اللي شايل الحالة الحالية
  final ValueNotifier<ConnectionStateStatus> statusNotifier = ValueNotifier(
    ConnectionStateStatus.connected,
  );

  void _init() async {
    await checkInternetConnection();

    _subscription = _checker.onStatusChange.listen((_) async {
      await checkInternetConnection();
    });
  }

  /// دالة فحص وتحديث الحالة الحالية
  /// بتفرّق بين noAccess و disconnected عن طريق فحص الهارد وير فعليًا
  /// (هل في واي فاي/داتا مفتوحة أصلاً ولا لأ) مش بس بيانات الباكدج
  Future<ConnectionStateStatus> checkInternetConnection() async {
    final bool hasAccess = await _checker.hasInternetAccess;

    if (hasAccess) {
      statusNotifier.value = ConnectionStateStatus.connected;
      return ConnectionStateStatus.connected;
    }

    final ConnectionStateStatus result = await _resolveNoAccessReason();
    statusNotifier.value = result;
    return result;
  }

  Future<ConnectionStateStatus> _resolveNoAccessReason() async {
    if (kIsWeb) {
      // مش قادرين نفحص NetworkInterface على الويب
      return ConnectionStateStatus.noAccess;
    }

    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        type: InternetAddressType.any,
      );
      return interfaces.isNotEmpty
          ? ConnectionStateStatus.noAccess
          : ConnectionStateStatus.disconnected;
    } catch (_) {
      return ConnectionStateStatus.disconnected;
    }
  }

  void dispose() {
    _subscription?.cancel();
    statusNotifier.dispose();
  }
}

/// Extension لتسهيل الاستماع لتغيرات الإنترنت من الـ UI مباشرة
/// بدون أي حاجة تانية - استخدم زي كذا:
/// MyWidget().listenToInternet(onChange: (context, status) { ... })
extension InternetListenerExtension on Widget {
  Widget listenToInternet({
    InternetCheckerService? service,
    required void Function(BuildContext context, ConnectionStateStatus status)
    onChange,
  }) {
    final targetService = service ?? InternetCheckerService.instance;

    return _InternetListenerWidget(
      service: targetService,
      onChange: onChange,
      child: this,
    );
  }
}

class _InternetListenerWidget extends StatefulWidget {
  final InternetCheckerService service;
  final void Function(BuildContext context, ConnectionStateStatus status)
  onChange;
  final Widget child;

  const _InternetListenerWidget({
    required this.service,
    required this.onChange,
    required this.child,
  });

  @override
  State<_InternetListenerWidget> createState() =>
      _InternetListenerWidgetState();
}

class _InternetListenerWidgetState extends State<_InternetListenerWidget> {
  ConnectionStateStatus? _previousStatus;

  @override
  void initState() {
    super.initState();
    _previousStatus = widget.service.statusNotifier.value;
    widget.service.statusNotifier.addListener(_handleStatusChange);
  }

  void _handleStatusChange() {
    final newStatus = widget.service.statusNotifier.value;
    if (_previousStatus != newStatus) {
      _previousStatus = newStatus;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onChange(context, newStatus);
        }
      });
    }
  }

  @override
  void dispose() {
    widget.service.statusNotifier.removeListener(_handleStatusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
