import 'dart:async';

import 'package:app_realtime_wrap/app_realtime_wrap.dart';
import 'package:appwrite/appwrite.dart';

/// The typedef of callback on subscribing the state
typedef SubscribeStateCallback = void Function(Stream<SubscribeState> state);

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
    required SubscribeStateCallback stateListen,
  });
}

/// The base class for all subscribe services
sealed class SubscribeServicesBase<T> implements SubscribeService<T> {
  @override
  SubscribeRealtime<T> subscribe({
    required List<String> channels,
    required SubscribeStateCallback stateListen,
  });
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
  Realtime realtime;

  /// A callback that is that the subscribe is going to refresh

  final StreamController<SubscribeState> _subscriptionStateController =
      StreamController.broadcast();

  RealtimeSubscription? _realtimeSubscription;

  Timer? _staleTimer;

  bool _isConnected = false;

  /// Indicator if the subscription is going to refresh
  bool _isRefreshing = false;

  @override
  SubscribeRealtime<T> subscribe({
    required List<String> channels,
    required SubscribeStateCallback stateListen,
  }) {
    stateListen.call(_subscriptionStateController.stream);

    _connect(realtime: realtime, channels: channels);

    AppRealtimeWrap.instance.realtime.addListener(_realtimeInstanceListener);
    return SubscribeRealtime(
      onDispose: () {
        _subscriptionStateController.add(const DisposeSubscribeEvent());
        _realtimeSubscription?.close();
        _subscriptionStateController.close();
        _staleTimer?.cancel();
        AppRealtimeWrap.instance.realtime
            .removeListener(_realtimeInstanceListener);

        _realtimeSubscription = null;
        _staleTimer = null;
      },
      // subscription: _subscriptionStateController.stream.map((event) {
      //   return SubscribeRealtimeData(
      //     data: event,
      //     type: SubscribeRealtimeType.fromString(event.events.first),
      //   );
      // }),
    );
  }

  void _realtimeInstanceListener() {
    _connect(
      realtime: AppRealtimeWrap.instance.realtime.value!,
      channels: _realtimeSubscription!.channels,
    );
  }

  void _connect({required Realtime realtime, required List<String> channels}) {
    if (!_isRefreshing) {
      _subscriptionStateController.add(const LoadingSubscribeEvent());
    }
    _isRefreshing = false;
    _realtimeSubscription?.close();
    _realtimeSubscription = realtime.subscribe(channels);

    _subscriptionStateController.add(const ConnectedSubscribeEvent());
    _isConnected = true;
    _realtimeSubscription!.stream.listen(
      (event) {
        _resetStaleTimer();
        _subscriptionStateController.add(
          DataSubscribeEvent(
            SubscribeRealtimeData(
              data: event,
              type: SubscribeRealtimeType.fromString(event.events.first),
            ),
          ),
        );
      },
      onError: (Object error) {
        final exception = AppRealtimeException(
          message: 'Error subscribing to realtime',
          error: error,
          stackTrace: StackTrace.current,
        );
        _subscriptionStateController.add(ErrorSubscribeEvent(exception));
        _isConnected = false;
      },
      onDone: () {
        if (_isRefreshing == true && _isConnected == true) {
          _isConnected = false;
          _connect(
            realtime: AppRealtimeWrap.instance.realtime.value!,
            channels: channels,
          );

          return;
        }
        _isConnected = false;
      },
    );

    _resetStaleTimer();
  }

  void _resetStaleTimer() {
    _staleTimer?.cancel();
    _staleTimer = Timer(Duration(seconds: staleTimeout), () {
      if (_isConnected) {
        _isRefreshing = true;
        _subscriptionStateController.add(const RefreshSubscribeEvent());
        _realtimeSubscription?.close();
        _realtimeSubscription = null;
      }
    });
  }
}
