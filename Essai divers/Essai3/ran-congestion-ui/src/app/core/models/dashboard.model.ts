export interface DashboardSummary {
  activeCongestions: number;
  criticalAlerts: number;
  averageLatencyMs: number;
  averageUtilizationPct: number;
  successfulActions: number;
  failedActions: number;
}
