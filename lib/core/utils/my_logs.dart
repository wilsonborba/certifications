// ignore_for_file: avoid_print


import 'package:accredit/core/settings.dart';
import 'package:flutter/material.dart';

import 'package:logging/logging.dart';


final Level _logLevel = app_settings.developmentMode ? Level.ALL : Level.INFO;

bool _shouldLog(Level messageLevel) => messageLevel.value >= _logLevel.value;

void debug(String message) {
  if (_shouldLog(Level.FINE)) {
    print('[DEBUG] $message');
  }
}

void info(String message) {
  if (_shouldLog(Level.INFO)) {
    print('[INFO] $message');
  }
}

void warning(String message) {
  if (_shouldLog(Level.WARNING)) {
    print('[WARNING] $message');
  }
}

void severe(String message) {
  if (_shouldLog(Level.SEVERE)) {
    print('[SEVERE] $message');
  }
}


  /// Handle authentication failure
  void handleAuthFailure(BuildContext context, String message, void Function(bool) setLoading) async {
    await Future.delayed(const Duration(seconds: 2));
    setLoading(false);  // Stop loading

    if (context.mounted) {
      showSnackBar(context, message);
    }
  }

  /// Display a snack bar message
  void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
