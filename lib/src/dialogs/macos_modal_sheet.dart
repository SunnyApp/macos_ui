import 'package:flutter/material.dart';
import 'package:macos_ui/src/library.dart';
import 'package:macos_ui/macos_ui.dart';

const kDialogRadius = Radius.circular(12.0);
const _kDialogBorderRadius = BorderRadius.all(kDialogRadius);

/// A macOS-style AlertDialog.
///
/// A [MacosAlertDialog] must display an [appIcon], [title], [message],
/// and [primaryButton].
///
/// To display a [MacosAlertDialog] call [showMacosAlertDialog].
/// ```dart
/// showMacosAlertDialog(
///    context: context,
///    builder: (_) => MacosAlertDialog(
///     appIcon: FlutterLogo(
///       size: 56,
///     ),
///     title: Text(
///       'Alert Dialog with Primary Action',
///     ),
///     message: Text(
///       'This is an alert dialog with a primary action and no secondary action',
///     ),
///     primaryButton: PushButton(
///       buttonSize: ButtonSize.large,
///       child: Text('Primary'),
///       onPressed: Navigator.of(context).pop,
///     ),
///   ),
/// ),
/// ```
class MacosModalSheet extends StatelessWidget {
  /// Builds a macOS-style Alert Dialog
  const MacosModalSheet({
    super.key,
    this.backgroundColor,
    this.constraints,
    required this.body,
    this.heroTag,
  });

  final String? heroTag;
  final Color? backgroundColor;
  final BoxConstraints? constraints;

  /// The content to display in the dialog.
  ///
  /// Typically a Text widget.
  final Widget body;

  static const kPrimaryButtonHeight = 18.0;
  static const kSpacer = 16.0;
  static const kIconHeight = 28.0;
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

    var innerBorderSide = BorderSide(
      color: innerBorderColor,
      width: 2,
    );
    var outerBorderSide = BorderSide(
      width: 1,
      color: outerBorderColor,
    );
    var page = Material(
      color: backgroundColor ??
          brightness.resolve(
            CupertinoColors.systemGrey6.color,
            MacosColors.controlBackgroundColor.darkColor,
          ),
      shape: const RoundedRectangleBorder(
        borderRadius: _kDialogBorderRadius,
      ),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: Container(
        foregroundDecoration: BoxDecoration(
          border: Border.fromBorderSide(outerBorderSide),
          borderRadius: _kDialogBorderRadius,
        ),
        // duration: const Duration(milliseconds: 200),
        child: Container(
          decoration: BoxDecoration(
            border: Border.fromBorderSide(innerBorderSide),
            borderRadius: _kDialogBorderRadius,
          ),
          // duration: const Duration(milliseconds: 200),
          child: body,
        ),
      ),
    );
    return heroTag == null
        ? page
        : Hero(
            tag: heroTag!,
            transitionOnUserGestures: true,
            // createRectTween: (begin, end) {
            //   return RectTween(
            //     begin: end,
            //     end: begin,
            //   );
            // },
            child: page,
          );
  }
}
