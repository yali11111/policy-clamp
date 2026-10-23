import { useId } from "react";

export default function ConfigField({
  label,
  hint,
  children,
}) {
  const id = useId();

  return (
    <div className="config-field">
      <label
        className="config-field-label"
        htmlFor={id}
      >
        {label}
      </label>

      <div className="config-field-control">
        {typeof children === "function"
          ? children(id)
          : children}
      </div>

      {hint && (
        <p className="config-field-hint">
          {hint}
        </p>
      )}
    </div>
  );
}
