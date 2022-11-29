import 'package:macos_ui/macos_ui.dart';
import 'package:macos_ui/src/library.dart';

/// Asserts that the given context has a [MacosTheme] ancestor.
///
/// To call this function, use the following pattern, typically in the
/// relevant Widget's build method:
///
/// ```dart
/// assert(debugCheckHasMacosTheme(context));
/// ```
///
/// Does nothing if asserts are disabled. Always returns true.
bool debugCheckHasMacosTheme(BuildContext context, [bool check = true]) {
  assert(() {
    if (MacosTheme.maybeOf(context) == null) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('A MacosTheme widget is necessary to draw this layout.'),
        ErrorHint(
          'To introduce a MacosTheme widget, you can either directly '
          'include one, or use a widget that contains MacosTheme itself, '
          'such as MacosApp',
        ),
        ...context.describeMissingAncestor(expectedAncestorType: MacosTheme),
      ]);
    }
    return true;
  }());
  return true;
}

Color textLuminance(Color backgroundColor) {
  return backgroundColor.computeLuminance() >= 0.5
      ? CupertinoColors.black
      : CupertinoColors.white;
}

Color helpIconLuminance(Color backgroundColor, bool isDark) {
  return !isDark
      ? backgroundColor.computeLuminance() > 0.5
          ? CupertinoColors.black
          : CupertinoColors.white
      : backgroundColor.computeLuminance() < 0.5
          ? CupertinoColors.black
          : CupertinoColors.white;
}

Color iconLuminance(Color backgroundColor, bool isDark) {
  if (isDark) {
    return backgroundColor.computeLuminance() > 0.5
        ? CupertinoColors.black
        : CupertinoColors.white;
  } else {
    return backgroundColor.computeLuminance() > 0.5
        ? CupertinoColors.black
        : CupertinoColors.white;
  }
}

String intToMonthAbbr(int month) {
  switch (month) {
    case 1:
      return 'Jan';
    case 2:
      return 'Feb';
    case 3:
      return 'Mar';
    case 4:
      return 'Apr';
    case 5:
      return 'May';
    case 6:
      return 'Jun';
    case 7:
      return 'Jul';
    case 8:
      return 'Aug';
    case 9:
      return 'Sep';
    case 10:
      return 'Oct';
    case 11:
      return 'Nov';
    case 12:
      return 'Dev';
    default:
      throw Exception('Unsupported value');
  }
}

class Unsupported {
  const Unsupported(this.message);

  final String message;
}

extension ColorResolveAll on Color {
  Color resolveAll(BuildContext context) {
    return CupertinoDynamicColor.resolve(
      MacosDynamicColor.resolve(this, context),
      context,
    );
  }
}

extension BorderSideMergeExt on BorderSide {
  BorderSide merge(BorderSide? fromSide, [BorderSide? source]) {
    return fromSide == null
        ? this
        : source == null
            ? fromSide
            : BorderSide(
                color: fromSide.color == source.color ? color : fromSide.color,
                style: fromSide.style == source.style ? style : fromSide.style,
                width: fromSide.width == source.width ? width : fromSide.width,
                strokeAlign: fromSide.strokeAlign == source.strokeAlign
                    ? strokeAlign
                    : fromSide.strokeAlign,
              );
  }

  BorderSide resolveColor(BuildContext context) {
    return copyWith(
      color: color.resolveAll(context),
    );
  }
}

BorderDirectional? mergeBorderDirectional(
  BorderDirectional? self,
  BorderDirectional? other, [
  BorderDirectional? source,
]) {
  return self == null
      ? other
      : other == null
          ? self
          : source == null
              ? other
              : BorderDirectional(
                  top: self.top.merge(other.top, source.top),
                  bottom: self.bottom.merge(other.bottom, source.bottom),
                  start: self.start.merge(other.start, source.start),
                  end: self.end.merge(other.end, source.end),
                );
}

