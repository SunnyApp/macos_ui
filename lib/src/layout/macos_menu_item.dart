import 'package:flutter/material.dart';
import 'package:macos_ui/src/layout/sidebar/sidebar_item.dart';
import 'package:macos_ui/src/layout/sidebar/sidebar_items.dart';
import 'package:macos_ui/src/theme/macos_theme.dart';

import '../../macos_ui.dart';

abstract class MacosMenuItemThemeData {
  TextStyle? get style;

  TextStyle? get hoverStyle;

  Color? get backgroundColor;

  Color? get hoverColor;

  static MacosMenuItemThemeData lerp(
    MacosMenuItemThemeData menuItemTheme,
    MacosMenuItemThemeData menuItemTheme2,
    double t,
  ) {
    return menuItemTheme2;
  }
}

extension DefaultMacosMenuItemMergeExt on MacosMenuItemThemeData {
  MacosMenuItemThemeData merge(MacosMenuItemThemeData? other) {
    if (other == null) return this;
    return DefaultMacosMenuItemThemeData(
      style: style == null ? other.style : style!.merge(other.style),
      hoverStyle: hoverStyle == null
          ? other.hoverStyle
          : hoverStyle!.merge(other.hoverStyle),
      backgroundColor: other.backgroundColor ?? backgroundColor,
      hoverColor: other.hoverColor ?? hoverColor,
    );
  }

  MacosMenuItemThemeData resolve(MacosThemeData theme) {
    return merge(DefaultMacosMenuItemThemeData.fromTheme(theme));
  }
}

class DefaultMacosMenuItemThemeData implements MacosMenuItemThemeData {
  const DefaultMacosMenuItemThemeData({
    this.style,
    this.hoverStyle,
    this.backgroundColor,
    this.hoverColor,
  });

  DefaultMacosMenuItemThemeData.fromTheme(MacosThemeData theme)
      : backgroundColor = Colors.transparent,
        hoverColor = theme.primaryColor,
        style = const TextStyle(fontSize: 12),
        hoverStyle = const TextStyle(fontSize: 12);

  @override
  final TextStyle? style;

  @override
  final TextStyle? hoverStyle;

  @override
  final Color? backgroundColor;

  @override
  final Color? hoverColor;
}

/// A widget that aims to approximate the [ListTile] widget found in
/// Flutter's material library.
class MacosMenuItem extends StatefulWidget implements MacosMenuItemThemeData {
  /// Builds a [MacosListTile].
  const MacosMenuItem({
    super.key,
    this.size,
    this.leading,
    this.title,
    this.titleWidget,
    this.onClick,
    this.style,
    this.hoverStyle,
    this.backgroundColor,
    this.hoverColor,
  }) : assert(titleWidget != null || title != null);

  /// A widget to display before the [title].
  final Widget? leading;

  /// The primary content of the list tile.
  final String? title;

  final Widget? titleWidget;

  /// A callback to perform when the widget is clicked.
  final VoidCallback? onClick;

  @override
  final TextStyle? style;
  @override
  final TextStyle? hoverStyle;
  @override
  final Color? backgroundColor;
  @override
  final Color? hoverColor;

  final SidebarItemSize? size;

  @override
  State<MacosMenuItem> createState() => _MacosMenuItemState();
}

class _MacosMenuItemState extends State<MacosMenuItem> {
  bool _hovered = false;

  void updateHover(bool hovered) {
    if (hovered != _hovered) {
      if (mounted) {
        setState(() {
          _hovered = hovered;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var macosThemeData = MacosTheme.of(context);
    var mergedData =
        widget.merge(macosThemeData.menuItemTheme).resolve(macosThemeData);
    return MouseRegion(
      opaque: true,
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        updateHover(true);
      },
      onExit: (_) => updateHover(false),
      child: Container(
        padding: EdgeInsets.zero,
        decoration: BoxDecoration(
          color: _hovered ? mergedData.hoverColor : mergedData.backgroundColor,
          borderRadius: BorderRadius.circular(7),
        ),
        child: MacosSidebarItem(
          type: SidebarItemType.main,
          // padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          // height: 28,
          item: SidebarItem(
            onContextMenu: null,
            size: widget.size ?? SidebarItemSize.large,
            label: widget.title,
            labelWidget: widget.titleWidget,
            leading: widget.leading,
            unselectedColor: mergedData.backgroundColor,
            selectedColor: mergedData.hoverColor,
          ),
          selected: _hovered,
          onClick: widget.onClick,
        ),
      ),
    );
  }
}
