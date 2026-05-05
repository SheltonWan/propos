import { DEFAULT_THEME_ID, getThemePreset } from '@/constants/theme'
import type { FloorHeatmapUnit, LayerMode, UnitStatus } from '@/types/assets'

interface BuildFloorSvgWebviewHtmlOptions {
  svgText: string
  units: FloorHeatmapUnit[]
  layer: LayerMode
  scale: number
  themeVars?: Record<string, string>
}

const DEFAULT_THEME_VARS = getThemePreset(DEFAULT_THEME_ID).vars

const STATUS_LABELS: Record<UnitStatus, string> = {
  leased: '已出租',
  vacant: '空置',
  expiring_soon: '即将到期',
  non_leasable: '非可租',
  renovating: '装修中',
  pre_lease: '预租中',
}

function sanitizeSvgMarkup(svgText: string): string {
  return svgText
    .replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi, '')
    .replace(/\son[a-z]+\s*=\s*"[^"]*"/gi, '')
    .replace(/\son[a-z]+\s*=\s*'[^']*'/gi, '')
    .replace(/\s(?:href|xlink:href)\s*=\s*"javascript:[^"]*"/gi, '')
    .replace(/\s(?:href|xlink:href)\s*=\s*'javascript:[^']*'/gi, '')
}

function serializeForScript(value: unknown): string {
  return JSON.stringify(value)
    .replace(/</g, '\\u003c')
    .replace(/-->/g, '--\\>')
}