Border? mergeBorder(
  Border? self,
  Border? other, [
  Border source = const Border.fromBorderSide(BorderSide()),
]) {
  return self == null
      ? other
      : other == null
          ? self
          : Border(
              top: self.top.merge(other.top, source.top),
              bottom: self.bottom.merge(other.bottom, source.bottom),
              left: self.left.merge(other.left, source.left),
              right: self.right.merge(other.right, source.right),
            );
}

const kdefaultBorderValue = Border.fromBorderSide(BorderSide());

extension BoxBorderMergeExt on BoxBorder? {
  BoxBorder? merge(BoxBorder? other, [BoxBorder? source]) {
    source ??= kdefaultBorderValue;
    if (other == null) return this;
    if (this == null) return other;
    final self = this;
    if (self is BorderDirectional &&
        other is BorderDirectional &&
        source is BorderDirectional) {
      return mergeBorderDirectional(self, other, source);
    } else if (self is Border && other is Border && source is Border) {
      return mergeBorder(self, other, source);
    } else {
      // Convert all to directional first, assuming ltr
      return mergeBorderDirectional(
        self.toDirectional(),
        other.toDirectional(),
        source.toDirectional(),
      );
    }
  }

  BoxBorder? resolveColors(BuildContext context) {
    final self = this;
    if (self == null) return null;
    if (self is BorderDirectional) {
      return BorderDirectional(
        top: self.top.resolveColor(context),
        bottom: self.bottom.resolveColor(context),
        start: self.start.resolveColor(context),
        end: self.end.resolveColor(context),
      );
    } else if (self is Border) {
      return Border(
        top: self.top.resolveColor(context),
        bottom: self.bottom.resolveColor(context),
        left: self.left.resolveColor(context),
        right: self.right.resolveColor(context),
      );
    } else {
      return error('Cannot resolve colors of $runtimeType');
    }
  }

  BorderDirectional? toDirectional() {
    final self = this;
    if (self == null) {
      return null;
    }
    return self is BorderDirectional
        ? self
        : self is Border
            ? BorderDirectional(
                top: self.top,
                bottom: self.bottom,
                start: self.left,
                end: self.right,
              )
            : error<BorderDirectional>(
                'Cannot convert $runtimeType to BorderDirectional',
              );
  }
}

T error<T>([String? message]) {
  throw StateError(message ?? 'Illegal state');
}

const kDefaultBoxDecorationSource = BoxDecoration();

extension BoxDecorationMergeExt on BoxDecoration? {
  BoxDecoration? merge(
    BoxDecoration? other, [
    BoxDecoration source = kDefaultBoxDecorationSource,
  ]) {
    final self = this;
    if (self == null) return other;
    if (other == null) return self;
    return self.copyWith(
      color: other.color ?? self.color,
      image: other.image ?? self.image,
      border: self.border.merge(other.border, source.border),
      borderRadius: other.borderRadius ?? self.borderRadius,
      boxShadow: other.boxShadow ?? self.boxShadow,
      gradient: other.gradient ?? self.gradient,
      backgroundBlendMode:
          other.backgroundBlendMode ?? self.backgroundBlendMode,
      shape: other.shape,
    );
  }
}

extension BoxDecorationMergeExtNonNull on BoxDecoration {
  BoxDecoration merge(
    BoxDecoration? other, [
    BoxDecoration source = kDefaultBoxDecorationSource,
  ]) {
    return BoxDecorationMergeExt(this).merge(other, source) ??
        error("Must return a valid decoration");
  }

  BoxDecoration resolveColors(BuildContext context, Brightness brightness) {
    var decorationColor = MacosDynamicColor.maybeResolve(color, context);

    /// Replace hard black colors with something softer
    if (decorationColor is ResolvedMacosDynamicColor) {
      if (decorationColor.color == const Color(0xffffffff) ||
          (decorationColor).darkColor == const Color(0xff000000)) {
        decorationColor = brightness.isDark
            ? const Color.fromRGBO(30, 30, 30, 1)
            : MacosColors.white;
      }
    }

    return copyWith(
      color: decorationColor,
      border: border?.resolveColors(context),
    );
  }
}
