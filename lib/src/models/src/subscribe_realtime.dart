import 'dart:async';

import 'package:appwrite/appwrite.dart';

/// The type of realtime event.
enum SubscribeRealtimeType {
  /// A new data was created.
  create,

  /// A data was updated.
  update,

  /// A data was deleted.
  delete,

  /// A data was read.
  read,

  /// Unknown realtime type.
  unknown,
  ;

  /// Parse ConsultationRealtimeType from string
  static SubscribeRealtimeType fromString(String value) {
    final parts = value.split('.');
    final eventTypeString = parts.last;

    switch (eventTypeString) {
      case 'create':
        return SubscribeRealtimeType.create;
      case 'update':
        return SubscribeRealtimeType.update;
      case 'delete':
        return SubscribeRealtimeType.delete;
      case 'read':
        return SubscribeRealtimeType.read;
      default:
        return SubscribeRealtimeType.unknown;
    }
  }
}

/// {@template sidlak_realtime}
/// The realtime event of the [T].
/// {@endtemplate}
class SubscribeRealtime<T> {
  /// {@macro sidlak_realtime}
  const SubscribeRealtime({
    required this.onDispose,
    required this.subscription,
  });

  /// The callback when the subscription is disposed.
  final void Function() onDispose;

  /// The subscription
  final Stream<SubscribeRealtimeData<RealtimeMessage>> subscription;

  /// Dispose
  Future<void> dispose() async {
    onDispose.call();
  }
}

/// {@template sidlak_realtime}
/// The realtime event of the [T].
/// {@endtemplate}
class SubscribeRealtimeData<T> {
  /// {@macro sidlak_realtime}
  SubscribeRealtimeData({
    required this.data,
    required this.type,
  });

  /// The data of the realtime event.
  T data;

  /// The type of realtime event.
  SubscribeRealtimeType type;

  /// When method by return [R]
  R when<R>({
    required R Function(T data) onCreate,
    required R Function(T data) onUpdate,
    required R Function(T data) onDelete,
    required R Function(T data) onRead,
    required R Function(T data) unknown,
  }) =>
      switch (type) {
        SubscribeRealtimeType.create => onCreate(data),
        SubscribeRealtimeType.update => onUpdate(data),
        SubscribeRealtimeType.delete => onDelete(data),
        SubscribeRealtimeType.read => onRead(data),
        SubscribeRealtimeType.unknown => unknown(data),
      };

  /// When method by return [R]
  R maybeWhen<R>({
    required R Function(T data) orElse,
    R Function(T data)? onCreate,
    R Function(T data)? onUpdate,
    R Function(T data)? onDelete,
    R Function(T data)? onRead,
    R Function(T data)? unknown,
  }) {
    if (type == SubscribeRealtimeType.create) {
      return onCreate != null ? onCreate(data) : orElse(data);
    } else if (type == SubscribeRealtimeType.update) {
      return onUpdate != null ? onUpdate(data) : orElse(data);
    } else if (type == SubscribeRealtimeType.delete) {
      return onDelete != null ? onDelete(data) : orElse(data);
    } else if (type == SubscribeRealtimeType.read) {
      return onRead != null ? onRead(data) : orElse(data);
    } else if (type == SubscribeRealtimeType.unknown) {
      return unknown != null ? unknown(data) : orElse(data);
    } else {
      return orElse(data);
    }
  }
}
