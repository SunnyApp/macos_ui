import 'package:macos_ui/macos_ui.dart';
import 'package:macos_ui/src/library.dart';

/// A scrollable widget that renders [SidebarItem]s.
///
/// See also:
///
///  * [SidebarItem], the items used by this sidebar
///  * [Sidebar], a side bar used alongside [MacosScaffold]
class SidebarItems extends StatelessWidget {
  /// Creates a scrollable widget that renders [SidebarItem]s.
  const SidebarItems({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onChanged,
    this.itemSize = SidebarItemSize.medium,
    this.shrinkWrap = false,
    this.scrollController,
    this.selectedColor,
    this.unselectedColor,
    this.shape,
    this.cursor = SystemMouseCursors.basic,
  }) : assert(currentIndex >= 0);

  /// The [SidebarElement]s used by the sidebar. If no items are provided,
  /// the sidebar is not rendered.
  final List<SidebarElement> items;

  /// The current selected index. It must be in the range of 0 to
  /// [items.length]
  final int currentIndex;

  /// Called when the current selected index should be changed.
  final ValueChanged<int> onChanged;

  /// The size specifications for all [items].
  ///
  /// Defaults to [SidebarItemSize.medium].
  final SidebarItemSize itemSize;

  /// The scroll controller used by this sidebar. If null, a local scroll
  /// controller is created.
  final ScrollController? scrollController;

  final bool shrinkWrap;

  /// The color to paint the item when it's selected.
  ///
  /// If null, [MacosThemeData.primaryColor] is used.
  final Color? selectedColor;

  /// The color to paint the item when it's unselected.
  ///
  /// Defaults to transparent.
  final Color? unselectedColor;

  /// The [shape] property specifies the outline (border) of the
  /// decoration. The shape must not be null. It's used alongside
  /// [selectedColor].
  final ShapeBorder? shape;

  /// Specifies the kind of cursor to use for all sidebar items.
  ///
  /// Defaults to [SystemMouseCursors.basic].
  final MouseCursor? cursor;

  List<SidebarElement> get _allItems => [
        for (var element in items) ...[
          element,
          if (element.disclosureItems != null)
            for (final disc in element.disclosureItems!) disc,
        ],
      ];

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    assert(debugCheckHasMacosTheme(context));
    assert(_allItems.isEmpty || currentIndex < _allItems.length);
    final theme = MacosTheme.of(context);
    return IconTheme.merge(
      data: const IconThemeData(size: 20),
      child: SidebarItemsConfiguration(
        data: SidebarItemsData.ofTheme(theme),
        child: ListView(
          shrinkWrap: shrinkWrap,
          controller: scrollController,
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.all(10.0 - theme.visualDensity.horizontal),
          children: List.generate(items.length, (index) {
            final item = items[index];
            return item is SidebarDivider
                ? const Divider()
                : item is! SidebarItem
                    ? Container()
                    : !item.isSelectable &&
                            item.disclosureItems?.isNotEmpty != true
                        ? MacosSidebarLabel(item: item)
                        : MouseRegion(
                            cursor: cursor!,
                            child: (item.disclosureItems?.isNotEmpty == true)
                                ? _DisclosureSidebarItem(
                                    item: item,
                                    selected: _allItems[currentIndex] == item,
                                    selectedItem: _allItems[currentIndex],
                                    onChanged: (newItem) {
                                      onChanged(_allItems.indexOf(newItem));
                                      newItem.onTap?.call();
                                    },
                                  )
                                : MacosSidebarItem(
                                    type: SidebarItemType.main,
                                    item: item,
                                    selected: _allItems[currentIndex] == item,
                                    onClick: () {
                                      onChanged(_allItems.indexOf(item));
                                      item.onTap?.call();
                                    },
                                  ),
                          );
          }),
        ),
      ),
    );
  }
}

const kExpanderBaseWidth = 12.0;
const kExpanderPadding = EdgeInsets.only(left: 4.0, right: 2.0);
final kExpanderWidth =
    kExpanderBaseWidth + (kExpanderPadding.left + kExpanderPadding.right);
var kBaseVerticalPadding = 7.0;
var kBaseHorizontalPadding = 10.0;

