import 'package:flutter/material.dart';

/// Space around a sheet's content; the drag handle above it adds its own.
const sheetPadding = EdgeInsets.fromLTRB(24, 0, 24, 24);

/// Opens what [builder] builds in a sheet from the bottom, with a handle to
/// drag it away. It's as tall as its content, up to the whole screen.
Future<T?> showAppSheet<T>(BuildContext context, WidgetBuilder builder) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: builder,
    );

/// Opens a long read, like help, in a sheet that starts tall and scrolls with
/// the controller [builder] gets.
Future<void> showReadingSheet(
  BuildContext context,
  Widget Function(ScrollController controller) builder,
) => showAppSheet<void>(
  context,
  (_) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.85,
    maxChildSize: 0.95,
    builder: (_, controller) => builder(controller),
  ),
);

/// A sheet's content, clear of the screen's edges and scrolling when it
/// doesn't fit.
class SheetBody extends StatelessWidget {
  const SheetBody({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(padding: sheetPadding, child: child),
    );
  }
}

/// Shown in a sheet while what it shows is loading.
class SheetLoading extends StatelessWidget {
  const SheetLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 240,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
