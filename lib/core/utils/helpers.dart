import 'package:intl/intl.dart';

/// KLE HOMECARE — Shared Utility Helpers
class AppHelpers {
  AppHelpers._();

  static String formatDate(DateTime date) =>
      DateFormat('dd MMM yyyy').format(date);

  static String formatDateTime(DateTime dt) =>
      DateFormat('dd MMM yyyy, hh:mm a').format(dt);

  static String formatDateApi(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date);

  static String capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  static String serviceTypeLabel(String type) =>
      type.replaceAll('_', ' ').split(' ').map(capitalize).join(' ');

  static String statusLabel(String status) =>
      status.replaceAll('_', ' ').split(' ').map(capitalize).join(' ');

  static String urgencyLabel(String urgency) => capitalize(urgency);

  /// Returns a user-friendly error message from an exception.
  static String friendlyError(Object error) {
    final msg = error.toString();
    if (msg.contains('NetworkException')) {
      return 'No internet connection. Please check your network.';
    }
    if (msg.contains('UnauthorizedException')) {
      return 'Session expired. Please login again.';
    }
    if (msg.contains('ServerException')) {
      // Extract the message part
      final match = RegExp(r'ServerException\(\d*\): (.+)').firstMatch(msg);
      return match?.group(1) ?? 'Server error. Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }
}
