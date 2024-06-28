import 'dart:async';
import 'dart:io';

import 'package:app_realtime_wrap/app_realtime_wrap.dart';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// {@template app_realtime_wrap}
/// A package to extend Appwrite Realtime
/// {@endtemplate}
class AppRealtimeWrap {
  /// {@macro app_realtime_wrap}
  AppRealtimeWrap._();

  static final Logger _logger = Logger('AppRealtimeWrap');

  static final AppRealtimeWrap _instance = AppRealtimeWrap._();

  /// Returns the instance of AppRealtimeWrap
  static AppRealtimeWrap get instance => _instance;

  /// The Realtime instance from Appwrite
  final ValueNotifier<Realtime?> _realtime = ValueNotifier<Realtime?>(null);

  /// Getter for the Realtime instance
  ValueNotifier<Realtime?> get realtime => _realtime;

  /// The StreamController for catching the errors
  final StreamController<AppRealtimeException> _errorController =
      StreamController<AppRealtimeException>.broadcast();

  /// the StreamSubscription for the error controller
  late final Stream<AppRealtimeException> errorListen = _errorController.stream;

  /// The stale timeout for the Realtime if the connection is lost. If we
  /// encounter a stale connection, we will try to reconnect to the Realtime
  late int _staleTimeout;

  /// The flag to check if the Realtime is initialized
  bool _isInitialized = false;

  /// The flag to check if the `AppRealtimeWrap` is disposed
  bool _isDisposed = false;

  /// Indicate that the Realtime has error so you cannot subscribe to
  /// the Realtime
  bool _hasError = false;

  /// Initializes the Realtime instance
  Future<void> initialize({
    required Client client,
    int reconnectMaxAttempts = 5,
    int reconnectDelay = 5,
    int staleTimeout = 300,
    void Function(AppRealtimeException exception)? onError,
  }) async {
    if (_isDisposed) {
      throw AppRealtimeException(
        message: 'AppRealtimeWrap is already disposed',
        error: 'AppRealtimeWrap is already disposed',
        stackTrace: StackTrace.current,
      );
    }

    if (_isInitialized) {
      throw AppRealtimeException(
        message: 'AppRealtimeWrap is already initialized',
        error: 'AppRealtimeWrap is already initialized',
        stackTrace: StackTrace.current,
      );
    }

    _logger.info('Initializing AppRealtimeWrap');

    try {
      _staleTimeout = staleTimeout;
      final instance = Realtime(client);
      _realtime.value = instance;
    } catch (e) {
      _errorController.add(
        AppRealtimeException(
          message: 'Error initializing AppRealtimeWrap',
          error: e,
          stackTrace: StackTrace.current,
        ),
      );
      if (e is WebSocketException) {
        _logger.severe('Error initializing AppRealtimeWrap');
        await _reconnect(
          client,
          reconnectMaxAttempts: reconnectMaxAttempts,
          reconnectDelay: reconnectDelay,
          onFailReconnect: (exception) {
            _hasError = true;
            onError?.call(
              exception,
            );
          },
        );

        return;
      }
      final exception = AppRealtimeException(
        message: 'Error initializing AppRealtimeWrap',
        error: e,
        stackTrace: StackTrace.current,
      );
      onError?.call(
        exception,
      );

      _hasError = true;
    } finally {
      _isInitialized = true;
    }
  }

  Future<void> _reconnect(
    Client client, {
    required int reconnectMaxAttempts,
    required int reconnectDelay,
    required void Function(AppRealtimeException exception) onFailReconnect,
  }) async {
    // ignore: no_leading_underscores_for_local_identifiers
    var _reconnectMaxAttempts = reconnectMaxAttempts;

    while (_reconnectMaxAttempts >= 0) {
      if (_reconnectMaxAttempts == 0) {
        _logger.severe('Reconnect attempts exhausted');
        onFailReconnect(
          AppRealtimeException(
            message: 'Reconnect attempts exhausted',
            error: 'Reconnect attempts exhausted',
            stackTrace: StackTrace.current,
          ),
        );
        break;
      }

      await Future<void>.delayed(
        Duration(seconds: reconnectDelay),
      );
      _logger.info('Reconnecting to Realtime after $reconnectDelay seconds');
      try {
        final instance = Realtime(client);
        _realtime.value = instance;
        break;
      } catch (e) {
        _logger.severe('Reconnecting to Realtime failed');
        _reconnectMaxAttempts--;
      }
    }
  }

  /// Subscribes to Appwrite events and returns a `SubscribeRealtime` object
  /// which can be used
  SubscribeRealtime<RealtimeMessage> subscribe({
    required List<String> channels,
    required SubscribeStateCallback stateListen,
  }) {
    if (_isDisposed) {
      throw AppRealtimeException(
        message: 'AppRealtimeWrap is already disposed',
        error: 'AppRealtimeWrap is already disposed',
        stackTrace: StackTrace.current,
      );
    }

    if (!_isInitialized) {
      throw AppRealtimeException(
        message: 'AppRealtimeWrap is not initialized',
        error: 'AppRealtimeWrap is not initialized',
        stackTrace: StackTrace.current,
      );
    }

    if (_hasError) {
      throw AppRealtimeException(
        message: 'AppRealtimeWrap has error',
        error: 'AppRealtimeWrap has error',
        stackTrace: StackTrace.current,
      );
    }

    return SubscribeService<RealtimeMessage>(
      staleTimeout: _staleTimeout,
      realtime: _realtime.value!,
    ).subscribe(channels: channels, stateListen: stateListen);
  }

  /// Disposes the `AppRealtimeWrap`. To avoid memory leaks,
  /// this method should be called when the `AppRealtimeWrap` is
  /// no longer needed.
  Future<void> dispose() async {
    if (_isDisposed) {
      throw AppRealtimeException(
        message: 'AppRealtimeWrap is already disposed',
        error: 'AppRealtimeWrap is already disposed',
        stackTrace: StackTrace.current,
      );
    }

    if (!_isInitialized) {
      throw AppRealtimeException(
        message: 'AppRealtimeWrap is not initialized',
        error: 'AppRealtimeWrap is not initialized',
        stackTrace: StackTrace.current,
      );
    }

    _logger.info('Disposing AppRealtimeWrap');

    await _errorController.close();

    _isDisposed = true;
  }
}
