import { SearchX } from "lucide-react";

export default function EmptyState({
  title = "No slices found",
  description = "Try changing your search or filters.",
}) {
  return (
    <div className="empty-state">
      <div className="empty-state-icon">
        <SearchX size={25} />
      </div>

      <h3>{title}</h3>
      <p>{description}</p>
    </div>
  );
}
