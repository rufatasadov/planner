import 'package:flutter/material.dart';

/// Extra space under a field so the button below it stays above the keyboard.
const fieldScrollPadding = EdgeInsets.fromLTRB(20, 24, 20, 140);

/// Dismisses the keyboard when the surrounding route closes or the user taps
/// empty space.
class DismissKeyboard extends StatefulWidget {
  const DismissKeyboard({super.key, required this.child});

  final Widget child;

  @override
  State<DismissKeyboard> createState() => _DismissKeyboardState();
}

class _DismissKeyboardState extends State<DismissKeyboard> {
  @override
  void dispose() {
    FocusManager.instance.primaryFocus?.unfocus();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.opaque,
      child: widget.child,
    );
  }
}

/// Bottom-sheet body. The action button can be scrolled above the keyboard,
/// and a tap on empty space hides the keyboard.
class KeyboardSheet extends StatelessWidget {
  const KeyboardSheet({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(20, 0, 20, 16),
  });

  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final safe = MediaQuery.paddingOf(context).bottom;
    return DismissKeyboard(
      child: ListView(
        shrinkWrap: true,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: padding.copyWith(
          bottom: padding.bottom + (inset > 0 ? inset : safe),
        ),
        children: [
          DismissKeyboard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}
