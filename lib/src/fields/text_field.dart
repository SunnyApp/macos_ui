import 'dart:ui' as ui show BoxHeightStyle, BoxWidthStyle;

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'package:macos_ui/macos_ui.dart';
import 'package:macos_ui/src/library.dart';

export 'package:flutter/services.dart'
    show
        TextInputType,
        TextInputAction,
        TextCapitalization,
        SmartQuotesType,
        SmartDashesType;

const _klightBorderSide = BorderSide(
  width: 3,
  color: Color.fromRGBO(0, 103, 244, 0.25),
);
const _kdarkBorderSide = BorderSide(
  width: 3,
  color: Color.fromRGBO(26, 169, 255, 0.3),
);

const _klightFocusedDecoration = BoxDecoration(
  border: Border(
    bottom: _klightBorderSide,
    top: _klightBorderSide,
    left: _klightBorderSide,
    right: _klightBorderSide,
  ),
);

const _kdarkFocusedDecoration = BoxDecoration(
  border: Border(
    bottom: _kdarkBorderSide,
    top: _kdarkBorderSide,
    left: _kdarkBorderSide,
    right: _kdarkBorderSide,
  ),
);

const TextStyle _kDefaultPlaceholderStyle = TextStyle(
  fontWeight: FontWeight.w400,
  color: CupertinoColors.placeholderText,
);

const BorderSide _kDefaultRoundedBorderSide = BorderSide(
  color: CupertinoDynamicColor.withBrightness(
    color: Color(0x33000000),
    darkColor: Color(0x33FFFFFF),
  ),
  style: BorderStyle.solid,
  width: 0.1,
);

const Border _kDefaultRoundedBorder = Border(
  top: _kDefaultRoundedBorderSide,
  bottom: _kDefaultRoundedBorderSide,
  left: _kDefaultRoundedBorderSide,
  right: _kDefaultRoundedBorderSide,
);

const BoxDecoration kDefaultRoundedBorderDecoration = BoxDecoration(
  color: CupertinoDynamicColor.withBrightness(
    color: CupertinoColors.white,
    darkColor: CupertinoColors.black,
  ),
  border: _kDefaultRoundedBorder,
  boxShadow: [
    BoxShadow(
      color: CupertinoDynamicColor.withBrightness(
        color: Color.fromRGBO(0, 0, 0, 0.1),
        darkColor: Color.fromRGBO(255, 255, 255, 0.1),
      ),
      offset: Offset(0, 1),
    ),
  ],
  borderRadius: BorderRadius.all(Radius.circular(7.0)),
);

const BoxDecoration kDefaultFocusedBorderDecoration = BoxDecoration(
  borderRadius: BorderRadius.all(Radius.circular(7.0)),
  boxShadow: [],
);

const Color _kDisabledBackground = CupertinoDynamicColor.withBrightness(
  color: Color(0xfff6f6f9),
  darkColor: Color.fromRGBO(255, 255, 255, 0.01),
);

// An eyeballed value that moves the cursor slightly left of where it is
// rendered for text on Android so it's positioning more accurately matches the
// native iOS text cursor positioning.
//
// This value is in device pixels, not logical pixels as is typically used
// throughout the codebase.
const int _iOSHorizontalCursorOffsetPixels = -2;

/// Visibility of text field overlays based on the state of the current text entry.
///
/// Used to toggle the visibility behavior of the optional decorating widgets
/// surrounding the [EditableText] such as the clear text button.
enum OverlayVisibilityMode {
  /// Overlay will never appear regardless of the text entry state.
  never,

  /// Overlay will only appear when the current text entry is not empty.
  ///
  /// This includes prefilled text that the user did not type in manually. But
  /// does not include text in placeholders.
  editing,

  /// Overlay will only appear when the current text entry is empty.
  ///
  /// This also includes not having prefilled text that the user did not type
  /// in manually. Texts in placeholders are ignored.
  notEditing,

  /// Always show the overlay regardless of the text entry state.
  always,
}

class _TextFieldSelectionGestureDetectorBuilder
    extends TextSelectionGestureDetectorBuilder {
  _TextFieldSelectionGestureDetectorBuilder({
    required _MacosTextFieldState state,
  })  : _state = state,
        super(delegate: state);

  final _MacosTextFieldState _state;

  @override
  void onSingleTapUp(TapUpDetails details) {
    // Because TextSelectionGestureDetector listens to taps that happen on
    // widgets in front of it, tapping the clear button will also trigger
    // this handler. If the clear button widget recognizes the up event,
    // then do not handle it.
    if (_state._clearGlobalKey.currentContext != null) {
      final RenderBox renderBox = _state._clearGlobalKey.currentContext!
          .findRenderObject()! as RenderBox;
      final Offset localOffset =
          renderBox.globalToLocal(details.globalPosition);
      if (renderBox.hitTest(BoxHitTestResult(), position: localOffset)) {
        return;
      }
    }
    if (delegate.selectionEnabled) {
      renderEditable.selectPosition(cause: SelectionChangedCause.tap);
    }
    _state._requestKeyboard();
    if (_state.widget.onTap != null) _state.widget.onTap!();
  }

  @override
  void onDragSelectionEnd(DragEndDetails details) {
    _state._requestKeyboard();
  }
}

class MacosTextFieldThemeData {
  const MacosTextFieldThemeData.raw({
    required this.decoration,
    required this.focusedDecoration,
    required this.padding,
    required this.margin,
    required this.placeholderStyle,
    required this.style,
    required this.strutStyle,
    required this.textAlign,
    required this.textAlignVertical,
    required this.obscuringCharacter,
    required this.smartDashesType,
    required this.smartQuotesType,
    required this.cursorWidth,
    required this.cursorHeight,
    required this.cursorRadius,
    required this.scrollPadding,
    required this.cursorColor,
    required this.selectionColor,
    required this.selectionHeightStyle,
    required this.selectionWidthStyle,
  });

  const MacosTextFieldThemeData({
    this.decoration,
    this.focusedDecoration,
    this.padding,
    this.margin,
    this.placeholderStyle,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textAlignVertical,
    this.obscuringCharacter,
    this.smartDashesType,
    this.smartQuotesType,
    this.cursorWidth,
    this.cursorHeight,
    this.cursorRadius,
    this.cursorColor,
    this.selectionColor,
    this.selectionHeightStyle,
    this.selectionWidthStyle,
    this.scrollPadding,
  });

  final Color? selectionColor;

  /// Controls the [BoxDecoration] of the box behind the text input.
  ///
  /// Defaults to having a rounded rectangle grey border and can be null to have
  /// no box decoration.
  final BoxDecoration? decoration;

  /// Controls the [BoxDecoration] of the box behind the text input when focused.
  /// This decoration is drawn above [decoration].
  ///
  /// Defaults to having a rounded rectangle blue border and can be null to have
  /// no box decoration.
  final BoxDecoration? focusedDecoration;

  /// Padding around the text entry area between the [prefix] and [suffix]
  /// or the clear button when [clearButtonMode] is not never.
  ///
  /// Defaults to a padding of 6 pixels on all sides and can be null.
  final EdgeInsets? padding;

  /// Padding around the text element. The border of the text field will expand
  /// into this area as needed./// Padding around the text element. The border of the text field will expand
  /// into this area as needed.
  final EdgeInsets? margin;

