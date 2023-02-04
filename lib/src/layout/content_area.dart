import 'package:macos_ui/src/indicators/scrollbar.dart';
import 'package:macos_ui/src/layout/scaffold.dart';
import 'package:macos_ui/src/library.dart';

/// The widget that fills the rest of the body of the macOS [MacosScaffold].
///
/// A [MacosScaffold] can contain only one [ContentArea].
class ContentArea extends StatefulWidget {
  /// Creates a widget that fills the body of the scaffold.
  /// The [builder] can be null to show an empty widget.
  ///
  /// The width of this
  /// widget is automatically calculated in [MacosScaffoldScope].
  const ContentArea({
    required this.builder,
    this.scrollController,
    this.showScrollbar = false,
    this.minWidth = 300,
  }) : super(key: const Key('macos_scaffold_content_area'));

  /// The builder that creates a child to display in this widget, which will
  /// use the provided [_scrollController] to enable the scrollbar to work.
  ///
  /// Pass the [_scrollController] obtained from this method, to a scrollable
  /// widget used in this method to work with the internal [MacosScrollbar].
  final ScrollableWidgetBuilder? builder;
  final bool showScrollbar;

  /// Specifies the minimum width that this [ContentArea] can have.
  final double minWidth;

  final ScrollController? scrollController;

  @override
  State<ContentArea> createState() => _ContentAreaState();
}

class _ContentAreaState extends State<ContentArea> {
  ScrollController? _scrollController;
  bool _wasCreated = false;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController;
  }

  @override
  void dispose() {
    if (_wasCreated) {
      _scrollController?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_scrollController == null) {
      _scrollController = PrimaryScrollController.of(context);
      if (_scrollController == null) {
        _wasCreated = true;
        _scrollController = ScrollController();
      }
    }
    final mq = MediaQuery.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: mq.size.width,
        maxHeight: mq.size.height,
      ).copyWith(
        minWidth: widget.minWidth,
      ),
      child: SafeArea(
        left: false,
        right: false,
        child: widget.showScrollbar
            ? MacosScrollbar(
                controller: _scrollController,
                child: widget.builder!(
                  context,
                  _scrollController!,
                ),
              )
            : widget.builder!(
                context,
                _scrollController!,
              ),
      ),
    );
  }
}
