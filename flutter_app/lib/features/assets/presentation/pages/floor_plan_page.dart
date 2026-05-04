import 'dart:convert';
import 'dart:io';

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
  String _currentLayer = 'status'; // 'status' | 'expiry'

  @override
  void initState() {
    super.initState();
    context.read<FloorMapCubit>().fetch(widget.floorId);
  }

  @override
  Widget build(BuildContext context) {
    // 加载完成后显示 "楼栋名 楼层名 楼层图"，其余状态显示通用标题。
    final title = context.select<FloorMapCubit, String>((cubit) {
      final s = cubit.state;
      return s is FloorMapStateLoaded
          ? '${s.floor.buildingName} ${s.floor.displayName} 楼层图'
          : '楼层热区图';
    });

    return Scaffold(
      appBar: CupertinoNavigationBar(
        middle: Text(title),
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
        // 图层切换（出租状态 / 到期预警）
        _LayerToggle(
          currentLayer: _currentLayer,
          onLayerChanged: (layer) => setState(() => _currentLayer = layer),
        ),
        Expanded(
          child: heatmap.svgPath != null
              ? _FloorImageViewer(
                  imagePath: heatmap.svgPath!,
                  units: heatmap.units,
                  layer: _currentLayer,
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
        _LegendBar(layer: _currentLayer),
        if (heatmap.units.isNotEmpty) _StatsBar(units: heatmap.units),
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

  /// 当前图层模式（'status' | 'expiry'）。
  final String layer;

  /// 选中某个单元的回调。
  final void Function(HeatmapUnit) onUnitTap;

  const _FloorImageViewer({
    required this.imagePath,
    required this.units,
    required this.layer,
    required this.onUnitTap,
  });

  @override
  State<_FloorImageViewer> createState() => _FloorImageViewerState();
}

class _FloorImageViewerState extends State<_FloorImageViewer> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  double _zoom = 1.0;
  static const double _zoomMin = 0.6;
  static const double _zoomMax = 2.8;
  static const double _zoomStep = 0.3;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  @override
  void didUpdateWidget(_FloorImageViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 图层切换时调用 HTML 内预定义的 FlutterSetLayer 函数，无需重新注入 JS。
    if (oldWidget.layer != widget.layer && _controller != null && !_isLoading) {
      _controller!
          .runJavaScript('try{FlutterSetLayer("${widget.layer}");}catch(e){}')
          .catchError((_) {});
    }
  }

  /// 应用缩放比例。
  ///
  /// 调用 HTML 模板内预定义的 `FlutterSetZoom(scale)` 函数，
  /// 该函数通过 `transform: scale()` 缩放 `#wrap` 容器，并同步扩展
  /// `body` 尺寸以确保 WebView 滚动视口跟随，放大后可拖动查看边角。
  Future<void> _applyZoom(double zoom) async {
    final clamped = zoom.clamp(_zoomMin, _zoomMax);
    if (mounted) setState(() => _zoom = clamped);
    if (_controller == null || _isLoading) return;
    try {
      await _controller!.runJavaScript(
        'try{FlutterSetZoom($clamped);}catch(e){}',
      );
    } catch (_) {
      // iOS WKWebView 偶发 PlatformException，静默忽略。
    }
  }

  /// 初始化 WebView：用 dart:io HttpClient 携带 token 拉取 SVG 内容，
  /// 将其内联到 HTML 模板后通过 loadHtmlString 加载。
  ///
  /// 这样避免了直接 loadRequest SVG 文件时 WebKit 进入 SVG 文档模式
  /// （该模式下 CSS zoom/transform 行为异常，无法可靠缩放）。
  Future<void> _initWebView() async {
    final storage = GetIt.instance<FlutterSecureStorage>();
    final token = await storage.read(key: 'access_token');
    final fullUrl = ApiPaths.fileProxyUrl(
      AppConfig.apiBaseUrl,
      widget.imagePath,
    );

    // ── Step 1：拉取 SVG 内容 ────────────────────────────────────────────────
    String svgContent;
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(fullUrl));
      if (token != null) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'HTTP ${response.statusCode}',
          uri: Uri.parse(fullUrl),
        );
      }
      svgContent = await response.transform(utf8.decoder).join();
      client.close();
    } catch (_) {
      if (mounted)
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      return;
    }

    // ── Step 2：构建 WebViewController 并加载 HTML ───────────────────────────
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (msg) {
          final unitId = msg.message;
          final matched = widget.units.where((u) => u.unitId == unitId);
          if (matched.isNotEmpty) widget.onUnitTap(matched.first);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
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
      ..loadHtmlString(_buildHtml(svgContent, _buildUnitsJson(), widget.layer),
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

  /// 将所有单元序列化为 JS 可用的 JSON 字符串（含状态 CSS class 与合同到期日）。
  String _buildUnitsJson() => widget.units
      .map(
        (u) =>
            '{"id":"${u.unitId}","num":"${u.unitNumber}",'
            '"statusCls":"${_statusToCssClass(u.currentStatus)}",'
            '"endDate":"${u.contractEndDate?.toIso8601String() ?? ""}"}',
      )
      .join(',');

  /// 构建包含内联 SVG 的 HTML 模板。
  ///
  /// SVG 内联到标准 HTML `#wrap div` 中，缩放通过 `transform: scale()` 实现，
  /// 完全规避了 WebKit SVG 文档模式下 zoom/transform 行为不一致的问题。
  ///
  /// 导出两个全局函数供 Dart 通过 runJavaScript 调用：
  ///   - `FlutterSetZoom(scale)` —— 缩放
  ///   - `FlutterSetLayer(layer)` —— 切换图层着色
  String _buildHtml(String svgContent, String unitsJson, String layer) {
    // 防御性处理：SVG 内容中若含 </script> 标签会破坏 HTML，做转义。
    final safeSvg = svgContent.replaceAll('</script>', r'<\/script>');
    return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=5.0, user-scalable=yes">
<style>
* { margin: 0; padding: 0; box-sizing: border-box; }
html, body { background: #fff; overflow: auto; }
/* wrap 是缩放锚点，transform-origin 左上角确保放大从左上展开 */
#wrap { display: block; transform-origin: 0 0; line-height: 0; }
/* 强制 SVG 初始填满视口宽度，规避 ezdxf 输出的 mm/px 绝对尺寸在内联模式下超出屏幕的问题 */
#wrap svg { display: block; width: 100vw !important; height: auto !important; max-width: none !important; }
</style>
</head>
<body>
<div id="wrap">$safeSvg</div>
<script>
(function() {
  var units = [$unitsJson];
  var _layer = '$layer';
  // 自然尺寸在 DOMContentLoaded 后从渲染结果（offsetWidth/Height）读取，
  // 不使用 viewBox 坐标值（SVG 坐标系与屏幕 px 可能差异悬殊）。
  var _naturalW = 0, _naturalH = 0;

  // 按 unitNumber 和规范化后的 unitNumber（去连字符/空格）建立双索引。
  var byNum = {}, byNorm = {};
  units.forEach(function(u) {
    byNum[u.num] = u;
    byNorm[u.num.replace(/[-\\s]/g, '')] = u;
  });

  var allCls = ['unit-leased','unit-vacant','unit-expiring-soon','unit-renovating','unit-non-leasable'];

  // 三级匹配策略：精确 → 规范化 → 纯房号后缀。
  function resolveUnit(el) {
    var svgId  = el.getAttribute('data-unit-id')     || '';
    var svgNum = el.getAttribute('data-unit-number') || '';
    var normId = svgId.replace(/[-\\s]/g, '');
    return byNum[svgId] || byNorm[normId]
      || (svgNum ? units.find(function(u) {
           return u.num.endsWith(svgNum) || u.num === svgNum;
         }) : null);
  }

  // 根据图层模式计算目标 CSS class。
  function toCls(unit, layerMode) {
    if (layerMode !== 'expiry' || !unit.endDate) return unit.statusCls;
    var diffDays = (new Date(unit.endDate).getTime() - Date.now()) / 86400000;
    if (unit.statusCls === 'unit-non-leasable' || unit.statusCls === 'unit-vacant') return unit.statusCls;
    if (diffDays > 90) return 'unit-leased';
    if (diffDays > 30) return 'unit-expiring-soon';
    return 'unit-vacant';
  }

  // 更新所有已匹配元素的 CSS class（切换图层时复用）。
  function applyLayer(layerMode) {
    document.querySelectorAll('[data-unit-id]').forEach(function(el) {
      var unit = resolveUnit(el);
      if (!unit) return;
      allCls.forEach(function(c) { el.classList.remove(c); });
      el.classList.add(toCls(unit, layerMode));
    });
  }

  // 绑定点击事件（只绑一次）。
  function bindClicks() {
    document.querySelectorAll('[data-unit-id]').forEach(function(el) {
      el.addEventListener('click', function(e) {
        e.stopPropagation();
        var unit = resolveUnit(el);
        if (unit) FlutterChannel.postMessage(unit.id);
      });
      el.style.cursor = 'pointer';
    });
  }

  // Dart 侧调用：缩放。
  window.FlutterSetZoom = function(scale) {
    var wrap = document.getElementById('wrap');
    if (!wrap) return;
    wrap.style.transform = 'scale(' + scale + ')';
    // 同步扩展 body 尺寸，使 WebView 原生滚动视口跟随缩放区域，放大后可拖动查看边角。
    document.body.style.width  = Math.ceil(_naturalW * scale) + 'px';
    document.body.style.height = Math.ceil(_naturalH * scale) + 'px';
  };

  // Dart 侧调用：切换图层着色。
  window.FlutterSetLayer = function(newLayer) {
    _layer = newLayer;
    applyLayer(newLayer);
  };

  document.addEventListener('DOMContentLoaded', function() {
    var wrap = document.getElementById('wrap');
    if (wrap) {
      // 读取 CSS 渲染后的实际像素尺寸（SVG 已被 CSS 缩放为 100vw，此时 offsetWidth 就是屏幕宽）。
      _naturalW = wrap.offsetWidth  || 800;
      _naturalH = wrap.offsetHeight || 600;
    }
    applyLayer(_layer);
    bindClicks();
  });
})();
</script>
</body>
</html>''';
  }

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
    return Stack(
      children: [
        WebViewWidget(
          controller: _controller!,
          gestureRecognizers: {
            Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
          },
        ),
        // 右下角缩放控制按鈕（对齐 uni-app zoom-controls）
        Positioned(
          right: 12,
          bottom: 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ZoomButton(
                icon: CupertinoIcons.plus,
                onTap: () => _applyZoom(_zoom + _zoomStep),
              ),
              const SizedBox(height: 6),
              _ZoomButton(
                label: '适',
                highlight: true,
                onTap: () => _applyZoom(1.0),
              ),
              const SizedBox(height: 6),
              _ZoomButton(
                icon: CupertinoIcons.minus,
                onTap: () => _applyZoom(_zoom - _zoomStep),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 状态色例 Legend 条（根据图层模式显示对应图例）。
class _LegendBar extends StatelessWidget {
  final String layer;

  const _LegendBar({required this.layer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: layer == 'expiry'
          ? const Row(
              children: [
                _LegendItem(status: UnitStatus.leased, label: '90天以上'),
                SizedBox(width: 12),
                _LegendItem(status: UnitStatus.expiringSoon, label: '30-90天'),
                SizedBox(width: 12),
                _LegendItem(status: UnitStatus.vacant, label: '30天内'),
                SizedBox(width: 12),
                _LegendItem(status: UnitStatus.nonLeasable),
              ],
            )
          : const Row(
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
  final String? label;

  const _LegendItem({required this.status, this.label});

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
        Text(label ?? status.label,
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

// ─────────────────────────────────────────────────────────────────────────────
// 图层切换
// ─────────────────────────────────────────────────────────────────────────────

/// 图层切换按钮组（出租状态 / 到期预警），对齐 uni-app layer-toggle。
class _LayerToggle extends StatelessWidget {
  final String currentLayer;
  final void Function(String) onLayerChanged;

  const _LayerToggle({
    required this.currentLayer,
    required this.onLayerChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          _ToggleBtn(
            label: '出租状态',
            active: currentLayer == 'status',
            onTap: () => onLayerChanged('status'),
          ),
          const SizedBox(width: 8),
          _ToggleBtn(
            label: '到期预警',
            active: currentLayer == 'expiry',
            onTap: () => onLayerChanged('expiry'),
          ),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = CupertinoTheme.of(context).primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? primary
              : CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active
                ? primary
                : CupertinoColors.systemGrey4.resolveFrom(context),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: active
                ? CupertinoColors.white
                : CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 楼层统计栏
// ─────────────────────────────────────────────────────────────────────────────

/// 楼层统计栏（已租/空置/可租总量/出租率），对齐 uni-app stats-bar。
class _StatsBar extends StatelessWidget {
  final List<HeatmapUnit> units;

  const _StatsBar({required this.units});

  @override
  Widget build(BuildContext context) {
    final leased = units
        .where(
          (u) =>
              u.currentStatus == UnitStatus.leased ||
              u.currentStatus == UnitStatus.expiringSoon,
        )
        .length;
    final vacant = units
        .where((u) => u.currentStatus == UnitStatus.vacant)
        .length;
    final totalLeasable = units
        .where((u) => u.currentStatus != UnitStatus.nonLeasable)
        .length;
    final rate = totalLeasable == 0
        ? 0
        : (leased / totalLeasable * 100).round();

    final colors = Theme.of(context).extension<CustomColors>()!;
    final primary = CupertinoTheme.of(context).primaryColor;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: CupertinoColors.systemGrey5.resolveFrom(context),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(value: '$leased', label: '已租', valueColor: colors.success),
          _StatsDivider(),
          _StatItem(value: '$vacant', label: '空置', valueColor: colors.danger),
          _StatsDivider(),
          _StatItem(value: '$totalLeasable', label: '可租总量'),
          _StatsDivider(),
          _StatItem(value: '$rate%', label: '出租率', valueColor: primary),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color? valueColor;

  const _StatItem({required this.value, required this.label, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: valueColor ?? CupertinoColors.label.resolveFrom(context),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      ],
    );
  }
}

class _StatsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.5,
      height: 24,
      color: CupertinoColors.systemGrey4.resolveFrom(context),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 缩放控制按钮
// ─────────────────────────────────────────────────────────────────────────────

/// 缩放控制按钮（+/适/-），对齐 uni-app zoom-controls__btn。
///
/// 使用 [StatefulWidget] 支持按压态视觉反馈。
class _ZoomButton extends StatefulWidget {
  final IconData? icon;
  final String? label;
  final bool highlight;
  final VoidCallback onTap;

  const _ZoomButton({
    this.icon,
    this.label,
    this.highlight = false,
    required this.onTap,
  });

  @override
  State<_ZoomButton> createState() => _ZoomButtonState();
}

class _ZoomButtonState extends State<_ZoomButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final primary = CupertinoTheme.of(context).primaryColor;
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 80),
        opacity: _pressed ? 0.45 : 1.0,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.highlight
                  ? primary.withValues(alpha: 0.4)
                  : CupertinoColors.systemGrey4.resolveFrom(context),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 6,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Center(
            child: widget.icon != null
                ? Icon(
                    widget.icon,
                    size: 16,
                    color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  )
                : Text(
                    widget.label ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: primary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
