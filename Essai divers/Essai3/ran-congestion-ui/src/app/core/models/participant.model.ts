export type ParticipantType =
  | 'SCALING'
  | 'TRAFFIC_STEERING'
  | 'NETWORK_CONFIG';

export type ParticipantHealth =
  | 'UP'
  | 'DOWN'
  | 'DEGRADED'
  | 'UNKNOWN';

export interface ParticipantStatus {
  id: string;
  name: string;
  type: ParticipantType;
  status: ParticipantHealth;
  lastSeen?: string;
  description?: string;
}
