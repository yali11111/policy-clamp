import {
  Gauge,
  MoreHorizontal,
  Play,
  Server,
  Square,
  Zap,
} from "lucide-react";

import StatusBadge from "./StatusBadge.jsx";

export default function SliceCard({
  slice,
  onDetails = () => {},
  onDeploy = () => {},
  onUndeploy = () => {},
}) {
  const isRunning = slice.status === "RUNNING";
  const isBusy = [
    "VALIDATING",
    "DEPLOYING",
    "STOPPING",
  ].includes(slice.status);

  const isUrlcc = slice.type === "URLLC";
  const Icon = isUrlcc ? Zap : Gauge;

  return (
    <article className="slice-card">
      <div className="slice-card-main">
        <div className={`slice-profile-icon ${isUrlcc ? "urlcc" : "embb"}`}>
          <Icon size={22} />
        </div>

        <div className="slice-card-content">
          <div className="slice-title-row">
            <h3>{slice.id}</h3>
            <StatusBadge status={slice.status} />
          </div>

          <p className="slice-description">
            {slice.description ||
              (isUrlcc
                ? "Low latency · Critical applications"
                : "High bandwidth · Data applications")}
          </p>

          <div className="slice-metrics">
            <span>Priority {slice.priority}</span>
            <span>{slice.cpu} m CPU</span>
            <span>{slice.memory} MiB RAM</span>
            <span>{slice.replicas} replicas</span>
          </div>
        </div>

        <button
          type="button"
          className="icon-button details-menu"
          onClick={() => onDetails(slice)}
          aria-label={`View details for ${slice.id}`}
          title="View details"
        >
          <MoreHorizontal size={20} />
        </button>
      </div>

      <div className="slice-card-footer">
        <div className="slice-namespace">
          <Server size={15} />
          <span>{slice.namespace || "network-slices"}</span>
        </div>

        <div className="slice-actions">
          <button
            type="button"
            className="button button-secondary button-small"
            onClick={() => onDetails(slice)}
          >
            Details
          </button>

          {isRunning ? (
            <button
              type="button"
              className="button button-danger button-small"
              disabled={isBusy}
              onClick={() => onUndeploy(slice)}
            >
              <Square size={14} />
              Undeploy
            </button>
          ) : (
            <button
              type="button"
              className="button button-primary button-small"
              disabled={isBusy}
              onClick={() => onDeploy(slice)}
            >
              <Play size={14} />
              Deploy
            </button>
          )}
        </div>
      </div>
    </article>
  );
}
