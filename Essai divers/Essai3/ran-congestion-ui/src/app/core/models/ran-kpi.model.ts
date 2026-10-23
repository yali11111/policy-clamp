export interface RanKpi {
  cellId: string;
  timestamp: string;

  throughputMbps: number;
  latencyMs: number;
  packetLossPct: number;
  resourceUtilizationPct: number;
}

export interface KpiHistoryQuery {
  cellId: string;
  from: string;
  to: string;
}
