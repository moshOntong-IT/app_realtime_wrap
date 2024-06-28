import 'package:appwrite/appwrite.dart';

/// {@template app_realtime_wrap}
/// A package to extend Appwrite Realtime
/// {@endtemplate}
class AppRealtimeWrap {
  /// {@macro app_realtime_wrap}
  const AppRealtimeWrap._();

  static const AppRealtimeWrap _instance = AppRealtimeWrap._();

  /// Returns the instance of AppRealtimeWrap
  static AppRealtimeWrap get instance => _instance;

  Future<void> initialize({required Client client}) async {}
}
