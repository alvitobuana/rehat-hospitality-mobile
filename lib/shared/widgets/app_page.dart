import 'package:flutter/material.dart';
import '../../core/design_system/app_colors.dart';
import '../../core/design_system/app_insets.dart';

class AppPage extends StatelessWidget {
  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final Widget? bottomAction;
  final bool useSafeArea;
  final bool scrollable;
  final PreferredSizeWidget? appBar;
  final Widget? leading;
  final Future<void> Function()? onRefresh;
  final EdgeInsetsGeometry? padding;

  const AppPage({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.bottomAction,
    this.useSafeArea = true,
    this.scrollable = true,
    this.appBar,
    this.leading,
    this.onRefresh,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    PreferredSizeWidget? computedAppBar = appBar;
    if (computedAppBar == null && title != null) {
      computedAppBar = AppBar(
        title: Text(title!),
        actions: actions,
        leading: leading,
      );
    }

    final computedPadding = padding ?? EdgeInsets.only(
      left: AppInsets.s24,
      right: AppInsets.s24,
      top: AppInsets.s24,
      bottom: AppInsets.s24 + (bottomAction != null ? 0.0 : AppInsets.bottomSafe(context)),
    );

    Widget bodyWidget = child;
    if (scrollable) {
      bodyWidget = SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: computedPadding,
        child: bodyWidget,
      );
    }

    if (onRefresh != null) {
      bodyWidget = RefreshIndicator(
        onRefresh: onRefresh!,
        child: bodyWidget,
      );
    }

    if (useSafeArea) {
      bodyWidget = SafeArea(
        top: computedAppBar == null,
        bottom: bottomAction == null,
        child: bodyWidget,
      );
    }

    // Wrap in a Column if we have bottomAction
    if (bottomAction != null) {
      bodyWidget = Column(
        children: [
          Expanded(child: bodyWidget),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                left: AppInsets.s24,
                right: AppInsets.s24,
                top: AppInsets.s8,
                bottom: AppInsets.s16 + AppInsets.bottomSafe(context),
              ),
              child: bottomAction!,
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: computedAppBar,
        backgroundColor: AppColors.background(context),
        body: bodyWidget,
      ),
    );
  }
}
