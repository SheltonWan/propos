/// Route path constants for go_router.
///
/// Extracted from PAGE_SPEC_FLUTTER v1.9.
abstract final class RoutePaths {
  // ── Auth ──
  static const login = '/login';

  // ── Main Tabs ──
  static const dashboard = '/dashboard';
  static const assets = '/assets';
  static const contracts = '/contracts';
  static const workorders = '/workorders';
  static const finance = '/finance';

  // ── Dashboard sub-routes ──
  static const noiDetail = '/dashboard/noi-detail';
  static const waleDetail = '/dashboard/wale-detail';

  // ── Assets sub-routes ──
  static const buildingDetail = '/assets/buildings/:id';
  static const floorPlan = '/assets/buildings/:bid/floors/:fid';
  static const unitDetail = '/assets/units/:id';

  // ── Contracts sub-routes ──
  static const contractDetail = '/contracts/:id';

  // ── Finance sub-routes ──
  static const invoices = '/finance/invoices';
  static const kpi = '/finance/kpi';
  static const dunning = '/finance/dunning';

  // ── Work Orders sub-routes ──
  static const workorderDetail = '/workorders/:id';
  static const workorderNew = '/workorders/new';

  // ── Subleases ──
  static const subleases = '/subleases';
  static const subleaseDetail = '/subleases/:id';

  // ── Misc ──
  static const notifications = '/notifications';
  static const approvals = '/approvals';
}