/// A macOS style navigation-list item intended for use in a [Sidebar]
class MacosSidebarItem extends StatefulWidget {
  /// Builds a [MacosSidebarItem].
  const MacosSidebarItem({
    super.key,
    required this.item,
    required this.onClick,
    required this.selected,
    required this.type,
  });

  final SidebarItemType type;

  /// The widget to lay out first.
  ///
  /// Typically an [Icon]
  final SidebarItem item;

  /// Whether the item is selected or not
  final bool selected;

  /// A function to perform when the widget is clicked or tapped.
  ///
  /// Typically a [Navigator] call
  final VoidCallback? onClick;

  @override
  State<MacosSidebarItem> createState() => _MacosSidebarItemState();
}

class _MacosSidebarItemState extends State<MacosSidebarItem> {
  bool _hover = false;
  void _handleActionTap() async {
    widget.onClick?.call();
  }

  set _hovering(bool hovering) {
    if (_hover != hovering) {
      if (mounted) {
        setState(() {
          _hover = hovering;
        });
      }
    }
  }

  Map<Type, Action<Intent>> get _actionMap => <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (ActivateIntent intent) => _handleActionTap(),
        ),
        ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
          onInvoke: (ButtonActivateIntent intent) => _handleActionTap(),
        ),
      };

  bool get hasLeading => widget.item.leading != null;

  bool get hasTrailing => widget.item.trailing != null;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMacosTheme(context));
    final theme = MacosTheme.of(context);

    var sidebarConfig = SidebarItemsConfiguration.of(context);

    final double spacing =
        kBaseHorizontalPadding + theme.visualDensity.horizontal;
    final itemSize = widget.item.size ?? sidebarConfig.itemSize;

    final foregroundColor = widget.selected
        ? sidebarConfig.selectedScheme!.foregroundColor
        : sidebarConfig.unselectedScheme!.foregroundColor;
    final labelStyle = itemSize.textStyle(theme).merge(
          (widget.selected
                  ? sidebarConfig.selectedScheme!.textStyle
                  : sidebarConfig.unselectedScheme!.textStyle)
              .copyWith(color: foregroundColor),
        );

    late EdgeInsets padding;

    switch (widget.type) {
      case SidebarItemType.main:
        padding = EdgeInsets.only(
          top: kBaseVerticalPadding + theme.visualDensity.horizontal,
          bottom: kBaseVerticalPadding + theme.visualDensity.horizontal,
          right: spacing,
          left: kExpanderWidth,
        );
        break;
      case SidebarItemType.disclosure:
        padding = EdgeInsets.only(
          top: kBaseVerticalPadding + theme.visualDensity.horizontal,
          bottom: kBaseVerticalPadding + theme.visualDensity.horizontal,
          right: spacing,
          left: 0,
        );

        break;
      case SidebarItemType.child:
        padding = EdgeInsets.only(
          top: kBaseVerticalPadding + theme.visualDensity.horizontal,
          bottom: kBaseVerticalPadding + theme.visualDensity.horizontal,
          right: spacing,
          left: kExpanderWidth,
        );

        break;
    }

    return Semantics(
      label: widget.item.semanticLabel,
      button: true,
      focusable: true,
      focused: widget.item.focusNode?.hasFocus,
      enabled: widget.onClick != null,
      selected: widget.selected,
      child: MouseRegion(
        onEnter: (_) => _hovering = true,
        onExit: (_) => _hovering = false,
        child: GestureDetector(
          onTap: widget.onClick,
          onSecondaryTap: widget.item.onContextMenu,
          child: FocusableActionDetector(
            focusNode: widget.item.focusNode,
            descendantsAreFocusable: false,
            enabled: widget.onClick != null,
            //mouseCursor: SystemMouseCursors.basic,
            actions: _actionMap,
            child: Container(
              width: 134.0 + theme.visualDensity.horizontal,
              height: itemSize.height +
                  theme.visualDensity.vertical +
                  kBaseVerticalPadding,
              decoration: ShapeDecoration(
                color: _hover
                    ? widget.selected
                        ? sidebarConfig.selectedScheme!.hoverColor
                        : sidebarConfig.unselectedScheme!.hoverColor
                    : widget.selected
                        ? sidebarConfig.selectedScheme!.backgroundColor
                        : sidebarConfig.unselectedScheme!.backgroundColor,
                shape: widget.item.shape ?? sidebarConfig.shape,
              ),
              padding: padding,
              child: Row(
                children: [
                  if (hasLeading)
                    Padding(
                      padding: EdgeInsets.only(right: spacing),
                      child: MacosIconTheme.merge(
                        data: MacosIconThemeData(
                          color: foregroundColor,
                          size: itemSize.iconSize,
                        ),
                        child:
                            Builder(builder: (context) => widget.item.leading!),
                      ),
                    ),
                  DefaultTextStyle(
                    style: labelStyle,
                    child: widget.item.label != null
                        ? Text(widget.item.label!, style: labelStyle)
                        : widget.item.labelWidget!,
                  ),
                  if (hasTrailing) ...[
                    const Spacer(),
                    DefaultTextStyle(
                      style: labelStyle.copyWith(
                        color: widget.selected
                            ? sidebarConfig.selectedScheme!.foregroundColor
                            : sidebarConfig.selectedScheme!.foregroundColor,
                      ),
                      child: widget.item.trailing!,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MacosSidebarLabel extends StatelessWidget {
  /// Builds a [MacosSidebarItem].
  const MacosSidebarLabel({
    super.key,
    required this.item,
  });

  /// The widget to lay out first.
  ///
  /// Typically an [Icon]
  final SidebarItem item;

  bool get hasLeading => item.leading != null;
  bool get hasTrailing => item.trailing != null;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMacosTheme(context));
    final theme = MacosTheme.of(context);

    final sidebarConfig = SidebarItemsConfiguration.of(context);

    final double spacing =
        kBaseHorizontalPadding + theme.visualDensity.horizontal;
    final itemSize = item.size ?? sidebarConfig.itemSize;
    var labelStyle = itemSize.textStyle(theme);

    return Semantics(
      label: item.semanticLabel,
      button: false,
      focusable: false,
      enabled: true,
      selected: false,
      child: DefaultTextStyle(
        style: labelStyle,
        child: Container(
          width: 134.0 + theme.visualDensity.horizontal,
          height: itemSize.height + theme.visualDensity.vertical,
          padding: EdgeInsets.symmetric(
            vertical: kBaseVerticalPadding + theme.visualDensity.horizontal,
            horizontal: spacing,
          ),
          child: Row(
            children: [
              if (hasLeading)
                Padding(
                  padding: EdgeInsets.only(right: spacing),
                  child: MacosIconTheme.merge(
                    data: MacosIconThemeData(
                      color: MacosColors.controlAccentColor,
                      size: itemSize.iconSize,
                    ),
                    child: item.leading!,
                  ),
                ),
              item.label != null
                  ? Text(item.label!, style: labelStyle)
                  : item.labelWidget!,
              if (hasTrailing) ...[
                const Spacer(),
                item.trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DisclosureSidebarItem extends StatefulWidget {
  // ignore: use_super_parameters
  _DisclosureSidebarItem({
    Key? key,
    required this.item,
    this.selectedItem,
    required this.selected,
    this.onChanged,
  })  : assert(item.disclosureItems != null),
        super(key: key);

  final bool selected;

  final SidebarElement item;

  final SidebarElement? selectedItem;

  /// A function to perform when the widget is clicked or tapped.
  ///
  /// Typically a [Navigator] call
  final ValueChanged<SidebarItem>? onChanged;

  @override
  __DisclosureSidebarItemState createState() => __DisclosureSidebarItemState();
}

const Duration _kExpand = Duration(milliseconds: 200);

class __DisclosureSidebarItemState extends State<_DisclosureSidebarItem>
    with SingleTickerProviderStateMixin {
  static final Animatable<double> _easeInTween =
      CurveTween(curve: Curves.easeIn);
  static final Animatable<double> _halfTween =
      Tween<double>(begin: 0.0, end: 0.25);

  late AnimationController _controller;
  late Animation<double> _iconTurns;
  late Animation<double> _heightFactor;

  late bool _isExpanded;

  bool get hasLeading => widget.item.asItem()?.leading != null;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.item.asItem()?.expanded == true;
    _controller = AnimationController(
      duration: _kExpand,
      vsync: this,
      value: _isExpanded ? 1.0 : 0.0,
    );
    _heightFactor = _controller.drive(_easeInTween);
    _iconTurns = _controller.drive(_halfTween.chain(_easeInTween));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() {
      _isExpanded = !_isExpanded;
      widget.onChanged!(widget.item as SidebarItem);
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse().then<void>((void value) {
          if (!mounted) return;
          setState(() {
            // Rebuild without widget.children.
          });
        });
      }
      PageStorage.of(context)?.writeState(context, _isExpanded);
    });

    // widget.onExpansionChanged?.call(_isExpanded);
  }

  Widget _buildChildren(BuildContext context, Widget? child) {
    final theme = MacosTheme.of(context);

    var sidebarConfig = SidebarItemsConfiguration.of(context);
    final itemSize = widget.item.asItem()?.size ?? sidebarConfig.itemSize;

    final foregroundColor = widget.selected
        ? sidebarConfig.selectedScheme!.foregroundColor
        : sidebarConfig.unselectedScheme!.foregroundColor;
    final labelStyle = itemSize.textStyle(theme).merge(
          (widget.selected
                  ? sidebarConfig.selectedScheme!.textStyle
                  : sidebarConfig.unselectedScheme!.textStyle)
              .copyWith(color: foregroundColor),
        );

    final item = widget.item;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: item is SidebarDivider
              ? const Divider()
              : item is! SidebarItem
                  ? Container()
                  : MacosSidebarItem(
                      type: SidebarItemType.disclosure,
                      item: SidebarItem(
                        onContextMenu: item.onContextMenu,
                        onTap: item.onTap,
                        size: item.size,
                        label: item.label,
                        leading: Row(
                          children: [
                            Padding(
                              padding: kExpanderPadding,
                              child: RotationTransition(
                                turns: _iconTurns,
                                child: Icon(
                                  CupertinoIcons.chevron_right,
                                  size: kExpanderBaseWidth,
                                  color: foregroundColor,
                                ),
                              ),
                            ),
                            if (hasLeading)
                              Padding(
                                padding: const EdgeInsets.only(left: 0),
                                child: MacosIconTheme.merge(
                                  data: MacosIconThemeData(
                                    size: itemSize.iconSize,
                                    color: foregroundColor,
                                  ),
                                  child: item.leading!,
                                ),
                              ),
                          ],
                        ),
                        unselectedColor: MacosColors.transparent,
                        focusNode: item.focusNode,
                        semanticLabel: item.semanticLabel,
                        shape: item.shape,
                        trailing: item.trailing,
                      ),
                      onClick: _handleTap,
                      selected: widget.selected,
                    ),
        ),
        ClipRect(
          child: DefaultTextStyle(
            style: labelStyle,
            child: Align(
              alignment: Alignment.centerLeft,
              heightFactor: _heightFactor.value,
              child: child,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMacosTheme(context));
    final theme = MacosTheme.of(context);

    final bool closed = !_isExpanded && _controller.isDismissed;

    final Widget result = Offstage(
      offstage: closed,
      child: TickerMode(
        enabled: !closed,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final disclosureItem in widget.item.disclosureItems!)
              Padding(
                padding: EdgeInsets.only(
                  left: 24.0 + theme.visualDensity.horizontal,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: disclosureItem is SidebarDivider
                      ? const Divider()
                      : disclosureItem is! SidebarItem
                          ? Container()
                          : MacosSidebarItem(
                              type: SidebarItemType.child,
                              item: disclosureItem,
                              onClick: () =>
                                  widget.onChanged?.call(disclosureItem),
                              selected: widget.selectedItem == disclosureItem,
                            ),
                ),
              ),
          ],
        ),
      ),
    );

    return AnimatedBuilder(
      animation: _controller.view,
      builder: _buildChildren,
      child: closed ? null : result,
    );
  }
}

extension on SidebarElement {
  SidebarItem? asItem() {
    return this is SidebarItem ? this as SidebarItem : null;
  }
}
