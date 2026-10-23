
#!/usr/bin/env bash
# 09A-ui-structure.sh
# Création de la structure du frontend React.
# Aucun service n'est démarré.

set -eu

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}/ac-multislice-lab"
UI_DIR="${PROJECT_DIR}/ui-multislice"

if [ ! -d "${PROJECT_DIR}" ]; then
    printf 'Erreur : exécuter d’abord 01-structure.sh\n' >&2
    exit 1
fi

write_file() {
    target="$1"

    if [ -e "$target" ]; then
        printf 'Conservé (existe déjà) : %s\n' "$target"
        return 0
    fi

    mkdir -p "$(dirname "$target")"
    cat > "$target"
    printf 'Créé : %s\n' "$target"
}

printf '%s\n' "Création de la structure React..."
printf 'Répertoire cible : %s\n' "${UI_DIR}"

# Structure principale.
mkdir -p "${UI_DIR}/src/components"
mkdir -p "${UI_DIR}/src/pages"
mkdir -p "${UI_DIR}/src/services"
mkdir -p "${UI_DIR}/src/hooks"
mkdir -p "${UI_DIR}/public"

# Point d'entrée HTML.
write_file "${UI_DIR}/index.html" <<'EOF'
<!doctype html>
<html lang="fr">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta
      name="description"
      content="AC MultiSlice Lab - Console de démonstration d'orchestration multi-slice"
    />
    <meta name="theme-color" content="#0f172a" />
    <title>AC MultiSlice Lab</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
EOF

# Point d'entrée React.
write_file "${UI_DIR}/src/main.jsx" <<'EOF'
import React from "react";
import { createRoot } from "react-dom/client";
import App from "./App.jsx";
import "./styles.css";

createRoot(document.getElementById("root")).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
EOF

# Composant racine initial.
write_file "${UI_DIR}/src/App.jsx" <<'EOF'
import Dashboard from "./pages/Dashboard.jsx";

export default function App() {
  return <Dashboard />;
}
EOF

# Page d'attente qui sera remplacée par la partie 3.
write_file "${UI_DIR}/src/pages/Dashboard.jsx" <<'EOF'
export default function Dashboard() {
  return (
    <main className="initial-screen">
      <div className="initial-card">
        <div className="brand-mark">AC</div>
        <h1>AC MultiSlice Lab</h1>
        <p>Interface de gestion des slices réseau</p>
        <span className="demo-badge">DEMO MODE</span>
        <p className="muted">
          Structure initialisée. Exécutez les parties suivantes
          pour générer l'interface complète.
        </p>
      </div>
    </main>
  );
}
EOF

# Feuille de style initiale.
write_file "${UI_DIR}/src/styles.css" <<'EOF'
:root {
  font-family: Inter, ui-sans-serif, system-ui, -apple-system,
    BlinkMacSystemFont, "Segoe UI", sans-serif;
  color: #0f172a;
  background: #f8fafc;
  font-synthesis: none;
  text-rendering: optimizeLegibility;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

* {
  box-sizing: border-box;
}

body {
  margin: 0;
  min-width: 320px;
  min-height: 100vh;
}

button,
input,
select {
  font: inherit;
}

button {
  cursor: pointer;
}

.initial-screen {
  display: grid;
  min-height: 100vh;
  place-items: center;
  padding: 24px;
}

.initial-card {
  width: 100%;
  max-width: 520px;
  padding: 40px;
  text-align: center;
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 24px;
  box-shadow: 0 20px 50px rgb(15 23 42 / 6%);
}

.brand-mark {
  display: grid;
  width: 56px;
  height: 56px;
  margin: 0 auto 20px;
  place-items: center;
  color: white;
  font-weight: 800;
  background: #2563eb;
  border-radius: 16px;
}

.initial-card h1 {
  margin-bottom: 8px;
  font-size: 28px;
}

.initial-card p {
  color: #64748b;
  line-height: 1.6;
}

.demo-badge {
  display: inline-block;
  margin: 12px 0;
  padding: 6px 12px;
  color: #92400e;
  font-size: 12px;
  font-weight: 700;
  background: #fef3c7;
  border-radius: 999px;
}

.muted {
  margin-top: 20px;
  font-size: 13px;
}
EOF

# Fichier de configuration Vite.
write_file "${UI_DIR}/vite.config.js" <<'EOF'
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  server: {
    host: "127.0.0.1",
    port: 5173,
    strictPort: true,
  },
});
EOF

# Configuration npm minimale.
write_file "${UI_DIR}/package.json" <<'EOF'
{
  "name": "ac-multislice-ui",
  "private": true,
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "@vitejs/plugin-react": "^4.3.4",
    "vite": "^6.0.0",
    "react": "^18.3.1",
    "react-dom": "^18.3.1",
    "lucide-react": "^0.468.0"
  },
  "devDependencies": {}
}
EOF

printf '\nPartie 1/4 terminée.\n'
printf 'Structure React créée dans : %s\n' "${UI_DIR}"
printf 'Aucun fichier existant écrasé.\n'
printf 'Aucun service démarré.\n'

