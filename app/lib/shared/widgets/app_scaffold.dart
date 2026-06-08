import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.refreshIndicator,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Future<void> Function()? refreshIndicator;

  @override
  Widget build(BuildContext context) {
    Widget content = body;
    if (refreshIndicator != null) {
      content = RefreshIndicator(
        onRefresh: refreshIndicator!,
        child: body is ScrollView
            ? body
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [SizedBox(height: MediaQuery.sizeOf(context).height * 0.85, child: body)],
              ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: subtitle == null
            ? Text(title)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
        actions: actions,
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: content,
    );
  }
}

class AppPagePadding extends StatelessWidget {
  const AppPagePadding({super.key, required this.child, this.bottom = AppSpacing.xxl});

  final Widget child;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.page, AppSpacing.md, AppSpacing.page, bottom),
      child: child,
    );
  }
}