  /// The style to use for the placeholder text.
  ///
  /// The [placeholderStyle] is merged with the [style] [TextStyle] when applied
  /// to the [placeholder] text. To avoid merging with [style], specify
  /// [TextStyle.inherit] as false.
  ///
  /// Defaults to the [style] property with w300 font weight and grey color.
  ///
  /// If specifically set to null, placeholder's style will be the same as [style].
  final TextStyle? placeholderStyle;

  /// The style to use for the text being edited.
  ///
  /// Also serves as a base for the [placeholder] text's style.
  ///
  /// Defaults to the standard font style from [MacosTheme] if null.
  final TextStyle? style;

  /// {@macro flutter.widgets.editableText.strutStyle}
  final StrutStyle? strutStyle;

  /// {@macro flutter.widgets.editableText.textAlign}
  final TextAlign? textAlign;

  /// {@macro flutter.material.InputDecorator.textAlignVertical}
  final TextAlignVertical? textAlignVertical;

  /// {@macro flutter.widgets.editableText.obscuringCharacter}
  final String? obscuringCharacter;

  /// {@macro flutter.services.TextInputConfiguration.smartDashesType}
  final SmartDashesType? smartDashesType;

  /// {@macro flutter.services.TextInputConfiguration.smartQuotesType}
  final SmartQuotesType? smartQuotesType;

  /// {@macro flutter.widgets.editableText.cursorWidth}
  final double? cursorWidth;

  /// {@macro flutter.widgets.editableText.cursorHeight}
  final double? cursorHeight;

  /// {@macro flutter.widgets.editableText.cursorRadius}
  final Radius? cursorRadius;
  final EdgeInsets? scrollPadding;

  /// The color to use when painting the cursor.
  ///
  /// Defaults to the [MacosThemeData.primaryColor] of the ambient theme,
  /// which itself defaults to [CupertinoColors.activeBlue] in the light theme
  /// and [CupertinoColors.activeOrange] in the dark theme.
  final Color? cursorColor;

  /// Controls how tall the selection highlight boxes are computed to be.
  ///
  /// See [ui.BoxHeightStyle] for details on available styles.
  final ui.BoxHeightStyle? selectionHeightStyle;

  /// Controls how wide the selection highlight boxes are computed to be.
  ///
  /// See [ui.BoxWidthStyle] for details on available styles.
  final ui.BoxWidthStyle? selectionWidthStyle;

  /// Linearly interpolate between two icon theme data objects.
  ///
  /// {@macro dart.ui.shadow.lerp}
  static MacosTextFieldThemeData lerp(
    MacosTextFieldThemeData? a,
    MacosTextFieldThemeData? b,
    double t,
  ) {
    return b ?? a!;
  }

  MacosTextFieldThemeData merge(MacosTextFieldThemeData? other) {
    if (other == null) return this;
    return copyWith(
      decoration: other.decoration ?? decoration,
      focusedDecoration: other.focusedDecoration ?? focusedDecoration,
      padding: other.padding ?? padding,
      placeholderStyle: placeholderStyle == null
          ? other.placeholderStyle
          : placeholderStyle!.merge(other.placeholderStyle),
      style: style == null ? other.style : style!.merge(other.style),
      strutStyle: other.strutStyle ?? strutStyle,
      textAlign: other.textAlign ?? textAlign,
      textAlignVertical: other.textAlignVertical ?? textAlignVertical,
      obscuringCharacter: other.obscuringCharacter ?? obscuringCharacter,
      smartDashesType: other.smartDashesType ?? smartDashesType,
      smartQuotesType: other.smartQuotesType ?? smartQuotesType,
      cursorWidth: other.cursorWidth ?? cursorWidth,
      cursorHeight: other.cursorHeight ?? cursorHeight,
      cursorRadius: other.cursorRadius ?? cursorRadius,
      scrollPadding: other.scrollPadding ?? scrollPadding,
      cursorColor: other.cursorColor ?? cursorColor,
      selectionColor: other.selectionColor ?? selectionColor,
      selectionHeightStyle: other.selectionHeightStyle ?? selectionHeightStyle,
      selectionWidthStyle: other.selectionWidthStyle ?? selectionWidthStyle,
    );
  }

  MacosTextFieldThemeData copyWith({
    BoxDecoration? decoration,
    BoxDecoration? focusedDecoration,
    EdgeInsets? padding,
    EdgeInsets? margin,
    TextStyle? placeholderStyle,
    TextStyle? style,
    StrutStyle? strutStyle,
    TextAlign? textAlign,
    ToolbarOptions? toolbarOptions,
    TextAlignVertical? textAlignVertical,
    String? obscuringCharacter,
    SmartDashesType? smartDashesType,
    SmartQuotesType? smartQuotesType,
    double? cursorWidth,
    double? cursorHeight,
    Radius? cursorRadius,
    EdgeInsets? scrollPadding,
    Color? cursorColor,
    Color? selectionColor,
    ui.BoxHeightStyle? selectionHeightStyle,
    ui.BoxWidthStyle? selectionWidthStyle,
  }) {
    return MacosTextFieldThemeData.raw(
      margin: margin ?? this.margin,
      selectionColor: selectionColor ?? this.selectionColor,
      decoration: decoration ?? this.decoration,
      focusedDecoration: focusedDecoration ?? this.focusedDecoration,
      padding: padding ?? this.padding,
      placeholderStyle: placeholderStyle ?? this.placeholderStyle,
      style: style ?? this.style,
      strutStyle: strutStyle ?? this.strutStyle,
      textAlign: textAlign ?? this.textAlign,
      textAlignVertical: textAlignVertical ?? this.textAlignVertical,
      obscuringCharacter: obscuringCharacter ?? this.obscuringCharacter,
      smartDashesType: smartDashesType ?? this.smartDashesType,
      smartQuotesType: smartQuotesType ?? this.smartQuotesType,
      cursorWidth: cursorWidth ?? this.cursorWidth,
      cursorHeight: cursorHeight ?? this.cursorHeight,
      cursorRadius: cursorRadius ?? this.cursorRadius,
      scrollPadding: scrollPadding ?? this.scrollPadding,
      cursorColor: cursorColor ?? this.cursorColor,
      selectionHeightStyle: selectionHeightStyle ?? this.selectionHeightStyle,
      selectionWidthStyle: selectionWidthStyle ?? this.selectionWidthStyle,
    );
  }

  MacosTextFieldThemeData resolveWidget(
    MacosTextField widget,
    Brightness brightness,
  ) {
    var defaultFocusedDecoration = brightness == Brightness.dark
        ? _kdarkFocusedDecoration
        : _klightFocusedDecoration;
    defaultFocusedDecoration =
        defaultFocusedDecoration.merge(kDefaultFocusedBorderDecoration);
    return MacosTextFieldThemeData.raw(
      decoration: kDefaultRoundedBorderDecoration
          .merge(decoration)
          .merge(widget.decoration),
      focusedDecoration: defaultFocusedDecoration
          .merge(widget.focusedDecoration ?? focusedDecoration),
      padding: widget.padding ?? padding ?? const EdgeInsets.all(4.0),
      margin: widget.margin ?? margin ?? EdgeInsets.zero,
      placeholderStyle: (placeholderStyle ??
                  style?.copyWith(color: style?.color?.withOpacity(0.4)))
              ?.merge(widget.placeholderStyle) ??
          widget.placeholderStyle,
      style: style?.merge(widget.style) ?? widget.style,
      selectionColor: widget.selectionColor ?? selectionColor,
      strutStyle: widget.strutStyle ?? strutStyle,
      textAlign: widget.textAlign ?? textAlign ?? TextAlign.start,
      textAlignVertical: widget.textAlignVertical ?? textAlignVertical,
      obscuringCharacter:
          widget.obscuringCharacter ?? obscuringCharacter ?? '•',
      smartDashesType: widget.smartDashesType ?? smartDashesType,
      smartQuotesType: widget.smartQuotesType ?? smartQuotesType,
      cursorWidth: widget.cursorWidth ?? cursorWidth ?? 2.0,
      cursorHeight: widget.cursorHeight ?? cursorHeight,
      cursorRadius:
          widget.cursorRadius ?? cursorRadius ?? const Radius.circular(2.0),
      scrollPadding:
          widget.scrollPadding ?? scrollPadding ?? const EdgeInsets.all(20.0),
      cursorColor: widget.cursorColor ?? cursorColor,
      selectionHeightStyle: widget.selectionHeightStyle ??
          selectionHeightStyle ??
          ui.BoxHeightStyle.tight,
      selectionWidthStyle: widget.selectionWidthStyle ??
          selectionWidthStyle ??
          ui.BoxWidthStyle.tight,
    );
  }
}

