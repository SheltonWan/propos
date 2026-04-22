import 'package:flutter/cupertino.dart';

/// 首页页面主体（Dashboard Tab）。
///
/// 深色 Header 由 [MainShell] 的专属 [_DashboardNavBar] 提供，此 Widget 只负责主体内容区。
/// 当前为占位内容，对齐 uni-app 首页 "首页内容占位" 的显示状态。
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        // iOS 风格卡片：圆角 + 柔和阴影
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey4.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
        child: const Center(
          child: Text(
            '首页内容占位',
            style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ),
      ),
    );
  }
}
