import {
  Activity,
  Boxes,
  LayoutDashboard,
  Network,
  Settings2,
  ShieldCheck,
} from "lucide-react";

const navigation = [
  { label: "Overview", icon: LayoutDashboard, id: "overview" },
  { label: "Slice inventory", icon: Boxes, id: "inventory" },
  { label: "Events & logs", icon: Activity, id: "events" },
  { label: "Configuration", icon: Settings2, id: "configuration" },
];

export default function Sidebar({
  active = "overview",
  onNavigate = () => {},
}) {
  return (
    <aside className="sidebar">
      <div className="sidebar-brand">
        <div className="brand-icon">
          <Network size={23} />
        </div>

        <div className="brand-copy">
          <strong>AC MultiSlice</strong>
          <span>Orchestration Lab</span>
        </div>
      </div>

      <div className="sidebar-section-label">WORKSPACE</div>

      <nav className="sidebar-navigation" aria-label="Navigation principale">
        {navigation.map(({ label, icon: Icon, id }) => (
          <button
            key={id}
            type="button"
            className={`nav-item ${active === id ? "active" : ""}`}
            onClick={() => onNavigate(id)}
            aria-current={active === id ? "page" : undefined}
          >
            <Icon size={19} />
            <span>{label}</span>
          </button>
        ))}
      </nav>

      <div className="sidebar-bottom">
        <div className="environment-card">
          <div className="environment-title">
            <ShieldCheck size={18} />
            <span>Demo environment</span>
          </div>
          <div className="environment-status">
            <span className="status-dot offline" />
            No cluster connected
          </div>
        </div>

        <div className="sidebar-footer">
          <span>AC MultiSlice Lab</span>
          <span>v1.0.0</span>
        </div>
      </div>
    </aside>
  );
}
