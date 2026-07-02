import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class Responsive {
  static bool isDesktop(BuildContext context) {
    if (kIsWeb) {
      return MediaQuery.of(context).size.width >= 800;
    }
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  static bool isMobile(BuildContext context) {
    if (kIsWeb) {
      return MediaQuery.of(context).size.width < 800;
    }
    return Platform.isAndroid || Platform.isIOS;
  }

  static Widget builder({
    required BuildContext context,
    required Widget mobile,
    required Widget desktop,
  }) {
    if (isDesktop(context)) {
      return desktop;
    }
    return mobile;
  }
}
