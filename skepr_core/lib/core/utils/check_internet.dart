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

const Duration kInternetCheckInterval = Duration(seconds: 30);

const Duration kInternetCheckMemoDuration = Duration(seconds: 1);

Future<bool> get internetIsConnected async =>
    await InternetCheckerService.instance.checkInternetConnection() ==
    ConnectionStateStatus.connected;

class InternetCheckerService with WidgetsBindingObserver {
  final InternetConnection _checker;
  StreamSubscription<dynamic>? _subscription;

  bool _isForeground = true;
  bool _observerRegistered = false;
  DateTime? _lastCheckAt;
  ConnectionStateStatus? _lastResult;

  static final InternetCheckerService instance =
      InternetCheckerService._internal();

  factory InternetCheckerService() => instance;

  InternetCheckerService._internal({InternetConnection? checker})
    : _checker = checker ?? _createDefaultChecker() {
    _init();
  }

  static InternetConnection _createDefaultChecker() {
    return InternetConnection.createInstance(
      checkInterval: kInternetCheckInterval,
    );
  }

  final ValueNotifier<ConnectionStateStatus> statusNotifier = ValueNotifier(
    ConnectionStateStatus.connected,
  );

  void _init() {
    _ensureObserver();
    unawaited(checkInternetConnection(force: true));
    _startPolling();
  }

  void _ensureObserver() {
    if (_observerRegistered) return;
    try {
      WidgetsBinding.instance.addObserver(this);
      _observerRegistered = true;
    } catch (e) {
      debugPrint("[Internet] lifecycle observer unavailable: $e");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isForeground = true;
      _startPolling();
      unawaited(checkInternetConnection(force: true));
      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _isForeground = false;
      _stopPolling();
    }
  }

  void _startPolling() {
    if (!_isForeground || _subscription != null) return;
    _subscription = _checker.onStatusChange.listen((_) {
      unawaited(checkInternetConnection(force: true));
    });
  }

  void _stopPolling() {
    _subscription?.cancel();
    _subscription = null;
  }

  Future<ConnectionStateStatus> checkInternetConnection({
    bool force = false,
  }) async {
    _ensureObserver();

    final lastAt = _lastCheckAt;
    final lastResult = _lastResult;
    if (!force &&
        lastResult != null &&
        lastAt != null &&
        DateTime.now().difference(lastAt) < kInternetCheckMemoDuration) {
      return lastResult;
    }

    final bool hasAccess = await _checker.hasInternetAccess;
    final ConnectionStateStatus result = hasAccess
        ? ConnectionStateStatus.connected
        : await _resolveNoAccessReason();

    _lastCheckAt = DateTime.now();
    _lastResult = result;
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
    _stopPolling();
    if (_observerRegistered) {
      try {
        WidgetsBinding.instance.removeObserver(this);
      } catch (_) {}
      _observerRegistered = false;
    }
    statusNotifier.dispose();
  }
}

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
