import 'package:flutter/material.dart';

/// KeyboardManager provides utilities to manage the keyboard state.

class KeyboardManager {
  /// Hides the keyboard if it is currently open.

  static void hideKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  /// Shows the keyboard for the given [FocusNode].

  static void showKeyboard(FocusNode focusNode) {
    focusNode.requestFocus();
  }

  /// Returns true if the keyboard is currently visible.

  static bool isKeyboardVisible(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom > 0;
  }
}

/// A widget that dismisses the keyboard when tapping outside of input fields.

class KeyboardDismissOnTap extends StatelessWidget {
  final Widget child;

const KeyboardDismissOnTap({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,

      onTap: () => KeyboardManager.hideKeyboard(context),

      child: child,
    );
  }
}
