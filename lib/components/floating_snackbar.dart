import 'package:flutter/material.dart';

import 'package:univ_tiaret/constants.dart';

enum SnackBarType { success, error, info, warning }

DateTime? _lastSnackBarTime;
String? _lastSnackBarMessage;

void showFloatingSnackBar(
  BuildContext context, {
  required String message,
  SnackBarType type = SnackBarType.info,
  Duration duration = const Duration(seconds: 3),
}) {
  final now = DateTime.now();
  if (_lastSnackBarMessage == message &&
      _lastSnackBarTime != null &&
      now.difference(_lastSnackBarTime!) < const Duration(seconds: 5)) {
    return;
  }
  _lastSnackBarTime = now;
  _lastSnackBarMessage = message;

  final scaffold = ScaffoldMessenger.of(context);
  scaffold.hideCurrentSnackBar();

  final color = switch (type) {
    SnackBarType.success => successColor,
    SnackBarType.error => errorColor,
    SnackBarType.info => primaryColor,
    SnackBarType.warning => warningColor,
  };

  final icon = switch (type) {
    SnackBarType.success => Icons.check_circle_rounded,
    SnackBarType.error => Icons.error_outline_rounded,
    SnackBarType.info => Icons.info_outline_rounded,
    SnackBarType.warning => Icons.warning_rounded,
  };

  scaffold.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(
        defaultPadding,
        0,
        defaultPadding,
        defaultPadding,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(defaultBorderRadious),
      ),
      duration: duration,
      elevation: 6,
    ),
  );
}