/// An macos-style text field.
///
/// A text field lets the user enter text, either with a hardware keyboard or with
/// an onscreen keyboard.
///
/// This widget corresponds to a `NSTextField` on macos.
///
/// The text field calls the [onChanged] callback whenever the user changes the
/// text in the field. If the user indicates that they are done typing in the
/// field (e.g., by pressing a button on the soft keyboard), the text field
/// calls the [onSubmitted] callback.
///
/// {@macro flutter.widgets.EditableText.onChanged}
///
/// To control the text that is displayed in the text field, use the
/// [controller]. For example, to set the initial value of the text field, use
/// a [controller] that already contains some text such as:
///
/// {@tool snippet}
///
/// ```dart
/// class MyPrefilledText extends StatefulWidget {
///   @override
///   _MyPrefilledTextState createState() => _MyPrefilledTextState();
/// }
///
/// class _MyPrefilledTextState extends State<MyPrefilledText> {
///   late TextEditingController _textController;
///
///   @override
///   void initState() {
///     super.initState();
///     _textController = TextEditingController(text: 'initial text');
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return TextField(controller: _textController);
///   }
/// }
/// ```
/// {@end-tool}
///
/// The [controller] can also control the selection and composing region (and to
/// observe changes to the text, selection, and composing region).
///
/// The text field has an overridable [decoration] that, by default, draws a
/// rounded rectangle border around the text field. If you set the [decoration]
/// property to null, the decoration will be removed entirely.
///
/// Remember to call [TextEditingController.dispose] when it is no longer
/// needed. This will ensure we discard any resources used by the object.
///
/// See also:
///
///  * <https://developer.apple.com/design/human-interface-guidelines/macos/fields-and-labels/text-fields/>
///  * [MacosTextField], an alternative text field widget that follows the Material
///    Design UI conventions.
///  * [EditableText], which is the raw text editing control at the heart of a
///    [TextField].
///  * Learn how to use a [TextEditingController] in one of our [cookbook recipes](https://flutter.dev/docs/cookbook/forms/text-field-changes#2-use-a-texteditingcontroller).
class MacosTextField extends StatefulWidget {
  /// Creates an macos-style text field.
  ///
  /// To provide a prefilled text entry, pass in a [TextEditingController] with
  /// an initial value to the [controller] parameter.
  ///
  /// To provide a hint placeholder text that appears when the text entry is
  /// empty, pass a [String] to the [placeholder] parameter.
  ///
  /// The [maxLines] property can be set to null to remove the restriction on
  /// the number of lines. In this mode, the intrinsic height of the widget will
  /// grow as the number of lines of text grows. By default, it is `1`, meaning
  /// this is a single-line text field and will scroll horizontally when
  /// overflown. [maxLines] must not be zero.
  ///
  /// The text cursor is not shown if [showCursor] is false or if [showCursor]
  /// is null (the default) and [readOnly] is true.
  ///
  /// If specified, the [maxLength] property must be greater than zero.
  ///
  /// The [selectionHeightStyle] and [selectionWidthStyle] properties allow
  /// changing the shape of the selection highlighting. These properties default
  /// to [ui.BoxHeightStyle.tight] and [ui.BoxWidthStyle.tight] respectively and
  /// must not be null.
  ///
  /// The [autocorrect], [autofocus], [clearButtonMode], [dragStartBehavior],
  /// [expands], [maxLengthEnforcement], [obscureText], [prefixMode], [readOnly],
  /// [scrollPadding], [suffixMode], [textAlign], [selectionHeightStyle],
  /// [selectionWidthStyle], and [enableSuggestions] properties must not be null.
  ///
  /// See also:
  ///
  ///  * [minLines], which is the minimum number of lines to occupy when the
  ///    content spans fewer lines.
  ///  * [expands], to allow the widget to size itself to its parent's height.
  ///  * [maxLength], which discusses the precise meaning of "number of
  ///    characters" and how it may differ from the intuitive meaning.
  const MacosTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.decoration,
    this.focusedDecoration,
    this.margin,
    this.padding,
    this.placeholder,
    this.placeholderStyle,
    this.prefix,
    this.prefixMode = OverlayVisibilityMode.always,
    this.suffix,
    this.suffixMode = OverlayVisibilityMode.always,
    this.clearButtonMode = OverlayVisibilityMode.never,
    TextInputType? keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textAlignVertical,
    this.readOnly = false,
    ToolbarOptions? toolbarOptions,
    this.showCursor,
    this.selectionColor,
    this.autofocus = false,
    this.obscuringCharacter,
    this.obscureText = false,
    this.autocorrect = true,
    SmartDashesType? smartDashesType,
    SmartQuotesType? smartQuotesType,
    this.enableSuggestions = true,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
    this.maxLength,
    this.maxLengthEnforcement,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.inputFormatters,
    this.enabled,
    this.cursorWidth,
    this.cursorHeight,
    this.cursorRadius,
    this.cursorColor,
    this.selectionHeightStyle,
    this.selectionWidthStyle,
    this.keyboardAppearance,
    this.scrollPadding,
    this.dragStartBehavior = DragStartBehavior.start,
    this.enableInteractiveSelection = true,
    this.selectionControls,
    this.onTap,
    this.scrollController,
    this.scrollPhysics,
    this.autofillHints,
    this.restorationId,
  })  : smartDashesType =
            smartDashesType ?? (obscureText ? SmartDashesType.disabled : null),
        smartQuotesType =
            smartQuotesType ?? (obscureText ? SmartQuotesType.disabled : null),
        assert(maxLines == null || maxLines > 0),
        assert(minLines == null || minLines > 0),
        assert(
          (maxLines == null) || (minLines == null) || (maxLines >= minLines),
          "minLines can't be greater than maxLines",
        ),
        assert(
          !expands || (maxLines == null && minLines == null),
          'minLines and maxLines must be null when expands is true.',
        ),
        assert(!obscureText || maxLines == 1,
            'Obscured fields cannot be multiline.'),
        assert(maxLength == null || maxLength > 0),
        // Assert the following instead of setting it directly to avoid surprising the user by silently changing the value they set.
        assert(
            !identical(textInputAction, TextInputAction.newline) ||
                maxLines == 1 ||
                !identical(keyboardType, TextInputType.text),
            'Use keyboardType TextInputType.multiline when using TextInputAction.newline on a multiline TextField.'),
        keyboardType = keyboardType ??
            (maxLines == 1 ? TextInputType.text : TextInputType.multiline),
        toolbarOptions = toolbarOptions ??
            (obscureText
                ? const ToolbarOptions(
                    selectAll: true,
                    paste: true,
                  )
                : const ToolbarOptions(
                    copy: true,
                    cut: true,
                    selectAll: true,
                    paste: true,
                  ));

  /// Creates a borderless macOS-style text field.
  ///
  /// To provide a prefilled text entry, pass in a [TextEditingController] with
  /// an initial value to the [controller] parameter.
  ///
  /// To provide a hint placeholder text that appears when the text entry is
  /// empty, pass a [String] to the [placeholder] parameter.
  ///
  /// The [maxLines] property can be set to null to remove the restriction on
  /// the number of lines. In this mode, the intrinsic height of the widget will
  /// grow as the number of lines of text grows. By default, it is `1`, meaning
  /// this is a single-line text field and will scroll horizontally when
  /// overflown. [maxLines] must not be zero.
  ///
  /// The text cursor is not shown if [showCursor] is false or if [showCursor]
  /// is null (the default) and [readOnly] is true.
  ///
  /// If specified, the [maxLength] property must be greater than zero.
  ///
  /// The [selectionHeightStyle] and [selectionWidthStyle] properties allow
  /// changing the shape of the selection highlighting. These properties default
  /// to [ui.BoxHeightStyle.tight] and [ui.BoxWidthStyle.tight] respectively and
  /// must not be null.
  ///
  /// The [autocorrect], [autofocus], [clearButtonMode], [dragStartBehavior],
  /// [expands], [maxLengthEnforcement], [obscureText], [prefixMode], [readOnly],
  /// [scrollPadding], [suffixMode], [textAlign], [selectionHeightStyle],
  /// [selectionWidthStyle], and [enableSuggestions] properties must not be null.
  ///
  /// See also:
  ///
  ///  * [minLines], which is the minimum number of lines to occupy when the
  ///    content spans fewer lines.
  ///  * [expands], to allow the widget to size itself to its parent's height.
  ///  * [maxLength], which discusses the precise meaning of "number of
  ///    characters" and how it may differ from the intuitive meaning.
  const MacosTextField.borderless({
    super.key,
    this.controller,
    this.focusNode,
    this.decoration,
    this.focusedDecoration,
    this.margin,
    this.padding = const EdgeInsets.fromLTRB(2.0, 4.0, 2.0, 4.0),
    this.placeholder,
    this.placeholderStyle,
    this.prefix,
    this.prefixMode = OverlayVisibilityMode.always,
    this.suffix,
    this.suffixMode = OverlayVisibilityMode.always,
    this.clearButtonMode = OverlayVisibilityMode.never,
    TextInputType? keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.style,
    this.strutStyle,
    this.textAlign = TextAlign.start,
    this.textAlignVertical,
    this.readOnly = false,
    ToolbarOptions? toolbarOptions,
    this.showCursor,
    this.autofocus = false,
    this.obscuringCharacter = '•',
    this.obscureText = false,
    this.autocorrect = true,
    SmartDashesType? smartDashesType,
    SmartQuotesType? smartQuotesType,
    this.enableSuggestions = true,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
    this.maxLength,
    this.maxLengthEnforcement,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.inputFormatters,
    this.enabled,
    this.cursorWidth = 2.0,
    this.cursorHeight,
    this.cursorRadius = const Radius.circular(2.0),
    this.cursorColor,
    this.selectionHeightStyle = ui.BoxHeightStyle.tight,
    this.selectionWidthStyle = ui.BoxWidthStyle.tight,
    this.keyboardAppearance,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.dragStartBehavior = DragStartBehavior.start,
    this.enableInteractiveSelection = true,
    this.selectionControls,
    this.onTap,
    this.selectionColor,
    this.scrollController,
    this.scrollPhysics,
    this.autofillHints,
    this.restorationId,
  })  : smartDashesType = smartDashesType ??
            (obscureText ? SmartDashesType.disabled : SmartDashesType.enabled),
        smartQuotesType = smartQuotesType ??
            (obscureText ? SmartQuotesType.disabled : SmartQuotesType.enabled),
        assert(maxLines == null || maxLines > 0),
        assert(minLines == null || minLines > 0),
        assert(
          (maxLines == null) || (minLines == null) || (maxLines >= minLines),
          "minLines can't be greater than maxLines",
        ),
        assert(
          !expands || (maxLines == null && minLines == null),
          'minLines and maxLines must be null when expands is true.',
        ),
        assert(!obscureText || maxLines == 1,
            'Obscured fields cannot be multiline.'),
        assert(maxLength == null || maxLength > 0),
        // Assert the following instead of setting it directly to avoid surprising the user by silently changing the value they set.
        assert(
            !identical(textInputAction, TextInputAction.newline) ||
                maxLines == 1 ||
                !identical(keyboardType, TextInputType.text),
            'Use keyboardType TextInputType.multiline when using TextInputAction.newline on a multiline TextField.'),
        keyboardType = keyboardType ??
            (maxLines == 1 ? TextInputType.text : TextInputType.multiline),
        toolbarOptions = toolbarOptions ??
            (obscureText
                ? const ToolbarOptions(
                    selectAll: true,
                    paste: true,
                  )
                : const ToolbarOptions(
                    copy: true,
                    cut: true,
                    selectAll: true,
                    paste: true,
                  ));

  final Color? selectionColor;

  /// Controls the text being edited.
  ///
  /// If null, this widget will create its own [TextEditingController].
  final TextEditingController? controller;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode? focusNode;

  /// Controls the [BoxDecoration] of the box behind the text input.
  ///
  /// Defaults to having a rounded rectangle grey border and can be null to have
  /// no box decoration.
  final BoxDecoration? decoration;

  /// Controls the [BoxDecoration] of the box behind the text input when focused.
  /// This decoration is drawn above [decoration].
  ///
  /// Defaults to having a rounded rectangle blue border and can be null to have
  /// no box decoration.
  final BoxDecoration? focusedDecoration;

  /// Padding around the text entry area between the [prefix] and [suffix]
  /// or the clear button when [clearButtonMode] is not never.
  ///
  /// Defaults to a padding of 6 pixels on all sides and can be null.
  final EdgeInsets? padding;

  /// Padding around the text element. The border of the text field will expand
  /// into this area as needed./// Padding around the text element. The border of the text field will expand
  /// into this area as needed.
  final EdgeInsets? margin;

  /// A lighter colored placeholder hint that appears on the first line of the
  /// text field when the text entry is empty.
  ///
  /// Defaults to having no placeholder text.
  ///
  /// The text style of the placeholder text matches that of the text field's
  /// main text entry except a lighter font weight and a grey font color.
  final String? placeholder;

  /// The style to use for the placeholder text.
  ///
  /// The [placeholderStyle] is merged with the [style] [TextStyle] when applied
  /// to the [placeholder] text. To avoid merging with [style], specify
  /// [TextStyle.inherit] as false.
  ///
  /// Defaults to the [style] property with w300 font weight and grey color.
  ///
  /// If specifically set to null, placeholder's style will be the same as [style].
  final TextStyle? placeholderStyle;

  /// An optional [Widget] to display before the text.
  final Widget? prefix;

  /// Controls the visibility of the [prefix] widget based on the state of
  /// text entry when the [prefix] argument is not null.
  ///
  /// Defaults to [OverlayVisibilityMode.always] and cannot be null.
  ///
  /// Has no effect when [prefix] is null.
  final OverlayVisibilityMode prefixMode;

  /// An optional [Widget] to display after the text.
  final Widget? suffix;

  /// Controls the visibility of the [suffix] widget based on the state of
  /// text entry when the [suffix] argument is not null.
  ///
  /// Defaults to [OverlayVisibilityMode.always] and cannot be null.
  ///
  /// Has no effect when [suffix] is null.
  final OverlayVisibilityMode suffixMode;

  /// Show an macOS-style clear button to clear the current text entry.
  ///
  /// Can be made to appear depending on various text states of the
  /// [TextEditingController].
  ///
  /// Will only appear if no [suffix] widget is appearing.
  ///
  /// Defaults to never appearing and cannot be null.
  final OverlayVisibilityMode clearButtonMode;

  /// {@macro flutter.widgets.editableText.keyboardType}
  final TextInputType keyboardType;

  /// The type of action button to use for the keyboard.
  ///
  /// Defaults to [TextInputAction.newline] if [keyboardType] is
  /// [TextInputType.multiline] and [TextInputAction.done] otherwise.
  final TextInputAction? textInputAction;

  /// {@macro flutter.widgets.editableText.textCapitalization}
  final TextCapitalization textCapitalization;

  /// The style to use for the text being edited.
  ///
  /// Also serves as a base for the [placeholder] text's style.
  ///
  /// Defaults to the standard font style from [MacosTheme] if null.
  final TextStyle? style;

  /// {@macro flutter.widgets.editableText.strutStyle}
  final StrutStyle? strutStyle;

  /// {@macro flutter.widgets.editableText.textAlign}
  final TextAlign? textAlign;

  /// Configuration of toolbar options.
  ///
  /// If not set, select all and paste will default to be enabled. Copy and cut
  /// will be disabled if [obscureText] is true. If [readOnly] is true,
  /// paste and cut will be disabled regardless.
  final ToolbarOptions toolbarOptions;

  /// {@macro flutter.material.InputDecorator.textAlignVertical}
  final TextAlignVertical? textAlignVertical;

  /// {@macro flutter.widgets.editableText.readOnly}
  final bool readOnly;

  /// {@macro flutter.widgets.editableText.showCursor}
  final bool? showCursor;

  /// {@macro flutter.widgets.editableText.autofocus}
  final bool autofocus;

  /// {@macro flutter.widgets.editableText.obscuringCharacter}
  final String? obscuringCharacter;

  /// {@macro flutter.widgets.editableText.obscureText}
  final bool obscureText;

  /// {@macro flutter.widgets.editableText.autocorrect}
  final bool autocorrect;

  /// {@macro flutter.services.TextInputConfiguration.smartDashesType}
  final SmartDashesType? smartDashesType;

  /// {@macro flutter.services.TextInputConfiguration.smartQuotesType}
  final SmartQuotesType? smartQuotesType;

  /// {@macro flutter.services.TextInputConfiguration.enableSuggestions}
  final bool enableSuggestions;

  /// {@macro flutter.widgets.editableText.maxLines}
  final int? maxLines;

  /// {@macro flutter.widgets.editableText.minLines}
  final int? minLines;

  /// {@macro flutter.widgets.editableText.expands}
  final bool expands;

  /// The maximum number of characters (Unicode scalar values) to allow in the
  /// text field.
  ///
  /// After [maxLength] characters have been input, additional input
  /// is ignored, unless [maxLengthEnforcement] is set to
  /// [MaxLengthEnforcement.none].
  ///
  /// The TextField enforces the length with a
  /// [LengthLimitingTextInputFormatter], which is evaluated after the supplied
  /// [inputFormatters], if any.
  ///
  /// This value must be either null or greater than zero. If set to null
  /// (the default), there is no limit to the number of characters allowed.
  ///
  /// Whitespace characters (e.g. newline, space, tab) are included in the
  /// character count.
  ///
  /// {@macro flutter.services.lengthLimitingTextInputFormatter.maxLength}
  final int? maxLength;

  /// Determines how the [maxLength] limit should be enforced.
  ///
  /// If [MaxLengthEnforcement.none] is set, additional input beyond [maxLength]
  /// will not be enforced by the limit.
  ///
  /// {@macro flutter.services.textFormatter.effectiveMaxLengthEnforcement}
  ///
  /// {@macro flutter.services.textFormatter.maxLengthEnforcement}
  final MaxLengthEnforcement? maxLengthEnforcement;

  /// {@macro flutter.widgets.editableText.onChanged}
  final ValueChanged<String>? onChanged;

  /// {@macro flutter.widgets.editableText.onEditingComplete}
  final VoidCallback? onEditingComplete;

  /// {@macro flutter.widgets.editableText.onSubmitted}
  ///
  /// See also:
  ///
  ///  * [TextInputAction.next] and [TextInputAction.previous], which
  ///    automatically shift the focus to the next/previous focusable item when
  ///    the user is done editing.
  final ValueChanged<String>? onSubmitted;

  /// {@macro flutter.widgets.editableText.inputFormatters}
  final List<TextInputFormatter>? inputFormatters;

  /// Disables the text field when false.
  ///
  /// Text fields in disabled states have a light grey background and don't
  /// respond to touch events including the [prefix], [suffix] and the clear
  /// button.
  final bool? enabled;

  /// {@macro flutter.widgets.editableText.cursorWidth}
  final double? cursorWidth;

  /// {@macro flutter.widgets.editableText.cursorHeight}
  final double? cursorHeight;

  /// {@macro flutter.widgets.editableText.cursorRadius}
  final Radius? cursorRadius;

  /// The color to use when painting the cursor.
  ///
  /// Defaults to the [MacosThemeData.primaryColor] of the ambient theme,
  /// which itself defaults to [CupertinoColors.activeBlue] in the light theme
  /// and [CupertinoColors.activeOrange] in the dark theme.
  final Color? cursorColor;

  /// Controls how tall the selection highlight boxes are computed to be.
  ///
  /// See [ui.BoxHeightStyle] for details on available styles.
  final ui.BoxHeightStyle? selectionHeightStyle;

  /// Controls how wide the selection highlight boxes are computed to be.
  ///
  /// See [ui.BoxWidthStyle] for details on available styles.
  final ui.BoxWidthStyle? selectionWidthStyle;

  /// The appearance of the keyboard.
  ///
  /// This setting is only honored on iOS devices.
  ///
  /// If null, defaults to [Brightness.light].
  final Brightness? keyboardAppearance;

  /// {@macro flutter.widgets.editableText.scrollPadding}
  final EdgeInsets? scrollPadding;

  /// {@macro flutter.widgets.editableText.enableInteractiveSelection}
  final bool enableInteractiveSelection;

  /// {@macro flutter.widgets.editableText.selectionControls}
  final TextSelectionControls? selectionControls;

  /// {@macro flutter.widgets.scrollable.dragStartBehavior}
  final DragStartBehavior dragStartBehavior;

  /// {@macro flutter.widgets.editableText.scrollController}
  final ScrollController? scrollController;

  /// {@macro flutter.widgets.editableText.scrollPhysics}
  final ScrollPhysics? scrollPhysics;

  /// {@macro flutter.widgets.editableText.selectionEnabled}
  bool get selectionEnabled => enableInteractiveSelection;

  /// {@macro flutter.material.textfield.onTap}
  final GestureTapCallback? onTap;

  /// {@macro flutter.widgets.editableText.autofillHints}
  /// {@macro flutter.services.AutofillConfiguration.autofillHints}
  final Iterable<String>? autofillHints;

  /// {@macro flutter.material.textfield.restorationId}
  final String? restorationId;

  @override
  State<MacosTextField> createState() => _MacosTextFieldState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<TextEditingController>(
      'controller',
      controller,
      defaultValue: null,
    ));
    properties.add(DiagnosticsProperty<FocusNode>(
      'focusNode',
      focusNode,
      defaultValue: null,
    ));
    properties.add(DiagnosticsProperty<BoxDecoration>(
      'decoration',
      decoration,
      defaultValue: kDefaultRoundedBorderDecoration,
    ));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding));
    properties.add(StringProperty('placeholder', placeholder));
    properties.add(
      DiagnosticsProperty<TextStyle>(
        'placeholderStyle',
        placeholderStyle,
      ),
    );
    properties.add(EnumProperty<OverlayVisibilityMode>(
      'prefix',
      prefix == null ? null : prefixMode,
    ));
    properties.add(EnumProperty<OverlayVisibilityMode>(
      'suffix',
      suffix == null ? null : suffixMode,
    ));
    properties.add(EnumProperty<OverlayVisibilityMode>(
      'clearButtonMode',
      clearButtonMode,
    ));
    properties.add(EnumProperty<TextInputType>(
      'keyboardType',
      keyboardType,
      defaultValue: TextInputType.text,
    ));
    properties.add(DiagnosticsProperty<TextStyle>(
      'style',
      style,
      defaultValue: null,
    ));
    properties.add(DiagnosticsProperty<bool>(
      'autofocus',
      autofocus,
      defaultValue: false,
    ));
    properties.add(DiagnosticsProperty<String>(
      'obscuringCharacter',
      obscuringCharacter,
      defaultValue: '•',
    ));
    properties.add(DiagnosticsProperty<bool>(
      'obscureText',
      obscureText,
      defaultValue: false,
    ));
    properties.add(DiagnosticsProperty<bool>(
      'autocorrect',
      autocorrect,
      defaultValue: true,
    ));
    properties.add(EnumProperty<SmartDashesType>(
      'smartDashesType',
      smartDashesType,
      defaultValue:
          obscureText ? SmartDashesType.disabled : SmartDashesType.enabled,
    ));
    properties.add(EnumProperty<SmartQuotesType>(
      'smartQuotesType',
      smartQuotesType,
      defaultValue:
          obscureText ? SmartQuotesType.disabled : SmartQuotesType.enabled,
    ));
    properties.add(DiagnosticsProperty<bool>(
      'enableSuggestions',
      enableSuggestions,
      defaultValue: true,
    ));
    properties.add(IntProperty('maxLines', maxLines, defaultValue: 1));
    properties.add(IntProperty('minLines', minLines, defaultValue: null));
    properties.add(DiagnosticsProperty<bool>(
      'expands',
      expands,
      defaultValue: false,
    ));
    properties.add(IntProperty('maxLength', maxLength, defaultValue: null));
    properties.add(EnumProperty<MaxLengthEnforcement>(
      'maxLengthEnforcement',
      maxLengthEnforcement,
      defaultValue: null,
    ));
    properties.add(DoubleProperty(
      'cursorWidth',
      cursorWidth,
      defaultValue: 2.0,
    ));
    properties.add(DoubleProperty(
      'cursorHeight',
      cursorHeight,
      defaultValue: null,
    ));
    properties.add(DiagnosticsProperty<Radius>(
      'cursorRadius',
      cursorRadius,
      defaultValue: null,
    ));
    properties.add(createCupertinoColorProperty(
      'cursorColor',
      cursorColor,
      defaultValue: null,
    ));
    properties.add(FlagProperty(
      'selectionEnabled',
      value: selectionEnabled,
      defaultValue: true,
      ifFalse: 'selection disabled',
    ));
    properties.add(DiagnosticsProperty<TextSelectionControls>(
      'selectionControls',
      selectionControls,
      defaultValue: null,
    ));
    properties.add(DiagnosticsProperty<ScrollController>(
      'scrollController',
      scrollController,
      defaultValue: null,
    ));
    properties.add(DiagnosticsProperty<ScrollPhysics>(
      'scrollPhysics',
      scrollPhysics,
      defaultValue: null,
    ));
    properties.add(EnumProperty<TextAlign>(
      'textAlign',
      textAlign,
      defaultValue: TextAlign.start,
    ));
    properties.add(DiagnosticsProperty<TextAlignVertical>(
      'textAlignVertical',
      textAlignVertical,
      defaultValue: null,
    ));
  }
}

