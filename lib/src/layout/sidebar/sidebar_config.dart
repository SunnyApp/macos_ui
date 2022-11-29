import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../theme/macos_colors.dart';

const ShapeBorder _defaultShape = RoundedRectangleBorder(
  //TODO: consider changing to 4.0 or 5.0 - App Store, Notes and Mail seem to use 4.0 or 5.0
  borderRadius: BorderRadius.all(Radius.circular(5.0)),
);

/// {@template sidebarItemSize}
/// Enumerates the size specifications of [SidebarItem]s
///
/// Values were adapted from https://developer.apple.com/design/human-interface-guidelines/components/navigation-and-search/sidebars/#platform-considerations
/// and were eyeballed against apps like App Store, Notes, and Mail.
/// {@endtemplate}
enum SidebarItemSize {
  /// A small [SidebarItem]. Has a [height] of 24 and an [iconSize] of 12.
  small(24.0, 12.0),

  /// A medium [SidebarItem]. Has a [height] of 28 and an [iconSize] of 16.
  medium(29.0, 16.0),

  /// A large [SidebarItem]. Has a [height] of 32 and an [iconSize] of 20.0.
  large(36.0, 18.0);

  /// {@macro sidebarItemSize}
  const SidebarItemSize(
    this.height,
    this.iconSize,
  );

  /// The height of the [SidebarItem].
  final double height;

  /// The maximum size of the [SidebarItem]'s leading icon.
  final double iconSize;

  TextStyle textStyle(MacosThemeData theme) {
    switch (this) {
      case SidebarItemSize.small:
        return theme.typography.caption2;
      case SidebarItemSize.medium:
        return theme.typography.body;
      case SidebarItemSize.large:
        return theme.typography.title2;
    }
  }
}

class SidebarColorScheme {
  const SidebarColorScheme({
    required this.foregroundColor,
    required this.backgroundColor,
    required this.hoverColor,
    required this.textStyle,
  });

  final Color foregroundColor;
  final Color backgroundColor;
  final Color hoverColor;
  final TextStyle textStyle;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SidebarColorScheme &&
          runtimeType == other.runtimeType &&
          foregroundColor == other.foregroundColor &&
          backgroundColor == other.backgroundColor &&
          hoverColor == other.hoverColor;

  @override
  int get hashCode =>
      foregroundColor.hashCode ^ backgroundColor.hashCode ^ hoverColor.hashCode;
}

class SidebarItemsData {
  const SidebarItemsData({
    this.selectedScheme,
    this.unselectedScheme,
    this.shape = _defaultShape,
    this.itemSize = SidebarItemSize.medium,
  });

  factory SidebarItemsData.ofTheme(MacosThemeData theme) {
    return SidebarItemsData(
      selectedScheme: SidebarColorScheme(
        hoverColor: theme.primaryColor.withOpacity(0.95),
        backgroundColor: theme.primaryColor,
        foregroundColor: MacosColors.white,
        textStyle: const TextStyle(inherit: true, fontWeight: FontWeight.w600),
      ),
      unselectedScheme: SidebarColorScheme(
        hoverColor: MacosColors.lightHover,
        backgroundColor: MacosColors.transparent,
        foregroundColor: theme.typography.body.color!,
        textStyle: const TextStyle(
          inherit: true,
        ),
      ),
    );
  }

  final SidebarColorScheme? selectedScheme;
  final SidebarColorScheme? unselectedScheme;
  final ShapeBorder shape;
  final SidebarItemSize itemSize;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SidebarItemsData &&
          runtimeType == other.runtimeType &&
          selectedScheme == other.selectedScheme &&
          unselectedScheme == other.unselectedScheme &&
          shape == other.shape &&
          itemSize == other.itemSize;

  @override
  int get hashCode =>
      selectedScheme.hashCode ^
      unselectedScheme.hashCode ^
      shape.hashCode ^
      itemSize.hashCode;
}

class SidebarItemsConfiguration extends InheritedWidget {
  const SidebarItemsConfiguration({
    super.key,
    required super.child,
    required this.data,
  });

  final SidebarItemsData data;

  static SidebarItemsData of(BuildContext context) {
    final existing = context
        .dependOnInheritedWidgetOfExactType<SidebarItemsConfiguration>()
        ?.data;
    if (existing != null) {
      return existing;
    } else {
      return SidebarItemsData.ofTheme(MacosTheme.of(context));
    }
  }

  @override
  bool updateShouldNotify(SidebarItemsConfiguration oldWidget) {
    return data != oldWidget.data;
  }
}

enum SidebarItemType { main, disclosure, child }
