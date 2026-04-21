import 'package:flutter/material.dart';

/// 首页页面主体（Dashboard Tab）。
///
/// 深色 Header 由 [MainShell] 的专属 AppBar 提供，此 Widget 只负责主体内容区。
/// 当前为占位内容，对齐 uni-app 首页 "首页内容占位" 的显示状态。
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
          child: Center(
            child: Text(
              '首页内容占位',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
