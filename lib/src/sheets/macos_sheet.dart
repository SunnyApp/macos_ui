import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:macos_ui/src/library.dart';

const _kSheetBorderRadius = BorderRadius.all(Radius.circular(12.0));
const EdgeInsets _defaultInsetPadding =
    EdgeInsets.symmetric(horizontal: 140.0, vertical: 48.0);

/// {@template macosSheet}
/// A modal dialog that’s attached to a particular window and prevents further
/// interaction with the window until the sheet is dismissed.
/// {@endtemplate}
class MacosSheet extends StatelessWidget {
  /// {@macro macosSheet}
  const MacosSheet({
    super.key,
    required this.child,
    this.insetPadding = _defaultInsetPadding,
    this.insetAnimationDuration = const Duration(milliseconds: 100),
    this.insetAnimationCurve = Curves.decelerate,
    this.backgroundColor,
  });

  /// The widget below this widget in the tree.
  final Widget child;

  /// The amount of padding added to [MediaQueryData.viewInsets] on the outside
  /// of the dialog. This defines the minimum space between the screen's edges
  /// and the dialog.
  final EdgeInsets? insetPadding;

  /// The duration of the animation to show when the system keyboard intrudes
  /// into the space that the dialog is placed in.
  final Duration insetAnimationDuration;

  /// The curve to use for the animation shown when the system keyboard intrudes
  /// into the space that the dialog is placed in.
  final Curve insetAnimationCurve;

  /// The background color for this widget.
  ///
  /// Defaults to
  /// ```dart
  /// brightness.resolve(
  ///   CupertinoColors.systemGrey6.color,
  ///   MacosColors.controlBackgroundColor.darkColor,
  /// )
  /// ```
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMacosTheme(context));
    final brightness = MacosTheme.brightnessOf(context);

    final outerBorderColor = brightness.resolve(
      Colors.black.withOpacity(0.23),
      Colors.black.withOpacity(0.76),
    );

    final innerBorderColor = brightness.resolve(
      Colors.white.withOpacity(0.45),
      Colors.white.withOpacity(0.15),
    );

    final EdgeInsets effectivePadding =
        MediaQuery.of(context).viewInsets + (insetPadding ?? EdgeInsets.zero);

    return AnimatedPadding(
      padding: effectivePadding,
      duration: insetAnimationDuration,
      curve: insetAnimationCurve,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor ??
              brightness.resolve(
                CupertinoColors.systemGrey6.color,
                MacosColors.controlBackgroundColor.darkColor,
              ),
          borderRadius: _kSheetBorderRadius,
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              width: 2,
              color: innerBorderColor,
            ),
            borderRadius: _kSheetBorderRadius,
          ),
          foregroundDecoration: BoxDecoration(
            border: Border.all(
              width: 1,
              color: outerBorderColor,
            ),
            borderRadius: _kSheetBorderRadius,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Displays a [MacosSheet] above the current application.
Future<T?> showMacosSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = false,
  Color? barrierColor,
  String? barrierLabel,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  Constraints? constraints,
}) {
  barrierColor ??= MacosDynamicColor.resolve(
    MacosColors.controlBackgroundColor,
    context,
  ).withOpacity(0.6);

  return Navigator.of(context, rootNavigator: useRootNavigator).push<T>(
    MacosModalSheetRoute<T>(
      settings: routeSettings,
      pageBuilder: builder,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel ??
          MaterialLocalizations.of(context).modalBarrierDismissLabel,
    ),
  );
}

typedef ModalSheetBuilder = Widget Function(BuildContext context);

class MacosModalSheetRoute<T> extends PopupRoute<T> {
  MacosModalSheetRoute({
    required this.pageBuilder,
    this.barrierDismissible = false,
    this.barrierColor = const Color(0x80000000),
    this.barrierLabel,
    this.constraints,
    super.settings,
  });

  final ModalSheetBuilder pageBuilder;

  final BoxConstraints? constraints;
  @override
  final bool barrierDismissible;

  @override
  final String? barrierLabel;

  @override
  final Color? barrierColor;

  @override
  Curve get barrierCurve => Curves.linear;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 450);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 120);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: pageBuilder(context),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (animation.status == AnimationStatus.reverse) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutSine,
        ),
        child: child,
      );
    }
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: animation,
        curve: const _SubtleBounceCurve(),
      ),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.fastLinearToSlowEaseIn,
        ),
        child: child,
      ),
    );
  }
}

class MacosModalSheetRoute2<T> extends PageRoute<T> {
  MacosModalSheetRoute2({
    required this.pageBuilder,
    this.barrierDismissible = false,
    this.barrierColor = const Color(0x80000000),
    this.barrierLabel,
    this.constraints,
    this.maintainState = true,
    super.settings,
  });

  final ModalSheetBuilder pageBuilder;

  @override
  final bool maintainState;

  final BoxConstraints? constraints;

  @override
  final bool barrierDismissible;

  @override
  final String? barrierLabel;

  @override
  final Color? barrierColor;

  @override
  Curve get barrierCurve => Curves.linear;

  @override
  bool get opaque => false;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 450);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 120);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: Center(
        child: _buildWithConstraints(
          child: _buildInSheet(
            child: pageBuilder(context),
          ),
        ),
      ),
    );
  }

  Widget _buildInSheet({required Widget child}) {
    return child;
  }

  Widget _buildWithConstraints({required Widget child}) {
    if (constraints == null) {
      return child;
    } else {
      return ConstrainedBox(constraints: constraints!, child: child);
    }
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (animation.status == AnimationStatus.reverse) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutSine,
        ),
        child: child,
      );
    }
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: animation,
        curve: const _SubtleBounceCurve(),
      ),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.fastLinearToSlowEaseIn,
        ),
        child: child,
      ),
    );
  }
}

class MacosSheetPage<T> extends Page<T> {
  const MacosSheetPage({
    required this.child,
    this.barrierDismissible = false,
    this.barrierColor = const Color(0x80000000),
    this.barrierLabel,
  });

  final Widget child;

  final bool barrierDismissible;

  final String? barrierLabel;

  final Color? barrierColor;

  Curve get barrierCurve => Curves.linear;

  Duration get transitionDuration => const Duration(milliseconds: 450);

  Duration get reverseTransitionDuration => const Duration(milliseconds: 120);

  @override
  Route<T> createRoute(BuildContext context) {
    return MacosModalSheetRoute(
      settings: this,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel,
      pageBuilder: (context) => child,
    );
  }
}

class _SubtleBounceCurve extends Curve {
  const _SubtleBounceCurve();

  @override
  double transform(double t) {
    final simulation = SpringSimulation(
      const SpringDescription(
        damping: 14,
        mass: 1.4,
        stiffness: 180,
      ),
      0.0,
      1.0,
      0.1,
    );
    return simulation.x(t) + t * (1 - simulation.x(1.0));
  }
}