export function buildFloorSvgWebviewHtml(options: BuildFloorSvgWebviewHtmlOptions): string {
  const themeVars = {
    ...DEFAULT_THEME_VARS,
    ...(options.themeVars ?? {}),
  }

  return `<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
  <title>Floor SVG Viewer</title>
  <style>
    html, body {
      margin: 0;
      width: 100%;
      height: 100%;
      overflow: hidden;
      background: var(--color-background);
      color: var(--color-foreground);
      font-family: var(--theme-font-family-body);
      -webkit-tap-highlight-color: transparent;
      overscroll-behavior: none;
    }

    body {
      position: relative;
    }

    #viewport {
      position: absolute;
      inset: 0;
      overflow: auto;
      background: var(--color-background);
    }

    #stage {
      position: relative;
      min-width: 100%;
    }

    #svg-shell {
      position: relative;
      min-height: 100%;
    }

    #svg-shell svg {
      display: block;
      width: 100%;
      height: auto;
      max-width: none;
      user-select: none;
      -webkit-user-select: none;
    }

    [data-unit-id] {
      cursor: pointer;
      transition: opacity 140ms ease, transform 140ms ease;
    }

    .sheet-backdrop {
      position: fixed;
      inset: 0;
      background: var(--color-mask);
      opacity: 0;
      pointer-events: none;
      transition: opacity 180ms ease;
    }

    .sheet-backdrop.is-open {
      opacity: 1;
      pointer-events: auto;
    }

    .sheet {
      position: fixed;
      left: 0;
      right: 0;
      bottom: 0;
      transform: translateY(100%);
      transition: transform 220ms ease;
      border-radius: 24px 24px 0 0;
      background: var(--color-background);
      box-shadow: 0 -12px 32px var(--color-mask);
      border-top: 1px solid var(--color-border);
      padding-bottom: env(safe-area-inset-bottom);
      overflow: hidden;
    }

    .sheet.is-open {
      transform: translateY(0);
    }

    .sheet__handle {
      width: 44px;
      height: 5px;
      border-radius: 999px;
      background: var(--color-handle);
      margin: 12px auto 0;
    }

    .sheet__header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
      padding: 16px 20px 14px;
      border-bottom: 1px solid var(--color-border);
    }

    .sheet__title-wrap {
      display: flex;
      align-items: center;
      gap: 10px;
      min-width: 0;
    }

    .sheet__title {
      font-family: var(--theme-font-family-display);
      font-size: 20px;
      font-weight: 700;
      color: var(--color-foreground);
      white-space: nowrap;
    }

    .sheet__close {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      width: 32px;
      height: 32px;
      border-radius: 10px;
      border: 1px solid var(--color-border);
      background: var(--color-muted);
      color: var(--color-muted-foreground);
      font-size: 16px;
      line-height: 1;
    }

    .status-badge {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      min-height: 26px;
      padding: 0 12px;
      border-radius: 999px;
      font-size: 12px;
      font-weight: 600;
      border: 1px solid var(--color-border);
      white-space: nowrap;
    }

    .status-badge--leased {
      color: var(--color-primary);
      background: var(--color-primary-soft);
      border-color: var(--color-primary-border-soft);
    }

    .status-badge--expiring_soon {
      color: var(--color-warning);
      background: var(--color-warning-soft);
      border-color: var(--color-warning-border-soft);
    }

    .status-badge--vacant {
      color: var(--color-destructive);
      background: var(--color-destructive-soft);
      border-color: var(--color-destructive-border-soft);
    }

    .status-badge--renovating,
    .status-badge--pre_lease {
      color: var(--color-info);
      background: var(--color-info-soft);
      border-color: var(--color-info-border-soft);
    }

    .status-badge--non_leasable {
      color: var(--color-muted-foreground);
      background: var(--color-muted);
    }

    .sheet__body {
      max-height: min(56vh, 420px);
      overflow: auto;
      padding: 18px 20px 20px;
    }

    .info-block {
      display: flex;
      flex-direction: column;
      gap: 12px;
      padding: 16px;
      border-radius: 18px;
      border: 1px solid var(--color-border);
      background: var(--color-surface-light);
      margin-bottom: 14px;
    }

    .info-block--tenant {
      background: var(--color-primary-soft);
      border-color: var(--color-primary-border-soft);
    }

    .info-block--warning {
      background: var(--color-warning-soft);
      border-color: var(--color-warning-border-soft);
    }

    .info-block--vacant {
      background: var(--color-destructive-soft);
      border-color: var(--color-destructive-border-soft);
    }

    .info-block--info {
      background: var(--color-info-soft);
      border-color: var(--color-info-border-soft);
    }

    .info-row {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
    }

    .info-label,
    .meta-label {
      font-size: 13px;
      color: var(--color-muted-foreground);
    }

    .info-value,
    .meta-value {
      font-size: 14px;
      font-weight: 600;
      color: var(--color-foreground);
      text-align: right;
    }

    .meta-row {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
      padding: 14px 16px;
      border-radius: 16px;
      border: 1px solid var(--color-border);
      background: var(--color-background);
      margin-bottom: 14px;
    }

    .desc-title {
      font-size: 14px;
      font-weight: 700;
      color: var(--color-foreground);
    }

    .desc-text {
      font-size: 13px;
      line-height: 1.5;
      color: var(--color-muted-foreground);
    }

    .actions {
      display: flex;
      flex-direction: column;
      gap: 10px;
    }

    .action-btn {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      min-height: 44px;
      border-radius: 14px;
      font-size: 14px;
      font-weight: 700;
      border: 1px solid transparent;
      text-decoration: none;
    }

    .action-btn--primary {
      background: var(--color-primary);
      color: var(--color-primary-foreground);
    }

    .action-btn--secondary {
      background: var(--color-background);
      color: var(--color-primary);
      border-color: var(--color-primary-border-soft);
    }
  </style>
</head>
<body>
  <div id="viewport">
    <div id="stage">
      <div id="svg-shell">${sanitizeSvgMarkup(options.svgText)}</div>
    </div>
  </div>
  <div id="sheet-backdrop" class="sheet-backdrop" data-action="close-sheet"></div>
  <div id="sheet" class="sheet" aria-hidden="true"></div>

  <script>
    (function () {
      var initialUnits = ${serializeForScript(options.units)};
      var initialLayer = ${serializeForScript(options.layer)};
      var initialScale = ${serializeForScript(options.scale)};
      var initialThemeVars = ${serializeForScript(themeVars)};
      var statusLabels = ${serializeForScript(STATUS_LABELS)};
      var units = Array.isArray(initialUnits) ? initialUnits : [];
      var currentLayer = initialLayer === 'expiry' ? 'expiry' : 'status';
      var currentScale = Number(initialScale) || 1;
      var selectedUnitId = null;
      var stage = document.getElementById('stage');
      var sheet = document.getElementById('sheet');
      var backdrop = document.getElementById('sheet-backdrop');
      var byNumber = Object.create(null);
      var byNormalizedNumber = Object.create(null);

      for (var i = 0; i < units.length; i += 1) {
        var unit = units[i];
        if (unit && typeof unit.unit_number === 'string') {
          byNumber[unit.unit_number] = unit;
          byNormalizedNumber[normalizeValue(unit.unit_number)] = unit;
        }
      }

      function normalizeValue(value) {
        return String(value || '').replace(/[-\s]/g, '');
      }

      function escapeHtml(value) {
        return String(value || '')
          .replace(/&/g, '&amp;')
          .replace(/</g, '&lt;')
          .replace(/>/g, '&gt;')
          .replace(/"/g, '&quot;')
          .replace(/'/g, '&#39;');
      }

      function applyThemeVars(vars) {
        var root = document.documentElement;
        for (var key in vars) {
          if (Object.prototype.hasOwnProperty.call(vars, key)) {
            root.style.setProperty(key, String(vars[key] || ''));
          }
        }
        document.body.style.background = (vars && (vars['--color-background'] || vars['--color-surface-light'])) || 'transparent';
      }

      function resolveUnitByElement(element) {
        if (!element || typeof element.getAttribute !== 'function') {
          return null;
        }

        var svgId = element.getAttribute('data-unit-id') || '';
        var svgNumber = element.getAttribute('data-unit-number') || '';
        var normalizedId = normalizeValue(svgId);
        var direct = byNumber[svgId] || byNormalizedNumber[normalizedId];
        if (direct) {
          return direct;
        }

        if (svgNumber) {
          for (var index = 0; index < units.length; index += 1) {
            var candidate = units[index];
            if (candidate.unit_number === svgNumber || candidate.unit_number.endsWith(svgNumber)) {
              return candidate;
            }
          }
        }

        return null;
      }

      function findElementByAttr(start, attrName) {
        var node = start;
        while (node && node !== document.body && node !== document.documentElement) {
          if (node.nodeType === 1 && node.getAttribute && node.getAttribute(attrName)) {
            return node;
          }
          node = node.parentNode;
        }
        return null;
      }

      function getPaintTargets(element) {
        if (!element || typeof element.querySelectorAll !== 'function') {
          return [];
        }
        var shapes = element.querySelectorAll('path, rect, polygon, ellipse, circle, polyline, line');
        if (!shapes.length) {
          return [element];
        }
        return Array.prototype.slice.call(shapes);
      }

      function getRoomColor(unit, layer) {
        var status = unit.current_status;

        if (status === 'non_leasable') {
          return {
            fill: 'var(--color-muted-foreground)',
            stroke: 'var(--color-border)',
            opacity: 0.18,
          };
        }

        if (status === 'renovating') {
          return {
            fill: 'var(--color-info)',
            stroke: 'var(--color-info)',
            opacity: 0.28,
          };
        }

        if (status === 'pre_lease') {
          return {
            fill: 'var(--color-warning)',
            stroke: 'var(--color-warning)',
            opacity: 0.38,
          };
        }

        if (status === 'vacant') {
          return {
            fill: 'var(--color-destructive)',
            stroke: 'var(--color-destructive)',
            opacity: 0.3,
          };
        }

        if (layer === 'expiry') {
          if (status === 'expiring_soon') {
            return {
              fill: 'var(--color-destructive)',
              stroke: 'var(--color-destructive)',
              opacity: 0.55,
            };
          }

          if (unit.contract_end_date) {
            var endAt = Date.parse(unit.contract_end_date);
            if (!Number.isNaN(endAt)) {
              var days = Math.ceil((endAt - Date.now()) / 86400000);
              if (days < 90) {
                return {
                  fill: 'var(--color-destructive)',
                  stroke: 'var(--color-destructive)',
                  opacity: 0.55,
                };
              }
              if (days < 365) {
                return {
                  fill: 'var(--color-warning)',
                  stroke: 'var(--color-warning)',
                  opacity: 0.48,
                };
              }
            }
          }

          return {
            fill: 'var(--color-success)',
            stroke: 'var(--color-success)',
            opacity: 0.4,
          };
        }

        if (status === 'expiring_soon') {
          return {
            fill: 'var(--color-warning)',
            stroke: 'var(--color-warning)',
            opacity: 0.48,
          };
        }

        return {
          fill: 'var(--color-primary)',
          stroke: 'var(--color-primary)',
          opacity: 0.38,
        };
      }

      function applyRoomStates() {
        var elements = document.querySelectorAll('[data-unit-id]');
        for (var idx = 0; idx < elements.length; idx += 1) {
          var element = elements[idx];
          var unit = resolveUnitByElement(element);
          if (!unit) {
            continue;
          }
          var paintTargets = getPaintTargets(element);
          var color = getRoomColor(unit, currentLayer);
          var selected = selectedUnitId === unit.unit_id;
          element.style.cursor = 'pointer';
          for (var paintIndex = 0; paintIndex < paintTargets.length; paintIndex += 1) {
            var target = paintTargets[paintIndex];
            target.style.cursor = 'pointer';
            target.style.fill = color.fill;
            target.style.fillOpacity = String(selected ? Math.min(color.opacity + 0.18, 0.75) : color.opacity);
            target.style.stroke = selected ? 'var(--color-primary)' : color.stroke;
            target.style.strokeWidth = selected ? '2.5' : '1.5';
          }
        }
      }

      function layoutStage() {
        if (!stage) {
          return;
        }
        var viewportWidth = Math.max(document.documentElement.clientWidth || 0, window.innerWidth || 0, 1);
        stage.style.width = String(Math.round(viewportWidth * currentScale)) + 'px';
      }

      function formatDate(value) {
        return value ? String(value).slice(0, 10) : '—';
      }

      function formatArea(value) {
        return typeof value === 'number' ? String(value) + ' m²' : '—';
      }

      function setSheetContent(unit) {
        if (!sheet || !backdrop) {
          return;
        }

        var statusClass = 'status-badge status-badge--' + escapeHtml(unit.current_status);
        var parts = [];

        parts.push('<div class="sheet__handle"></div>');
        parts.push('<div class="sheet__header">');
        parts.push('<div class="sheet__title-wrap">');
        parts.push('<div class="sheet__title">' + escapeHtml(unit.unit_number) + '</div>');
        parts.push('<div class="' + statusClass + '">' + escapeHtml(statusLabels[unit.current_status] || '状态未知') + '</div>');
        parts.push('</div>');
        parts.push('<button class="sheet__close" type="button" data-action="close-sheet" aria-label="关闭">×</button>');
        parts.push('</div>');
        parts.push('<div class="sheet__body">');

        if (unit.current_status === 'leased' || unit.current_status === 'expiring_soon') {
          var tenantClass = unit.current_status === 'expiring_soon'
            ? 'info-block info-block--tenant info-block--warning'
            : 'info-block info-block--tenant';
          parts.push('<div class="' + tenantClass + '">');
          parts.push('<div class="info-row"><div class="info-label">租户名称</div><div class="info-value">' + escapeHtml(unit.tenant_name || '—') + '</div></div>');
          parts.push('<div class="info-row"><div class="info-label">合同到期</div><div class="info-value">' + escapeHtml(formatDate(unit.contract_end_date)) + '</div></div>');
          parts.push('</div>');
        }
        else if (unit.current_status === 'vacant') {
          parts.push('<div class="info-block info-block--vacant">');
          parts.push('<div class="desc-title">当前空置</div>');
          parts.push('<div class="desc-text">该房源暂无租户，可对外出租。</div>');
          parts.push('</div>');
        }
        else if (unit.current_status === 'renovating') {
          parts.push('<div class="info-block info-block--info">');
          parts.push('<div class="desc-title">装修改造中</div>');
          parts.push('<div class="desc-text">该房源正在进行内部改造工程。</div>');
          parts.push('</div>');
        }
        else if (unit.current_status === 'pre_lease') {
          parts.push('<div class="info-block info-block--info">');
          parts.push('<div class="desc-title">招租中 / 预租洽谈</div>');
          parts.push('<div class="desc-text">正在进行租户洽谈，预计近期完成签约。</div>');
          parts.push('</div>');
        }

        if (unit.area_sqm != null) {
          parts.push('<div class="meta-row"><div class="meta-label">建筑面积</div><div class="meta-value">' + escapeHtml(formatArea(unit.area_sqm)) + '</div></div>');
        }

        parts.push('<div class="actions">');
        parts.push('<button class="action-btn action-btn--primary" type="button" data-action="navigate-unit" data-unit-id="' + escapeHtml(unit.unit_id) + '">查看房源详情</button>');
        if (unit.contract_id) {
          parts.push('<button class="action-btn action-btn--secondary" type="button" data-action="navigate-contract" data-contract-id="' + escapeHtml(unit.contract_id) + '">查看合同</button>');
        }
        parts.push('</div>');
        parts.push('</div>');

        sheet.innerHTML = parts.join('');
        sheet.classList.add('is-open');
        sheet.setAttribute('aria-hidden', 'false');
        backdrop.classList.add('is-open');
      }

      function closeSheet() {
        selectedUnitId = null;
        if (sheet) {
          sheet.classList.remove('is-open');
          sheet.setAttribute('aria-hidden', 'true');
          sheet.innerHTML = '';
        }
        if (backdrop) {
          backdrop.classList.remove('is-open');
        }
        applyRoomStates();
      }

      function openSheet(unit) {
        selectedUnitId = unit.unit_id;
        setSheetContent(unit);
        applyRoomStates();
      }

      function navigateTo(path, id) {
        if (!id) {
          return;
        }
        window.location.href = 'propos://navigate/' + path + '?id=' + encodeURIComponent(String(id));
      }

      function normalizeSvgRoot() {
        var svg = document.querySelector('#svg-shell svg');
        if (!svg) {
          return;
        }
        svg.style.display = 'block';
        svg.style.width = '100%';
        svg.style.height = 'auto';
        svg.style.maxWidth = 'none';
        svg.setAttribute('preserveAspectRatio', svg.getAttribute('preserveAspectRatio') || 'xMinYMin meet');
      }

      window.PropSetLayer = function (nextLayer) {
        currentLayer = nextLayer === 'expiry' ? 'expiry' : 'status';
        applyRoomStates();
      };

      window.PropSetZoom = function (nextScale) {
        var numericScale = Number(nextScale);
        if (!Number.isFinite(numericScale)) {
          return;
        }
        currentScale = Math.max(0.6, Math.min(2.8, numericScale));
        layoutStage();
      };

      window.PropApplyTheme = function (nextVars) {
        applyThemeVars(nextVars || {});
        applyRoomStates();
      };

      document.addEventListener('click', function (event) {
        var target = event.target;
        var actionElement = findElementByAttr(target, 'data-action');
        if (actionElement) {
          var action = actionElement.getAttribute('data-action');
          if (action === 'close-sheet') {
            closeSheet();
            return;
          }
          if (action === 'navigate-unit') {
            navigateTo('unit', actionElement.getAttribute('data-unit-id'));
            return;
          }
          if (action === 'navigate-contract') {
            navigateTo('contract', actionElement.getAttribute('data-contract-id'));
            return;
          }
        }

        var unitElement = findElementByAttr(target, 'data-unit-id');
        if (!unitElement) {
          return;
        }
        var unit = resolveUnitByElement(unitElement);
        if (!unit) {
          return;
        }

        if (selectedUnitId === unit.unit_id) {
          closeSheet();
          return;
        }

        openSheet(unit);
      }, true);

      window.addEventListener('resize', function () {
        layoutStage();
      });

      applyThemeVars(initialThemeVars);
      normalizeSvgRoot();
      layoutStage();
      applyRoomStates();
    }());
  </script>
</body>
</html>`
}