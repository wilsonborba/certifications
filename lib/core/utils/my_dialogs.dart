import 'package:flutter/material.dart';
import 'package:certifications/core/utils/app_localizations.dart';

void showMyDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(context.tr('ok')),
        ),
      ],
    ),
  );
}
