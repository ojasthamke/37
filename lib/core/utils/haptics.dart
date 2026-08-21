import 'package:flutter/services.dart';

class AppHaptics {
  AppHaptics._();

  static void itemAdded() {
    HapticFeedback.lightImpact();
  }

  static void selection() {
    HapticFeedback.selectionClick();
  }

  static void buttonClick() {
    HapticFeedback.mediumImpact();
  }

  static void primarySave() {
    HapticFeedback.heavyImpact();
  }

  static void warning() {
    HapticFeedback.vibrate();
  }

  static void success() {
    HapticFeedback.lightImpact();
  }

  static void error() {
    HapticFeedback.vibrate();
  }

  static void impact() {
    HapticFeedback.mediumImpact();
  }
}
