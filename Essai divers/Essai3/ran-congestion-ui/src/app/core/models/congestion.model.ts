export type Severity =
  | 'LOW'
  | 'MEDIUM'
  | 'HIGH'
  | 'CRITICAL';

export interface CongestionEvent {
  id: string;
  cellId: string;
  severity: Severity;
  congestionScore: number;
  predicted: boolean;
  timestamp: string;
  description?: string;
}

export interface CongestionPrediction {
  cellId: string;
  predictionTimestamp: string;
  predictedCongestionScore: number;
  confidence?: number;
  severity: Severity;
}
