import 'package:flutter/foundation.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:macos_ui/src/layout/sidebar/sidebar_config.dart';
import 'package:macos_ui/src/library.dart';

abstract class SidebarElement {
  List<SidebarElement>? get disclosureItems => null;
  bool get isSelectable => false;
  String? get key => null;

  const SidebarElement();
}

class SidebarDivider extends SidebarElement {
  const SidebarDivider([this.key]);

  @override
  final String? key;
}

/// A macOS style navigation-list item intended for use in a [Sidebar]
///
/// See also:
///
///  * [Sidebar], a side bar used alongside [MacosScaffold]
///  * [SidebarItems], the widget that displays [SidebarItem]s vertically
class SidebarItem with Diagnosticable implements SidebarElement {
  /// Creates a sidebar item.
  const SidebarItem({
    required this.size,
    this.key,
    this.leading,
    this.label,
    this.labelWidget,
    this.isSelectable = true,
    this.selectedColor,
    this.unselectedColor,
    this.shape,
    this.focusNode,
    this.semanticLabel,
    this.expanded = false,
    this.disclosureItems,
    this.trailing,
    this.onTap,
    required this.onContextMenu,
  }) : assert(
          label != null || labelWidget != null,
        );

  @override
  final String? key;

  /// Whether disclosure items (if they exist), should start out expanded.
  final bool expanded;

  final VoidCallback? onTap;
  final VoidCallback? onContextMenu;

  /// An overridden size for this item.
  final SidebarItemSize? size;

  /// Whether this item can be focused
  @override
  final bool isSelectable;

  /// The widget before [label].
  ///
  /// Typically an [Icon]
  final Widget? leading;

  /// Indicates what content this widget represents.
  ///
  /// Typically a [Text]
  final String? label;

  final Widget? labelWidget;

  /// The color to paint this widget as when selected.
  ///
  /// If null, [MacosThemeData.primaryColor] is used.
  final Color? selectedColor;

  /// The color to paint this widget as when unselected.
  ///
  /// Defaults to transparent.
  final Color? unselectedColor;

  /// The [shape] property specifies the outline (border) of the
  /// decoration. The shape must not be null. It's used alonside
  /// [selectedColor].
  final ShapeBorder? shape;

  /// The focus node used by this item.
  final FocusNode? focusNode;

  /// The semantic label used by screen readers.
  final String? semanticLabel;

  /// The disclosure items. If null, there will be no disclosure items.
  ///
  /// If non-null and [leading] is null, a local animated icon is created
  @override
  final List<SidebarElement>? disclosureItems;

  /// An optional trailing widget.
  ///
  /// Typically a text indicator of a count of items, like in this
  /// screenshots from the Apple Notes app:
  /// {@image <img src="https://imgur.com/REpW9f9.png" height="88" width="219" />}
  final Widget? trailing;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('selectedColor', selectedColor));
    properties.add(ColorProperty('unselectedColor', unselectedColor));
    properties.add(StringProperty('semanticLabel', semanticLabel));
    properties.add(DiagnosticsProperty<ShapeBorder>('shape', shape));
    properties.add(DiagnosticsProperty<FocusNode>('focusNode', focusNode));
    properties.add(IterableProperty<SidebarElement>(
      'disclosure items',
      disclosureItems,
    ));
    properties.add(DiagnosticsProperty<Widget?>('trailing', trailing));
  }

  SidebarItem copyWith({
    String? key,
    bool? expanded,
    VoidCallback? onTap,
    VoidCallback? onContextMenu,
    SidebarItemSize? size,
    bool? isSelectable,
    Widget? leading,
    String? label,
    Widget? labelWidget,
    Color? selectedColor,
    Color? unselectedColor,
    ShapeBorder? shape,
    FocusNode? focusNode,
    String? semanticLabel,
    List<SidebarElement>? disclosureItems,
    Widget? trailing,
  }) {
    return SidebarItem(
      key: key ?? this.key,
      expanded: expanded ?? this.expanded,
      onTap: onTap ?? this.onTap,
      onContextMenu: onContextMenu ?? this.onContextMenu,
      size: size ?? this.size,
      isSelectable: isSelectable ?? this.isSelectable,
      leading: leading ?? this.leading,
      label: label ?? this.label,
      labelWidget: labelWidget ?? this.labelWidget,
      selectedColor: selectedColor ?? this.selectedColor,
      unselectedColor: unselectedColor ?? this.unselectedColor,
      shape: shape ?? this.shape,
      focusNode: focusNode ?? this.focusNode,
      semanticLabel: semanticLabel ?? this.semanticLabel,
      disclosureItems: disclosureItems ?? this.disclosureItems,
      trailing: trailing ?? this.trailing,
    );
  }
}
