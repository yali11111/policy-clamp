/**
 * Données fictives du dashboard.
 *
 * Ces valeurs restent dans le navigateur.
 * Elles ne représentent pas l'état d'un cluster réel.
 */

export const initialSlices = [
  {
    id: "slice-urllc-001",
    type: "URLLC",
    status: "RUNNING",
    priority: 100,
    namespace: "network-slices",
    deploymentName: "urllc-workload",
    replicas: 2,
    cpu: 500,
    memory: 512,
    description: "Low latency · Critical applications",
  },
  {
    id: "slice-embb-001",
    type: "EMBB",
    status: "RUNNING",
    priority: 50,
    namespace: "network-slices",
    deploymentName: "embb-workload",
    replicas: 3,
    cpu: 750,
    memory: 1024,
    description: "High bandwidth · Media workloads",
  },
  {
    id: "slice-urllc-002",
    type: "URLLC",
    status: "STOPPED",
    priority: 100,
    namespace: "network-slices",
    deploymentName: "urllc-edge",
    replicas: 1,
    cpu: 500,
    memory: 512,
    description: "Edge processing · Low latency",
  },
  {
    id: "slice-embb-002",
    type: "EMBB",
    status: "CREATED",
    priority: 50,
    namespace: "network-slices",
    deploymentName: "embb-streaming",
    replicas: 2,
    cpu: 1000,
    memory: 2048,
    description: "Streaming · High throughput",
  },
];

export const initialEvents = [
  {
    id: 1,
    time: "09:42:18",
    type: "SUCCESS",
    message: "slice-urllc-001 deployment completed",
  },
  {
    id: 2,
    time: "09:40:51",
    type: "INFO",
    message: "AC MultiSlice Lab initialized in demo mode",
  },
  {
    id: 3,
    time: "09:38:07",
    type: "SUCCESS",
    message: "slice-embb-001 replicas updated to 3",
  },
];
