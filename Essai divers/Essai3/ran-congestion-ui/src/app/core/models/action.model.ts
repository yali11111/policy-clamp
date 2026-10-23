export type ActionStatus =
  | 'PENDING'
  | 'RUNNING'
  | 'SUCCESS'
  | 'FAILED'
  | 'REJECTED';

export type ActionType =
  | 'SCALING'
  | 'TRAFFIC_STEERING'
  | 'NETWORK_CONFIG'
  | 'OTHER';

export interface ActionEvent {
  id: string;
  cellId: string;
  actionType: string;
  status: ActionStatus;
  timestamp: string;
  durationMs?: number;
  message?: string;
}
