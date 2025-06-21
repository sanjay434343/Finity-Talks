import 'package:flutter/material.dart';

extension NavigationHelper on Navigator {
  static void pushNamedAndClearStack(BuildContext context, String routeName) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      routeName,
      (Route<dynamic> route) => false,
    );
  }
}