class _MacosTextFieldState extends State<MacosTextField>
    with RestorationMixin, AutomaticKeepAliveClientMixin<MacosTextField>
    implements TextSelectionGestureDetectorBuilderDelegate {
  final GlobalKey _clearGlobalKey = GlobalKey();

  RestorableTextEditingController? _controller;
  TextEditingController get _effectiveController =>
      widget.controller ?? _controller!.value;

  FocusNode? _focusNode;
  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_focusNode ??= FocusNode());

  MaxLengthEnforcement get _effectiveMaxLengthEnforcement =>
      widget.maxLengthEnforcement ??
      LengthLimitingTextInputFormatter.getDefaultMaxLengthEnforcement();

  bool _showSelectionHandles = false;

  late _TextFieldSelectionGestureDetectorBuilder
      _selectionGestureDetectorBuilder;

  // API for TextSelectionGestureDetectorBuilderDelegate.
  @override
  bool get forcePressEnabled => true;

  @override
  final GlobalKey<EditableTextState> editableTextKey =
      GlobalKey<EditableTextState>();

  @override
  bool get selectionEnabled => widget.selectionEnabled;
  // End of API for TextSelectionGestureDetectorBuilderDelegate.

  MacosThemeData? _theme;

  @override
  void initState() {
    super.initState();
    _selectionGestureDetectorBuilder =
        _TextFieldSelectionGestureDetectorBuilder(state: this);
    if (widget.controller == null) {
      _createLocalController();
    }
    _effectiveFocusNode.canRequestFocus = widget.enabled ?? true;
    _effectiveFocusNode.addListener(_handleFocusChanged);
  }

  void _handleFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(MacosTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller == null && oldWidget.controller != null) {
      _createLocalController(oldWidget.controller!.value);
    } else if (widget.controller != null && oldWidget.controller == null) {
      unregisterFromRestoration(_controller!);
      _controller!.dispose();
      _controller = null;
    }
    _effectiveFocusNode.canRequestFocus = widget.enabled ?? true;
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    if (_controller != null) {
      _registerController();
    }
  }

  void _registerController() {
    assert(_controller != null);
    registerForRestoration(_controller!, 'controller');
    _controller!.value.addListener(updateKeepAlive);
  }

  void _createLocalController([TextEditingValue? value]) {
    assert(_controller == null);
    _controller = value == null
        ? RestorableTextEditingController()
        : RestorableTextEditingController.fromValue(value);
    if (!restorePending) {
      _registerController();
    }
  }

  @override
  String? get restorationId => widget.restorationId;

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_handleFocusChanged);
    _effectiveController.removeListener(updateKeepAlive);
    _effectiveController.removeListener(updateKeepAlive);
    _focusNode?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  EditableTextState get _editableText => editableTextKey.currentState!;

  void _requestKeyboard() {
    _editableText.requestKeyboard();
  }

  bool _shouldShowSelectionHandles(SelectionChangedCause? cause) {
    // When the text field is activated by something that doesn't trigger the
    // selection overlay, we shouldn't show the handles either.
    if (!_selectionGestureDetectorBuilder.shouldShowSelectionToolbar) {
      return false;
    }

    // On macOS, we don't show handles when the selection is collapsed.
    if (_effectiveController.selection.isCollapsed) return false;

    if (cause == SelectionChangedCause.keyboard) return false;

    if (_effectiveController.text.isNotEmpty) return true;

    return false;
  }

  void _handleSelectionChanged(
    TextSelection selection,
    SelectionChangedCause? cause,
  ) {
    if (cause == SelectionChangedCause.longPress) {
      _editableText.bringIntoView(selection.base);
    }
    final bool willShowSelectionHandles = _shouldShowSelectionHandles(cause);
    if (willShowSelectionHandles != _showSelectionHandles) {
      setState(() {
        _showSelectionHandles = willShowSelectionHandles;
      });
    }
  }

  @override
  bool get wantKeepAlive => _controller?.value.text.isNotEmpty == true;

  bool _shouldShowAttachment({
    required OverlayVisibilityMode attachment,
    required bool hasText,
  }) {
    switch (attachment) {
      case OverlayVisibilityMode.never:
        return false;
      case OverlayVisibilityMode.always:
        return true;
      case OverlayVisibilityMode.editing:
        return hasText;
      case OverlayVisibilityMode.notEditing:
        return !hasText;
    }
  }

  bool _showPrefixWidget(TextEditingValue text) {
    return widget.prefix != null &&
        _shouldShowAttachment(
          attachment: widget.prefixMode,
          hasText: text.text.isNotEmpty,
        );
  }

  bool _showSuffixWidget(TextEditingValue text) {
    return widget.suffix != null &&
        _shouldShowAttachment(
          attachment: widget.suffixMode,
          hasText: text.text.isNotEmpty,
        );
  }

  bool _showClearButton(TextEditingValue text) {
    return _shouldShowAttachment(
      attachment: widget.clearButtonMode,
      hasText: text.text.isNotEmpty,
    );
  }

  // True if any surrounding decoration widgets will be shown.
  bool get _hasDecoration {
    return widget.placeholder != null ||
        widget.clearButtonMode != OverlayVisibilityMode.never ||
        widget.prefix != null ||
        widget.suffix != null;
  }

  // Provide default behavior if widget.textAlignVertical is not set.
  // TextField has top alignment by default, unless it has decoration
  // like a prefix or suffix, in which case it's aligned to the center.
  TextAlignVertical get _textAlignVertical {
    if (widget.textAlignVertical != null) {
      return widget.textAlignVertical!;
    }
    return widget.maxLines == null || widget.maxLines! > 1
        ? TextAlignVertical.center
        : TextAlignVertical.top;
  }

  Widget _addTextDependentAttachments(
    MacosThemeData macTheme,
    MacosTextFieldThemeData theme,
    Widget editableText,
    TextStyle textStyle,
    TextStyle placeholderStyle,
  ) {
    // If there are no surrounding widgets, just return the core editable text
    // part.
    if (!_hasDecoration) {
      return editableText;
    }

    Color iconsColor = macTheme.brightness.isDark
        ? const Color.fromRGBO(255, 255, 255, 0.55)
        : const Color.fromRGBO(0, 0, 0, 0.5);
    if (widget.enabled != null && widget.enabled == false) {
      iconsColor = iconsColor.withOpacity(0.2);
    }

    // Otherwise, listen to the current state of the text entry.
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _effectiveController,
      child: editableText,
      builder: (BuildContext context, TextEditingValue? text, Widget? child) {
        return Row(
          crossAxisAlignment: widget.maxLines == null || widget.maxLines! > 1
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            // Insert a prefix at the front if the prefix visibility mode matches
            // the current text state.
            if (_showPrefixWidget(text!))
              Padding(
                padding: EdgeInsets.only(
                  top: theme.padding!.top,
                  bottom: theme.padding!.bottom,
                  left: 6.0,
                  right: 6.0,
                ),
                child: MacosIconTheme(
                  data: MacosIconThemeData(
                    color: iconsColor,
                    size: 16.0,
                  ),
                  child: widget.prefix!,
                ),
              ),
            // In the middle part, stack the placeholder on top of the main EditableText
            // if needed.
            Expanded(
              child: Stack(
                fit: StackFit.passthrough,
                alignment: widget.maxLines == null || widget.maxLines! > 1
                    ? Alignment.topCenter
                    : Alignment.center,
                children: <Widget>[
                  if (widget.placeholder != null && text.text.isEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding: theme.padding!,
                        child: Text(
                          widget.placeholder!,
                          maxLines: widget.maxLines,
                          overflow: TextOverflow.ellipsis,
                          style: placeholderStyle,
                          textAlign: theme.textAlign,
                        ),
                      ),
                    ),
                  child!,
                ],
              ),
            ),
            // First add the explicit suffix if the suffix visibility mode matches.
            if (_showSuffixWidget(text))
              widget.suffix!
            // Otherwise, try to show a clear button if its visibility mode matches.
            else if (_showClearButton(text))
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  key: _clearGlobalKey,
                  onTap: widget.enabled ?? true
                      ? (() {
                          // Special handle onChanged for ClearButton
                          // Also call onChanged when the clear button is tapped.
                          final bool textChanged =
                              _effectiveController.text.isNotEmpty;
                          _effectiveController.clear();
                          if (widget.onChanged != null && textChanged) {
                            widget.onChanged!(_effectiveController.text);
                          }
                        })
                      : null,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 6.0,
                      right: 6.0,
                      top: theme.padding!.top,
                      bottom: theme.padding!.bottom,
                    ),
                    child: Icon(
                      CupertinoIcons.clear_thick_circled,
                      size: 16.0,
                      color: iconsColor,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  bool get _isFocused => _effectiveFocusNode.hasFocus;
  bool get _isEnabled => widget.enabled ?? true;
  bool get _isDisabled => !_isEnabled;

  /// returns the inner and outer box decorations.  This is to maintain the same
  /// outer shape, while allowing the borders to resize.  The BoxDecoration, after
  /// it's calculated, should be split into border/background

  _TextBoxDecorations _effectiveDecoration(
    BuildContext context,
    MacosThemeData themeData,
    MacosTextFieldThemeData resolvedTheme,
  ) {
    final Color disabledColor =
        MacosDynamicColor.resolve(_kDisabledBackground, context);

    var outer = resolvedTheme.decoration ?? kDefaultBoxDecorationSource;
    if (_isFocused) {
      outer = outer.merge(resolvedTheme.focusedDecoration);
    }
    if (_isDisabled) {
      outer = outer.merge(
        BoxDecoration(
          border: Border.fromBorderSide(
            BorderSide(color: disabledColor),
          ),
        ),
      );
    }

    outer = outer.resolveColors(context, themeData.brightness);

    var innerPadding = resolvedTheme.padding!;
    var outerMargin = resolvedTheme.margin!;
    var decoWidth = resolvedTheme.decoration?.border?.top.width;
    var focusedWidth = resolvedTheme.focusedDecoration?.border?.top.width;
    if (decoWidth != null && focusedWidth != null) {
      final diff = focusedWidth - decoWidth;
      if (diff > 0 && !_isFocused) {
        outerMargin += EdgeInsets.all(diff);
      }
    }
    // Increase padding by the difference in border between focused/unfocused
    return _TextBoxDecorations(
      borderDecoration: outer,
      controlDecoration: const BoxDecoration(),
      margin: outerMargin,
      padding: innerPadding,
    );
  }

  @override
  // ignore: code-metrics
  Widget build(BuildContext context) {
    super.build(context); // See AutomaticKeepAliveClientMixin.
    assert(debugCheckHasDirectionality(context));
    assert(debugCheckHasMacosTheme(context));
    final controller = _effectiveController;

    // ignore: no_leading_underscores_for_local_identifiers
    final _textFieldTheme = theme.textFieldTheme;
    var textFieldTheme =
        _textFieldTheme.resolveWidget(widget, theme.brightness);

    TextSelectionControls? textSelectionControls = widget.selectionControls;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        textSelectionControls ??= cupertinoTextSelectionControls;
        break;

      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
        textSelectionControls ??= cupertinoDesktopTextSelectionControls;
        break;
    }

    final Offset cursorOffset = Offset(
      _iOSHorizontalCursorOffsetPixels /
          MediaQuery.of(context).devicePixelRatio,
      0,
    );
    final List<TextInputFormatter> formatters = <TextInputFormatter>[
      ...?widget.inputFormatters,
      if (widget.maxLength != null)
        LengthLimitingTextInputFormatter(
          widget.maxLength,
          maxLengthEnforcement: _effectiveMaxLengthEnforcement,
        ),
    ];

    final TextStyle? resolvedStyle = (textFieldTheme.style)?.copyWith(
      color:
          MacosDynamicColor.maybeResolve(textFieldTheme.style?.color, context),
      backgroundColor: MacosDynamicColor.maybeResolve(
        textFieldTheme.style?.backgroundColor,
        context,
      ),
    );

    final textStyle = theme.typography.body.merge(resolvedStyle);

    final resolvedPlaceholderStyle = textFieldTheme.placeholderStyle?.copyWith(
      color: MacosDynamicColor.maybeResolve(
        textFieldTheme.placeholderStyle?.color,
        context,
      ),
      backgroundColor: MacosDynamicColor.maybeResolve(
        textFieldTheme.placeholderStyle?.backgroundColor,
        context,
      ),
    );

    final placeholderStyle = textStyle.merge(
      _isEnabled
          ? resolvedPlaceholderStyle?.copyWith(
              fontSize: textStyle.fontSize,
              color: resolvedPlaceholderStyle.color!.withOpacity(0.2),
            )
          : resolvedPlaceholderStyle!.copyWith(
              fontSize: textStyle.fontSize,
              color: resolvedPlaceholderStyle.color!.withOpacity(0.2),
            ),
    );

    final Brightness keyboardAppearance =
        widget.keyboardAppearance ?? theme.brightness;
    Color? cursorColor;
    cursorColor = MacosDynamicColor.maybeResolve(widget.cursorColor, context);
    cursorColor ??=
        theme.brightness.isDark ? MacosColors.white : MacosColors.black;

    final Color selectionColor =
        textFieldTheme.selectionColor ?? MacosColors.selectedTextColor;

    final decorations = _effectiveDecoration(context, theme, textFieldTheme);

    final Widget paddedEditable = Padding(
      padding: decorations.padding,
      child: RepaintBoundary(
        child: UnmanagedRestorationScope(
          bucket: bucket,
          child: EditableText(
            key: editableTextKey,
            controller: controller,
            readOnly: widget.readOnly,
            toolbarOptions: widget.toolbarOptions,
            showCursor: widget.showCursor,
            showSelectionHandles: _showSelectionHandles,
            focusNode: _effectiveFocusNode,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            textCapitalization: widget.textCapitalization,
            style: textStyle,
            strutStyle: textFieldTheme.strutStyle,
            textAlign: textFieldTheme.textAlign!,
            autofocus: widget.autofocus,
            obscuringCharacter: textFieldTheme.obscuringCharacter!,
            obscureText: widget.obscureText,
            autocorrect: widget.autocorrect,
            smartDashesType: textFieldTheme.smartDashesType,
            smartQuotesType: textFieldTheme.smartQuotesType,
            enableSuggestions: widget.enableSuggestions,
            maxLines: widget.maxLines,
            minLines: widget.minLines,
            expands: widget.expands,
            selectionColor: selectionColor,
            selectionControls:
                widget.selectionEnabled ? textSelectionControls : null,
            onChanged: widget.onChanged,
            onSelectionChanged: _handleSelectionChanged,
            onEditingComplete: widget.onEditingComplete,
            onSubmitted: widget.onSubmitted,
            inputFormatters: formatters,
            rendererIgnoresPointer: true,
            cursorWidth: textFieldTheme.cursorWidth!,
            cursorHeight: textFieldTheme.cursorHeight,
            cursorRadius: textFieldTheme.cursorRadius,
            cursorColor: cursorColor,
            cursorOpacityAnimates: true,
            cursorOffset: cursorOffset,
            paintCursorAboveText: true,
            autocorrectionTextRectColor: selectionColor,
            backgroundCursorColor: MacosDynamicColor.resolve(
              CupertinoColors.inactiveGray,
              context,
            ),
            selectionHeightStyle: textFieldTheme.selectionHeightStyle!,
            selectionWidthStyle: textFieldTheme.selectionWidthStyle!,
            scrollPadding: textFieldTheme.scrollPadding!,
            keyboardAppearance: keyboardAppearance,
            dragStartBehavior: widget.dragStartBehavior,
            scrollController: widget.scrollController,
            scrollPhysics: widget.scrollPhysics,
            enableInteractiveSelection: widget.enableInteractiveSelection,
            autofillHints: widget.autofillHints,
            restorationId: 'editable',
            mouseCursor: SystemMouseCursors.text,
          ),
        ),
      ),
    );
    return Semantics(
      enabled: _isEnabled,
      onTap: _isDisabled || widget.readOnly
          ? null
          : () {
              if (!controller.selection.isValid) {
                controller.selection =
                    TextSelection.collapsed(offset: controller.text.length);
              }
              _requestKeyboard();
            },
      child: IgnorePointer(
        ignoring: _isDisabled,
        child: AnimatedContainer(
          /// Value eyeballed from MacOS Big Sur
          duration: const Duration(milliseconds: 125),
          margin: decorations.margin,
          decoration: decorations.borderDecoration,
          child: Container(
            decoration: decorations.controlDecoration,
            child: _selectionGestureDetectorBuilder.buildGestureDetector(
              behavior: HitTestBehavior.translucent,
              child: Align(
                alignment: Alignment(-1.0, _textAlignVertical.y),
                widthFactor: 1.0,
                heightFactor: 1.0,
                child: _addTextDependentAttachments(
                  theme,
                  textFieldTheme,
                  paddedEditable,
                  textStyle,
                  placeholderStyle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  MacosThemeData get theme {
    return _theme ??= MacosTheme.of(context);
  }
}

class _TextBoxDecorations {
  const _TextBoxDecorations({
    required this.borderDecoration,
    required this.controlDecoration,
    required this.margin,
    required this.padding,
  });
  final BoxDecoration? borderDecoration;
  final BoxDecoration? controlDecoration;
  final EdgeInsets margin;
  final EdgeInsets padding;
}
