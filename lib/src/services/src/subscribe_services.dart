import 'dart:async';

import 'package:app_realtime_wrap/app_realtime_wrap.dart';
import 'package:appwrite/appwrite.dart';

/// The factory function to create a subscribe service
SubscribeServicesBase<T> createService<T>({
  required int staleTimeout,
  required Realtime realtime,
}) =>
    SubscribeServicesIO<T>(
      realtime: realtime,
      staleTimeout: staleTimeout,
    );

/// {@template subscribe_service_interface}
/// The interface for all subscribe services
/// {@endtemplate}
sealed class SubscribeService<T> {
  factory SubscribeService({
    required int staleTimeout,
    required Realtime realtime,
  }) =>
      createService(
        staleTimeout: staleTimeout,
        realtime: realtime,
      );

  /// To subscribe to a channel
  SubscribeRealtime<T> subscribe({
    required List<String> channels,
  });
}

/// The base class for all subscribe services
sealed class SubscribeServicesBase<T> implements SubscribeService<T> {
  @override
  SubscribeRealtime<T> subscribe({required List<String> channels});
}

/// {@template subscribe_services_io}
/// The SubscribeServices for IO
/// {@endtemplate}
class SubscribeServicesIO<T> extends SubscribeServicesBase<T> {
  /// The SubscribeServices for IO
  SubscribeServicesIO({
    required this.staleTimeout,
    required this.realtime,
  });

  /// The timeout for stale data
  final int staleTimeout;

  /// The realtime instance
  final Realtime realtime;

  StreamController<RealtimeMessage>? _subscriptionController;

  RealtimeSubscription? _realtimeSubscription;
  Timer? _reconnectTimer;
  Timer? _staleTimer;

  bool _isConnected = false;

  @override
  SubscribeRealtime<T> subscribe({required List<String> channels}) {
    _connect(channels);
    return SubscribeRealtime(
      onDispose: () {
        _realtimeSubscription?.close();
        _subscriptionController?.close();
        _reconnectTimer?.cancel();
        _staleTimer?.cancel();
      },
      subscription: _subscriptionController!.stream.map((event) {
        return SubscribeRealtimeData(
          data: event,
          type: SubscribeRealtimeType.fromString(event.events.first),
        );
      }),
    );
  }

  void _connect(List<String> channels) {
    _realtimeSubscription?.close();
    _realtimeSubscription = realtime.subscribe(channels);

    _realtimeSubscription!.stream.listen(
      (event) {
        _isConnected = true;
        _reconnectTimer?.cancel();
        _resetStaleTimer(channels);
        _subscriptionController!.add(event);
      },
      onError: (error) {
        _isConnected = false;
        _startReconnectTimer(channels);
      },
      onDone: () {
        _isConnected = false;
        _startReconnectTimer(channels);
      },
    );

    _startReconnectTimer(channels);
    _resetStaleTimer(channels);
  }

  void _startReconnectTimer(List<String> channels) {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: staleTimeout), () {
      if (!_isConnected) {
        _connect(channels);
      }
    });
  }

  void _resetStaleTimer(List<String> channels) {
    _staleTimer?.cancel();
    _staleTimer = Timer(Duration(milliseconds: staleTimeout), () {
      if (_isConnected) {
        _isConnected = false;
        _connect(channels);
      }
    });
  }
}
