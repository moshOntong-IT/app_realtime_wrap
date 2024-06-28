import 'package:app_realtime_wrap/app_realtime_wrap.dart';

/// The Base class for all subscribe realtime state
sealed class SubscribeState {}

/// {@template data_subscribe_event}
/// The event for the data
/// {@endtemplate}
class DataSubscribeEvent<T> implements SubscribeState {
  /// {@macro data_subscribe_event}
  const DataSubscribeEvent(this.data);

  /// The data of the event
  final T data;
}

/// {@template error_subscribe_event}
/// The event for the error
///  {@endtemplate}
class ErrorSubscribeEvent implements SubscribeState {
  /// {@macro error_subscribe_event}
  const ErrorSubscribeEvent(this.exception);

  /// The exception of the event
  final AppRealtimeException exception;
}

/// {@template loading_subscribe_event}
/// The event for the loading
/// {@endtemplate}
class LoadingSubscribeEvent implements SubscribeState {
  /// {@macro loading_subscribe_event}
  const LoadingSubscribeEvent();
}

/// {@template refresh_subscribe_event}
/// The event for the refresh
/// {@endtemplate}
class RefreshSubscribeEvent implements SubscribeState {
  /// {@macro refresh_subscribe_event}
  const RefreshSubscribeEvent();
}

/// {@template dispose_subscribe_event}
/// The event for the dispose
/// {@endtemplate}
class DisposeSubscribeEvent implements SubscribeState {
  /// {@macro dispose_subscribe_event}
  const DisposeSubscribeEvent();
}

/// {@template connected_subscribe_event}
/// The event for the connected
/// {@endtemplate}
class ConnectedSubscribeEvent implements SubscribeState {
  /// {@macro connected_subscribe_event}
  const ConnectedSubscribeEvent();
}
