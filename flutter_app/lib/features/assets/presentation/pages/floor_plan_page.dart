import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart' show Factory;
import 'package:flutter/gestures.dart' show ScaleGestureRecognizer;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/api/api_paths.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/theme/custom_colors.dart';
import '../../../../shared/widgets/status_tag.dart';
import '../../domain/entities/heatmap.dart';
import '../../domain/entities/unit_status.dart';
import '../bloc/floor_map_cubit.dart';
import '../bloc/floor_map_state.dart';

/// 楼层平面图页（子页面，含独立 Scaffold）。
///
/// 当楼层有 SVG 时用 webview_flutter 渲染热区（支持 CSS class 状态色 + JS 点击回传）；
/// 否则展示房源状态网格列表（备用方案）。
class FloorPlanPage extends StatefulWidget {
  final String buildingId;
  final String floorId;

  const FloorPlanPage({
    super.key,
    required this.buildingId,
    required this.floorId,
  });

  @override
  State<FloorPlanPage> createState() => _FloorPlanPageState();
}

class _FloorPlanPageState extends State<FloorPlanPage> {
  HeatmapUnit? _selectedUnit;

  @override
  void initState() {
    super.initState();
    context.read<FloorMapCubit>().fetch(widget.floorId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CupertinoNavigationBar(
        middle: const Text('楼层热区图'),
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocBuilder<FloorMapCubit, FloorMapState>(
        builder: (context, state) => switch (state) {
          FloorMapStateInitial() || FloorMapStateLoading() => const Center(
              child: CupertinoActivityIndicator(),
            ),
          FloorMapStateError(:final message) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(message,
                      style: TextStyle(
                          color: Theme.of(context)
                              .extension<CustomColors>()!
                              .danger)),
                  const SizedBox(height: 12),
                  CupertinoButton(
                    onPressed: () =>
                        context.read<FloorMapCubit>().fetch(widget.floorId),
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          FloorMapStateLoaded(heatmap: final heatmap) =>
            _buildContent(context, heatmap),
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, FloorHeatmap heatmap) {
    return Column(
      children: [
        Expanded(
          child: heatmap.svgPath != null
              ? _FloorImageViewer(
                  imagePath: heatmap.svgPath!,
                  units: heatmap.units,
                  onUnitTap: (unit) => setState(() {
                    _selectedUnit = unit;
                    _showUnitBottomSheet(context, unit);
                  }),
                )
              : _UnitGrid(
                  units: heatmap.units,
                  selectedUnit: _selectedUnit,
                  onUnitTap: (unit) => setState(() {
                    _selectedUnit = unit;
                    _showUnitBottomSheet(context, unit);
                  }),
                ),
        ),
        _LegendBar(),
      ],
    );
  }

  void _showUnitBottomSheet(BuildContext context, HeatmapUnit unit) {
    final statusStr = unit.currentStatus.name == 'expiringSoon'
        ? 'expiring_soon'
        : unit.currentStatus.name;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.38,
        decoration: BoxDecoration(
          color: CupertinoTheme.of(ctx).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              // 拖动指示条
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey3,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 单元号 + 状态标签
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        unit.unitNumber,
                        style: CupertinoTheme.of(
                          ctx,
                        ).textTheme.navTitleTextStyle,
                      ),
                    ),
                    StatusTag(status: statusStr),
                  ],
                ),
              ),
              if (unit.tenantName != null) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        '租户：',
                        style: TextStyle(
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            ctx,
                          ),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        unit.tenantName!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
              if (unit.contractEndDate != null) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Text(
                        '到期日：',
                        style: TextStyle(
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            ctx,
                          ),
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        DateFormat(
                          'yyyy-MM-dd',
                        ).format(unit.contractEndDate!.toLocal()),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              // 查看详情按钮
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: CupertinoButton.filled(
                  onPressed: () {
                    Navigator.pop(ctx);
                    final path = RoutePaths.unitDetail.replaceAll(
                      ':id',
                      unit.unitId,
                    );
                    context.push(path);
                  },
                  child: const Text('查看详情'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 楼层 SVG 平面图（WebView 渲染）。
///
/// 加载完成后注入 JS，根据 API 返回的状态给 [data-unit-id] 元素追加 CSS class，
/// 并绑定点击事件通过 FlutterChannel 回传 DB UUID。
class _FloorImageViewer extends StatefulWidget {
  final String imagePath;

  /// 热区单元列表（用于叠加点击层）。
  final List<HeatmapUnit> units;

  /// 选中某个单元的回调。
  final void Function(HeatmapUnit) onUnitTap;

  const _FloorImageViewer({
    required this.imagePath,
    required this.units,
    required this.onUnitTap,
  });

  @override
  State<_FloorImageViewer> createState() => _FloorImageViewerState();
}

class _FloorImageViewerState extends State<_FloorImageViewer> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  /// 异步初始化 WebViewController：读取 token → 带 Authorization 头加载 SVG URL。
  ///
  /// 页面加载完成后注入 JS，完成两件事：
  ///   1. 根据 API 返回的单元状态给 SVG [data-unit-id] 元素追加对应 CSS class；
  ///   2. 给每个 [data-unit-id] 元素绑定点击事件，通过 FlutterChannel 回传 unitId（DB UUID）。
  Future<void> _initWebView() async {
    final storage = GetIt.instance<FlutterSecureStorage>();
    final token = await storage.read(key: 'access_token');
    final fullUrl = ApiPaths.fileProxyUrl(
      AppConfig.apiBaseUrl,
      widget.imagePath,
    );

    // 将所有单元序列化为 JS 可用的 JSON 数组。
    // SVG data-unit-id 格式为 "11-01"（floor-room），DB unit_number 格式为 "1101"；
    // JS 侧用去除连字符的规范化字符串进行模糊匹配。
    final unitsJson = widget.units
        .map(
          (u) =>
              '{"id":"${u.unitId}","num":"${u.unitNumber}","cls":"${_statusToCssClass(u.currentStatus)}"}',
        )
        .join(',');

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (msg) {
          // 收到 SVG 元素点击回传的 DB UUID，精确匹配后回调。
          final unitId = msg.message;
          final matched = widget.units.where((u) => u.unitId == unitId);
          if (matched.isNotEmpty) widget.onUnitTap(matched.first);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) async {
            // _controller 在 loadRequest 之后、页面实际完成之前已赋值，此处安全调用。
            await _controller?.runJavaScript(_buildInjectJs(unitsJson));
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
          onWebResourceError: (WebResourceError error) {
            // 只有主帧（Main Frame）失败才视为致命错误；
            // 子资源（CSS/字体等）报错忽略，避免误报。
            if (error.isForMainFrame != true) return;
            if (mounted) {
              setState(() {
                _isLoading = false;
                _hasError = true;
              });
            }
          },
        ),
      )
      ..loadRequest(
        Uri.parse(fullUrl),
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      );

    if (mounted) setState(() => _controller = controller);
  }

  /// 将 [UnitStatus] 枚举映射为 postprocess_svg.py 注入的 CSS class 名。
  String _statusToCssClass(UnitStatus status) => switch (status) {
    UnitStatus.leased => 'unit-leased',
    UnitStatus.vacant => 'unit-vacant',
    UnitStatus.expiringSoon => 'unit-expiring-soon',
    UnitStatus.nonLeasable => 'unit-non-leasable',
  };

  /// 生成注入 WebView 的 JavaScript 片段。
  ///
  /// SVG `data-unit-id` 与 DB `unit_number` 存在格式差异（如 "11-01" vs "1101"），
  /// 采用三级匹配策略（优先级递减）：
  ///   1. 精确匹配 `data-unit-id` 与 unitNumber；
  ///   2. 规范化匹配（去掉连字符/空格后比较）；
  ///   3. 匹配 `data-unit-number`（纯房号，如 "01"）与 unitNumber 末尾。
  String _buildInjectJs(String unitsJson) => '''
(function() {
  var units = [$unitsJson];

  // 按 unitNumber 和规范化后的 unitNumber（去连字符/空格）建立双索引。
  var byNum = {};
  var byNorm = {};
  units.forEach(function(u) {
    byNum[u.num] = u;
    byNorm[u.num.replace(/[-\\s]/g, '')] = u;
  });

  var allClasses = ['unit-leased','unit-vacant','unit-expiring-soon','unit-renovating','unit-non-leasable'];

  document.querySelectorAll('[data-unit-id]').forEach(function(el) {
    var svgId  = el.getAttribute('data-unit-id')     || '';
    var svgNum = el.getAttribute('data-unit-number') || '';
    var normId = svgId.replace(/[-\\s]/g, '');

    // 三级匹配：精确 → 规范化 → 纯房号后缀
    var unit = byNum[svgId]
      || byNorm[normId]
      || (svgNum ? units.find(function(u) {
           return u.num.endsWith(svgNum) || u.num === svgNum;
         }) : null);

    if (!unit) return;

    allClasses.forEach(function(c) { el.classList.remove(c); });
    el.classList.add(unit.cls);
    el.style.cursor = 'pointer';
    el.addEventListener('click', function(e) {
      e.stopPropagation();
      // 回传 DB UUID，Flutter 侧精确查找。
      FlutterChannel.postMessage(unit.id);
    });
  });
})();
''';

  @override
  Widget build(BuildContext context) {
    if (_controller == null || _isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (_hasError) {
      return Center(
        child: Text(
          '平面图加载失败，请检查网络连接',
          style: TextStyle(
            color: Theme.of(context).extension<CustomColors>()!.danger,
          ),
        ),
      );
    }
    // 热区点击已通过 JS FlutterChannel 处理，无需 Flutter 层叠加覆盖。
    return WebViewWidget(
      controller: _controller!,
      gestureRecognizers: {
        Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
      },
    );
  }
}

/// 状态色例 Legend 条。
class _LegendBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: const Row(
        children: [
          _LegendItem(status: UnitStatus.leased),
          SizedBox(width: 12),
          _LegendItem(status: UnitStatus.vacant),
          SizedBox(width: 12),
          _LegendItem(status: UnitStatus.expiringSoon),
          SizedBox(width: 12),
          _LegendItem(status: UnitStatus.nonLeasable),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final UnitStatus status;

  const _LegendItem({required this.status});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CustomColors>()!;
    final color = switch (status) {
      UnitStatus.leased => colors.success,
      UnitStatus.expiringSoon => colors.warning,
      UnitStatus.vacant => colors.danger,
      UnitStatus.nonLeasable => colors.neutral,
    };
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(status.label,
            style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

/// 房源状态网格（无平面图时的备用方案）。
class _UnitGrid extends StatelessWidget {
  final List<HeatmapUnit> units;
  final HeatmapUnit? selectedUnit;
  final void Function(HeatmapUnit) onUnitTap;

  const _UnitGrid({
    required this.units,
    required this.selectedUnit,
    required this.onUnitTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CustomColors>()!;
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.4,
      ),
      itemCount: units.length,
      itemBuilder: (context, index) {
        final unit = units[index];
        final color = switch (unit.currentStatus) {
          UnitStatus.leased => colors.success,
          UnitStatus.expiringSoon => colors.warning,
          UnitStatus.vacant => colors.danger,
          UnitStatus.nonLeasable => colors.neutral,
        };
        final isSelected = selectedUnit?.unitId == unit.unitId;
        return GestureDetector(
          onTap: () => onUnitTap(unit),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isSelected ? 0.3 : 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? color : color.withValues(alpha: 0.4),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    unit.unitNumber,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color),
                    textAlign: TextAlign.center,
                  ),
                  if (unit.tenantName != null)
                    Text(
                      unit.tenantName!,
                      style: TextStyle(
                          fontSize: 10,
                          color: color.withValues(alpha: 0.8)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
