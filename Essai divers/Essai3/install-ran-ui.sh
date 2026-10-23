
#!/bin/sh
set -eu

# ============================================================
# RAN CONGESTION CONTROL
# INSTALLATION DU FRONTEND ANGULAR
# PARTIE 1/8 : PREPARATION ET ENVIRONNEMENT
# ============================================================

ROOT="ran-congestion-ui"
SRC="$ROOT/src"

echo "Partie 1/8 : preparation des dossiers"

# ------------------------------------------------------------
# 1. Création de l'arborescence
# ------------------------------------------------------------

mkdir -p \
  "$SRC/app/core/config" \
  "$SRC/app/core/models" \
  "$SRC/app/core/services" \
  "$SRC/app/core/interceptors" \
  "$SRC/app/layout/shell" \
  "$SRC/app/layout/sidebar" \
  "$SRC/app/layout/header" \
  "$SRC/app/shared/metric-card" \
  "$SRC/app/shared/status-badge" \
  "$SRC/app/shared/line-chart" \
  "$SRC/app/pages/dashboard" \
  "$SRC/app/pages/kpi-monitoring" \
  "$SRC/app/pages/congestion" \
  "$SRC/app/pages/actions" \
  "$SRC/app/pages/participants" \
  "$SRC/app/pages/settings" \
  "$SRC/environments"

# ------------------------------------------------------------
# 2. Environnement de développement
# ------------------------------------------------------------

cat > "$SRC/environments/environment.ts" <<'EOF'
export const environment = {
  production: false,

  // Point d'entrée HTTP vers le backend Spring Boot
  apiBaseUrl: '/api',

  // Intervalle d'actualisation du dashboard, en millisecondes
  refreshIntervalMs: 5000
};
EOF

# ------------------------------------------------------------
# 3. Environnement de production
# ------------------------------------------------------------

cat > "$SRC/environments/environment.prod.ts" <<'EOF'
export const environment = {
  production: true,

  // URL à adapter à l'infrastructure de production
  apiBaseUrl: '/api',

  // Intervalle d'actualisation du dashboard
  refreshIntervalMs: 10000
};
EOF

# ------------------------------------------------------------
# 4. Documentation initiale du frontend
# ------------------------------------------------------------

cat > "$ROOT/README-UI.txt" <<'EOF'
RAN CONGESTION CONTROL
Frontend Angular

Organisation :
- core/config       : configuration de l'API
- core/models       : modèles de données
- core/services     : communication HTTP
- core/interceptors : gestion des erreurs HTTP
- layout            : structure générale et navigation
- shared            : composants réutilisables
- pages             : écrans de supervision
- environments      : configuration des environnements

Intégration :
- Backend existant : Spring Boot
- Communication    : HTTP REST
- Préfixe API      : /api
- Actualisation    : configuration dans environment.ts

Contraintes :
- Aucune installation de dépendances
- Aucun démarrage de serveur
- Aucune commande npm
- Aucun accès direct à Kafka depuis Angular

Les endpoints HTTP devront être vérifiés dans le code
des contrôleurs Spring Boot existants.
EOF

# ------------------------------------------------------------
# 5. Vérification des dossiers et fichiers créés
# ------------------------------------------------------------

echo ""
echo "Verification de la partie 1/8"

for FILE in \
  "$SRC/environments/environment.ts" \
  "$SRC/environments/environment.prod.ts" \
  "$ROOT/README-UI.txt"
do
  if [ -f "$FILE" ]; then
    echo "OK : $FILE"
  else
    echo "ERREUR : fichier absent : $FILE"
    exit 1
  fi
done

echo ""
echo "Partie 1/8 terminee."
echo "Dossiers et fichiers d'environnement prepares."
echo "Aucune dependance installee."
echo "Aucun service demarre."


# ============================================================
# PARTIE 2/8 - MODELES DE DONNEES TYPESCRIPT
# ============================================================

set -eu

ROOT="ran-congestion-ui"
SRC="$ROOT/src"

echo "Partie 2/8 : creation des modeles"

mkdir -p "$SRC/app/core/models"

# ------------------------------------------------------------
# 1. Modèles KPI
# ------------------------------------------------------------

cat > "$SRC/app/core/models/ran-kpi.model.ts" <<'EOF'
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
EOF

# ------------------------------------------------------------
# 2. Modèles de congestion et de prédiction
# ------------------------------------------------------------

cat > "$SRC/app/core/models/congestion.model.ts" <<'EOF'
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
EOF

# ------------------------------------------------------------
# 3. Modèles des actions réseau
# ------------------------------------------------------------

cat > "$SRC/app/core/models/action.model.ts" <<'EOF'
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
EOF

# ------------------------------------------------------------
# 4. Modèles des participants réseau
# ------------------------------------------------------------

cat > "$SRC/app/core/models/participant.model.ts" <<'EOF'
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
EOF

# ------------------------------------------------------------
# 5. Modèle de synthèse du dashboard
# ------------------------------------------------------------

cat > "$SRC/app/core/models/dashboard.model.ts" <<'EOF'
export interface DashboardSummary {
  activeCongestions: number;
  criticalAlerts: number;
  averageLatencyMs: number;
  averageUtilizationPct: number;
  successfulActions: number;
  failedActions: number;
}
EOF

# ------------------------------------------------------------
# 6. Vérification des fichiers
# ------------------------------------------------------------

echo ""
echo "Verification des modeles"

for FILE in \
  "$SRC/app/core/models/ran-kpi.model.ts" \
  "$SRC/app/core/models/congestion.model.ts" \
  "$SRC/app/core/models/action.model.ts" \
  "$SRC/app/core/models/participant.model.ts" \
  "$SRC/app/core/models/dashboard.model.ts"
do
  if [ -f "$FILE" ]; then
    echo "OK : $FILE"
  else
    echo "ERREUR : $FILE"
    exit 1
  fi
done

echo ""
echo "Partie 2/8 terminee."
echo "Modeles TypeScript crees."
echo "Aucune dependance installee."
echo "Aucun service demarre."


# ============================================================
# PARTIE 3/8 - SERVICES HTTP SPRING BOOT
# ============================================================

set -eu

ROOT="ran-congestion-ui"
SRC="$ROOT/src"

echo "Partie 3/8 : creation des services HTTP"

mkdir -p \
  "$SRC/app/core/config" \
  "$SRC/app/core/services"

# ------------------------------------------------------------
# 1. Centralisation des endpoints
# ------------------------------------------------------------

cat > "$SRC/app/core/config/api.config.ts" <<'EOF'
export const API_ENDPOINTS = {
  dashboardSummary: '/dashboard/summary',

  kpis: '/kpis/latest',
  kpiHistory: '/kpis/history',

  congestionEvents: '/congestion/events',

  actions: '/actions',

  participants: '/participants'
} as const;
EOF

# ------------------------------------------------------------
# 2. Service de collecte des KPI
# ------------------------------------------------------------

cat > "$SRC/app/core/services/kpi.service.ts" <<'EOF'
import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';

import { environment } from '../../../environments/environment';
import { API_ENDPOINTS } from '../config/api.config';
import { RanKpi } from '../models/ran-kpi.model';

@Injectable({ providedIn: 'root' })
export class KpiService {
  private readonly http = inject(HttpClient);
  private readonly baseUrl = environment.apiBaseUrl;

  getLatest(cellId?: string): Observable<RanKpi[]> {
    let params = new HttpParams();

    if (cellId) {
      params = params.set('cellId', cellId);
    }

    return this.http.get<RanKpi[]>(
      `${this.baseUrl}${API_ENDPOINTS.kpis}`,
      { params }
    );
  }

  getHistory(
    cellId: string,
    from: string,
    to: string
  ): Observable<RanKpi[]> {
    const params = new HttpParams()
      .set('cellId', cellId)
      .set('from', from)
      .set('to', to);

    return this.http.get<RanKpi[]>(
      `${this.baseUrl}${API_ENDPOINTS.kpiHistory}`,
      { params }
    );
  }
}
EOF

# ------------------------------------------------------------
# 3. Service de détection de congestion
# ------------------------------------------------------------

cat > "$SRC/app/core/services/congestion.service.ts" <<'EOF'
import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';

import { environment } from '../../../environments/environment';
import { API_ENDPOINTS } from '../config/api.config';
import { CongestionEvent } from '../models/congestion.model';

@Injectable({ providedIn: 'root' })
export class CongestionService {
  private readonly http = inject(HttpClient);
  private readonly url =
    `${environment.apiBaseUrl}${API_ENDPOINTS.congestionEvents}`;

  getEvents(severity?: string): Observable<CongestionEvent[]> {
    let params = new HttpParams();

    if (severity) {
      params = params.set('severity', severity);
    }

    return this.http.get<CongestionEvent[]>(
      this.url,
      { params }
    );
  }
}
EOF

# ------------------------------------------------------------
# 4. Service d'historique des actions
# ------------------------------------------------------------

cat > "$SRC/app/core/services/action.service.ts" <<'EOF'
import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

import { environment } from '../../../environments/environment';
import { API_ENDPOINTS } from '../config/api.config';
import { ActionEvent } from '../models/action.model';

@Injectable({ providedIn: 'root' })
export class ActionService {
  private readonly http = inject(HttpClient);
  private readonly url =
    `${environment.apiBaseUrl}${API_ENDPOINTS.actions}`;

  getHistory(): Observable<ActionEvent[]> {
    return this.http.get<ActionEvent[]>(this.url);
  }

  getById(id: string): Observable<ActionEvent> {
    return this.http.get<ActionEvent>(
      `${this.url}/${encodeURIComponent(id)}`
    );
  }
}
EOF

# ------------------------------------------------------------
# 5. Service des participants réseau
# ------------------------------------------------------------

cat > "$SRC/app/core/services/participant.service.ts" <<'EOF'
import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

import { environment } from '../../../environments/environment';
import { API_ENDPOINTS } from '../config/api.config';
import { ParticipantStatus } from '../models/participant.model';

@Injectable({ providedIn: 'root' })
export class ParticipantService {
  private readonly http = inject(HttpClient);
  private readonly url =
    `${environment.apiBaseUrl}${API_ENDPOINTS.participants}`;

  getStatuses(): Observable<ParticipantStatus[]> {
    return this.http.get<ParticipantStatus[]>(this.url);
  }
}
EOF

# ------------------------------------------------------------
# 6. Service de synthèse du dashboard
# ------------------------------------------------------------

cat > "$SRC/app/core/services/dashboard.service.ts" <<'EOF'
import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

import { environment } from '../../../environments/environment';
import { API_ENDPOINTS } from '../config/api.config';
import { DashboardSummary } from '../models/dashboard.model';

@Injectable({ providedIn: 'root' })
export class DashboardService {
  private readonly http = inject(HttpClient);

  getSummary(): Observable<DashboardSummary> {
    return this.http.get<DashboardSummary>(
      `${environment.apiBaseUrl}${API_ENDPOINTS.dashboardSummary}`
    );
  }
}
EOF

# ------------------------------------------------------------
# 7. Intercepteur pour les erreurs HTTP
# ------------------------------------------------------------

mkdir -p "$SRC/app/core/interceptors"

cat > "$SRC/app/core/interceptors/api-error.interceptor.ts" <<'EOF'
import {
  HttpErrorResponse,
  HttpInterceptorFn
} from '@angular/common/http';

import { catchError, throwError } from 'rxjs';

export const apiErrorInterceptor: HttpInterceptorFn = (req, next) =>
  next(req).pipe(
    catchError((error: HttpErrorResponse) => {
      if (error.status === 0) {
        console.error('Backend inaccessible ou erreur réseau.');
      } else if (error.status === 401) {
        console.error('Authentification requise.');
      } else if (error.status === 403) {
        console.error('Accès interdit.');
      } else {
        console.error(
          `Erreur HTTP ${error.status}: ${error.message}`
        );
      }

      return throwError(() => error);
    })
  );
EOF

# ------------------------------------------------------------
# 8. Vérification des fichiers
# ------------------------------------------------------------

echo ""
echo "Verification des services"

for FILE in \
  "$SRC/app/core/config/api.config.ts" \
  "$SRC/app/core/services/kpi.service.ts" \
  "$SRC/app/core/services/congestion.service.ts" \
  "$SRC/app/core/services/action.service.ts" \
  "$SRC/app/core/services/participant.service.ts" \
  "$SRC/app/core/services/dashboard.service.ts" \
  "$SRC/app/core/interceptors/api-error.interceptor.ts"
do
  if [ -f "$FILE" ]; then
    echo "OK : $FILE"
  else
    echo "ERREUR : $FILE"
    exit 1
  fi
done

echo ""
echo "Partie 3/8 terminee."
echo "Services HTTP crees."
echo "Aucune dependance installee."
echo "Aucun appel HTTP execute par le script."
echo "Aucun service demarre."


# ============================================================
# PARTIE 4/8 - CONFIGURATION ET ROUTAGE ANGULAR
# ============================================================

set -eu

ROOT="ran-congestion-ui"
SRC="$ROOT/src"

echo "Partie 4/8 : configuration Angular"

mkdir -p "$SRC/app"

# ------------------------------------------------------------
# 1. Configuration globale de l'application
# ------------------------------------------------------------

cat > "$SRC/app/app.config.ts" <<'EOF'
import { ApplicationConfig } from '@angular/core';
import { provideRouter } from '@angular/router';
import {
  provideHttpClient,
  withInterceptors
} from '@angular/common/http';

import { routes } from './app.routes';
import {
  apiErrorInterceptor
} from './core/interceptors/api-error.interceptor';

export const appConfig: ApplicationConfig = {
  providers: [
    provideRouter(routes),
    provideHttpClient(
      withInterceptors([apiErrorInterceptor])
    )
  ]
};
EOF

# ------------------------------------------------------------
# 2. Déclaration des routes
# ------------------------------------------------------------

cat > "$SRC/app/app.routes.ts" <<'EOF'
import { Routes } from '@angular/router';
import { ShellComponent } from './layout/shell/shell.component';

export const routes: Routes = [
  {
    path: '',
    component: ShellComponent,
    children: [
      {
        path: 'dashboard',
        loadComponent: () =>
          import('./pages/dashboard/dashboard.component')
            .then(m => m.DashboardComponent)
      },
      {
        path: 'kpis',
        loadComponent: () =>
          import('./pages/kpi-monitoring/kpi-monitoring.component')
            .then(m => m.KpiMonitoringComponent)
      },
      {
        path: 'congestion',
        loadComponent: () =>
          import('./pages/congestion/congestion.component')
            .then(m => m.CongestionComponent)
      },
      {
        path: 'actions',
        loadComponent: () =>
          import('./pages/actions/actions.component')
            .then(m => m.ActionsComponent)
      },
      {
        path: 'participants',
        loadComponent: () =>
          import('./pages/participants/participants.component')
            .then(m => m.ParticipantsComponent)
      },
      {
        path: 'settings',
        loadComponent: () =>
          import('./pages/settings/settings.component')
            .then(m => m.SettingsComponent)
      },
      {
        path: '',
        pathMatch: 'full',
        redirectTo: 'dashboard'
      }
    ]
  },
  {
    path: '**',
    redirectTo: 'dashboard'
  }
];
EOF

# ------------------------------------------------------------
# 3. Composant racine
# ------------------------------------------------------------

cat > "$SRC/app/app.component.ts" <<'EOF'
import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet],
  template: '<router-outlet />'
})
export class AppComponent {}
EOF

# ------------------------------------------------------------
# 4. Point d'entrée Angular
# ------------------------------------------------------------

cat > "$SRC/main.ts" <<'EOF'
import { bootstrapApplication } from '@angular/platform-browser';

import { AppComponent } from './app/app.component';
import { appConfig } from './app/app.config';

bootstrapApplication(AppComponent, appConfig)
  .catch(error => {
    console.error('Erreur de démarrage Angular :', error);
  });
EOF

# ------------------------------------------------------------
# 5. Document HTML principal
# ------------------------------------------------------------

cat > "$SRC/index.html" <<'EOF'
<!doctype html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <title>RAN Congestion Control</title>
  <base href="/">
  <meta name="viewport" content="width=device-width, initial-scale=1">
</head>
<body>
  <app-root></app-root>
</body>
</html>
EOF

# ------------------------------------------------------------
# 6. Vérification des fichiers
# ------------------------------------------------------------

echo ""
echo "Verification de la configuration Angular"

for FILE in \
  "$SRC/app/app.config.ts" \
  "$SRC/app/app.routes.ts" \
  "$SRC/app/app.component.ts" \
  "$SRC/main.ts" \
  "$SRC/index.html"
do
  if [ -f "$FILE" ]; then
    echo "OK : $FILE"
  else
    echo "ERREUR : $FILE"
    exit 1
  fi
done

echo ""
echo "Partie 4/8 terminee."
echo "Configuration Angular et routage prepares."
echo "Aucune dependance installee."
echo "Aucune compilation executee."
echo "Aucun serveur demarre."



# ============================================================
# PARTIE 5/8 - INTERFACE NOC ET STYLES
# ============================================================

set -eu

ROOT="ran-congestion-ui"
SRC="$ROOT/src"

echo "Partie 5/8 : interface NOC"

mkdir -p \
  "$SRC/app/layout/shell" \
  "$SRC/app/layout/sidebar" \
  "$SRC/app/layout/header"

# ------------------------------------------------------------
# 1. Composant principal de navigation
# ------------------------------------------------------------

cat > "$SRC/app/layout/shell/shell.component.ts" <<'EOF'
import { Component } from '@angular/core';
import {
  RouterLink,
  RouterLinkActive,
  RouterOutlet
} from '@angular/router';

@Component({
  selector: 'app-shell',
  standalone: true,
  imports: [
    RouterLink,
    RouterLinkActive,
    RouterOutlet
  ],
  templateUrl: './shell.component.html',
  styleUrl: './shell.component.scss'
})
export class ShellComponent {
  readonly navigation = [
    { label: 'Dashboard', path: '/dashboard' },
    { label: 'KPI Monitoring', path: '/kpis' },
    { label: 'Congestion', path: '/congestion' },
    { label: 'Historique des actions', path: '/actions' },
    { label: 'Participants réseau', path: '/participants' },
    { label: 'Configuration', path: '/settings' }
  ];
}
EOF

# ------------------------------------------------------------
# 2. Structure HTML
# ------------------------------------------------------------

cat > "$SRC/app/layout/shell/shell.component.html" <<'EOF'
<div class="app-shell">

  <aside class="sidebar">
    <a class="brand" routerLink="/dashboard">
      <strong>RAN CONTROL</strong>
      <span>Network Operations Center</span>
    </a>

    <div class="nav-heading">SUPERVISION</div>

    <nav aria-label="Navigation principale">
      @for (item of navigation; track item.path) {
        <a
          class="nav-item"
          [routerLink]="item.path"
          routerLinkActive="active"
          [attr.aria-current]="
            item.path === '/dashboard' ? null : undefined
          "
        >
          {{ item.label }}
        </a>
      }
    </nav>

    <footer class="sidebar-footer">
      <span>RAN Congestion Control</span>
      <span>Interface de supervision</span>
    </footer>
  </aside>

  <main class="main-panel">
    <header class="topbar">
      <div>
        <p class="breadcrumb">RAN / OPERATIONS</p>
        <h1>Network Operations Center</h1>
      </div>

      <div class="topbar-info">
        <span class="environment-label">ENVIRONNEMENT</span>
        <span>Interface de supervision</span>
      </div>
    </header>

    <section class="page-content">
      <router-outlet />
    </section>
  </main>

</div>
EOF

# ------------------------------------------------------------
# 3. Styles du layout
# ------------------------------------------------------------

cat > "$SRC/app/layout/shell/shell.component.scss" <<'EOF'
:host {
  display: block;
  min-height: 100vh;
}

.app-shell {
  display: grid;
  grid-template-columns: 245px minmax(0, 1fr);
  min-height: 100vh;
  background: #101010;
  color: #eeeeee;
}

.sidebar {
  display: flex;
  flex-direction: column;
  gap: 26px;
  padding: 24px 14px;
  background: #151515;
  border-right: 1px solid #414141;
}

.brand {
  display: grid;
  gap: 7px;
  padding: 10px;
  color: #eeeeee;
  text-decoration: none;
}

.brand strong {
  font-size: 14px;
  letter-spacing: 1px;
}

.brand span {
  color: #aaaaaa;
  font-size: 11px;
}

.nav-heading {
  padding: 0 10px;
  color: #999999;
  font-size: 10px;
  letter-spacing: 1.4px;
}

nav {
  display: grid;
  gap: 5px;
}

.nav-item {
  padding: 12px 10px;
  border-radius: 4px;
  color: #cccccc;
  text-decoration: none;
  font-size: 13px;
}

.nav-item:hover {
  background: #292929;
}

.nav-item.active {
  background: #333333;
  color: #ffffff;
  border-left: 3px solid #bbbbbb;
}

.sidebar-footer {
  display: grid;
  gap: 5px;
  margin-top: auto;
  padding: 16px 10px 0;
  border-top: 1px solid #414141;
  color: #aaaaaa;
  font-size: 11px;
}

.main-panel {
  min-width: 0;
}

.topbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 20px;
  min-height: 92px;
  padding: 20px 28px;
  background: #181818;
  border-bottom: 1px solid #414141;
}

.breadcrumb {
  margin: 0;
  color: #999999;
  font-size: 10px;
  letter-spacing: 1.2px;
}

.topbar h1 {
  margin: 7px 0 0;
  font-size: 20px;
  font-weight: 600;
}

.topbar-info {
  display: grid;
  gap: 5px;
  color: #bbbbbb;
  font-size: 11px;
  text-align: right;
}

.environment-label {
  color: #eeeeee;
  letter-spacing: 1px;
}

.page-content {
  padding: 28px;
  min-width: 0;
}

@media (max-width: 850px) {
  .app-shell {
    grid-template-columns: 190px minmax(0, 1fr);
  }

  .topbar {
    padding: 18px;
  }

  .page-content {
    padding: 18px;
  }
}

@media (max-width: 600px) {
  .app-shell {
    grid-template-columns: 1fr;
  }

  .sidebar {
    gap: 12px;
    padding: 12px;
  }

  nav {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .sidebar-footer {
    display: none;
  }

  .topbar {
    align-items: flex-start;
    flex-direction: column;
  }

  .topbar-info {
    text-align: left;
  }
}
EOF

# ------------------------------------------------------------
# 4. Styles globaux
# ------------------------------------------------------------

cat > "$SRC/styles.scss" <<'EOF'
:root {
  color-scheme: dark;
  font-family: Arial, Helvetica, sans-serif;
  background: #101010;
  color: #eeeeee;
}

* {
  box-sizing: border-box;
}

html,
body {
  min-height: 100%;
  margin: 0;
}

body {
  font-size: 13px;
  line-height: 1.5;
}

button,
input,
select,
textarea {
  font: inherit;
}

button,
input,
select,
textarea {
  color: #eeeeee;
  background: #181818;
  border: 1px solid #555555;
  border-radius: 4px;
}

button {
  padding: 8px 12px;
  cursor: pointer;
}

button:hover {
  background: #303030;
}

input,
select,
textarea {
  padding: 8px;
  max-width: 100%;
}

a {
  color: inherit;
}

h2 {
  margin-top: 0;
  font-size: 21px;
}

h3 {
  margin-top: 0;
  font-size: 15px;
}

p {
  line-height: 1.6;
}

.muted {
  color: #aaaaaa;
}

.panel {
  background: #181818;
  border: 1px solid #414141;
  border-radius: 5px;
}

.data-section {
  margin: 20px 0;
  padding: 18px;
}

.table-scroll {
  overflow-x: auto;
}

table {
  width: 100%;
  border-collapse: collapse;
  text-align: left;
}

th,
td {
  padding: 11px;
  border-bottom: 1px solid #414141;
}

th {
  font-weight: 600;
  white-space: nowrap;
}

:focus-visible {
  outline: 2px solid #eeeeee;
  outline-offset: 2px;
}

@media (prefers-reduced-motion: reduce) {
  *,
  *::before,
  *::after {
    scroll-behavior: auto !important;
    transition: none !important;
  }
}
EOF

# ------------------------------------------------------------
# 5. Vérification
# ------------------------------------------------------------

echo ""
echo "Verification de l'interface NOC"

for FILE in \
  "$SRC/app/layout/shell/shell.component.ts" \
  "$SRC/app/layout/shell/shell.component.html" \
  "$SRC/app/layout/shell/shell.component.scss" \
  "$SRC/styles.scss"
do
  if [ -f "$FILE" ]; then
    echo "OK : $FILE"
  else
    echo "ERREUR : $FILE"
    exit 1
  fi
done

echo ""
echo "Partie 5/8 terminee."
echo "Navigation et styles crees."
echo "Aucune dependance installee."
echo "Aucun service demarre."


# ============================================================
# PARTIE 6/8 - DASHBOARD ET KPI MONITORING
# ============================================================

set -eu

ROOT="ran-congestion-ui"
SRC="$ROOT/src"

echo "Partie 6/8 : dashboard et KPI"

mkdir -p \
  "$SRC/app/pages/dashboard" \
  "$SRC/app/pages/kpi-monitoring"

# ------------------------------------------------------------
# 1. Dashboard : logique TypeScript
# ------------------------------------------------------------

cat > "$SRC/app/pages/dashboard/dashboard.component.ts" <<'EOF'
import { Component, DestroyRef, inject } from '@angular/core';
import { DatePipe, DecimalPipe } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import {
  catchError,
  interval,
  of,
  startWith,
  switchMap
} from 'rxjs';

import { environment } from '../../../environments/environment';
import { DashboardService } from '../../core/services/dashboard.service';
import { CongestionService } from '../../core/services/congestion.service';
import { ActionService } from '../../core/services/action.service';

import { DashboardSummary } from '../../core/models/dashboard.model';
import { CongestionEvent } from '../../core/models/congestion.model';
import { ActionEvent } from '../../core/models/action.model';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [DatePipe, DecimalPipe],
  templateUrl: './dashboard.component.html',
  styleUrl: './dashboard.component.scss'
})
export class DashboardComponent {
  private readonly dashboardService = inject(DashboardService);
  private readonly congestionService = inject(CongestionService);
  private readonly actionService = inject(ActionService);
  private readonly destroyRef = inject(DestroyRef);

  summary: DashboardSummary | null = null;
  congestions: CongestionEvent[] = [];
  actions: ActionEvent[] = [];

  loading = true;
  error = '';
  lastUpdated: Date | null = null;

  constructor() {
    interval(environment.refreshIntervalMs)
      .pipe(
        startWith(0),
        switchMap(() =>
          this.dashboardService.getSummary().pipe(
            catchError(() => {
              this.error =
                'Le résumé est indisponible. Vérifiez le backend.';
              return of(null);
            })
          )
        ),
        takeUntilDestroyed(this.destroyRef)
      )
      .subscribe(result => {
        this.summary = result;
        this.loading = false;

        if (result !== null) {
          this.error = '';
          this.lastUpdated = new Date();
        }
      });

    this.refreshEvents();
  }

  refreshEvents(): void {
    this.congestionService.getEvents()
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: events => this.congestions = events,
        error: () => {
          this.error = 'Chargement des congestions impossible.';
        }
      });

    this.actionService.getHistory()
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: events => this.actions = events,
        error: () => {
          this.error = 'Chargement des actions impossible.';
        }
      });
  }
}
EOF

# ------------------------------------------------------------
# 2. Dashboard : template HTML
# ------------------------------------------------------------

cat > "$SRC/app/pages/dashboard/dashboard.component.html" <<'EOF'
<div class="page-heading">
  <div>
    <h2>Dashboard</h2>
    <p class="muted">
      Vue globale du réseau et des actions de contrôle.
    </p>
  </div>

  <button type="button" (click)="refreshEvents()">
    Actualiser les événements
  </button>
</div>

@if (error) {
  <p class="panel message" role="alert">{{ error }}</p>
}

@if (loading) {
  <p>Chargement du résumé...</p>
} @else if (summary) {
  <div class="metric-grid">
    <article class="panel metric">
      <span class="muted">Congestions actives</span>
      <strong>{{ summary.activeCongestions }}</strong>
    </article>

    <article class="panel metric">
      <span class="muted">Alertes critiques</span>
      <strong>{{ summary.criticalAlerts }}</strong>
    </article>

    <article class="panel metric">
      <span class="muted">Latence moyenne</span>
      <strong>
        {{ summary.averageLatencyMs | number:'1.1-2' }} ms
      </strong>
    </article>

    <article class="panel metric">
      <span class="muted">Utilisation moyenne</span>
      <strong>
        {{ summary.averageUtilizationPct | number:'1.1-2' }} %
      </strong>
    </article>

    <article class="panel metric">
      <span class="muted">Actions réussies</span>
      <strong>{{ summary.successfulActions }}</strong>
    </article>

    <article class="panel metric">
      <span class="muted">Actions échouées</span>
      <strong>{{ summary.failedActions }}</strong>
    </article>
  </div>
} @else {
  <p class="panel message">
    Aucune donnée de synthèse disponible.
  </p>
}

<p class="muted">
  Dernière actualisation :
  {{ lastUpdated ? (lastUpdated | date:'medium') : 'Indisponible' }}
</p>

<section class="panel data-section">
  <h3>Événements de congestion</h3>

  @if (congestions.length === 0) {
    <p class="muted">
      Aucun événement disponible ou endpoint inaccessible.
    </p>
  } @else {
    <div class="table-scroll">
      <table>
        <thead>
          <tr>
            <th>Cellule</th>
            <th>Gravité</th>
            <th>Score</th>
            <th>Prédiction</th>
            <th>Date</th>
          </tr>
        </thead>
        <tbody>
          @for (event of congestions; track event.id) {
            <tr>
              <td>{{ event.cellId }}</td>
              <td>{{ event.severity }}</td>
              <td>{{ event.congestionScore }}</td>
              <td>{{ event.predicted ? 'Oui' : 'Non' }}</td>
              <td>{{ event.timestamp | date:'short' }}</td>
            </tr>
          }
        </tbody>
      </table>
    </div>
  }
</section>

<section class="panel data-section">
  <h3>Historique récent des actions</h3>

  @if (actions.length === 0) {
    <p class="muted">
      Aucune action disponible ou endpoint inaccessible.
    </p>
  } @else {
    <div class="table-scroll">
      <table>
        <thead>
          <tr>
            <th>Cellule</th>
            <th>Type</th>
            <th>Statut</th>
            <th>Date</th>
          </tr>
        </thead>
        <tbody>
          @for (action of actions; track action.id) {
            <tr>
              <td>{{ action.cellId }}</td>
              <td>{{ action.actionType }}</td>
              <td>{{ action.status }}</td>
              <td>{{ action.timestamp | date:'short' }}</td>
            </tr>
          }
        </tbody>
      </table>
    </div>
  }
</section>
EOF

# ------------------------------------------------------------
# 3. Styles du dashboard
# ------------------------------------------------------------

cat > "$SRC/app/pages/dashboard/dashboard.component.scss" <<'EOF'
.page-heading {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 16px;
  margin-bottom: 22px;
}

.metric-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 14px;
  margin: 22px 0;
}

.metric {
  display: grid;
  gap: 10px;
  padding: 18px;
}

.metric strong {
  font-size: 25px;
  overflow-wrap: anywhere;
}

.message {
  padding: 14px;
}

@media (max-width: 900px) {
  .metric-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 560px) {
  .metric-grid {
    grid-template-columns: 1fr;
  }
}
EOF

# ------------------------------------------------------------
# 4. Page KPI Monitoring
# ------------------------------------------------------------

cat > "$SRC/app/pages/kpi-monitoring/kpi-monitoring.component.ts" <<'EOF'
import { Component, DestroyRef, inject } from '@angular/core';
import { DatePipe, DecimalPipe } from '@angular/common';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';

import { KpiService } from '../../core/services/kpi.service';
import { RanKpi } from '../../core/models/ran-kpi.model';

@Component({
  selector: 'app-kpi-monitoring',
  standalone: true,
  imports: [DatePipe, DecimalPipe],
  template: `
    <div class="page-heading">
      <div>
        <h2>KPI Monitoring</h2>
        <p class="muted">
          Mesures reçues du service de collecte KPI.
        </p>
      </div>

      <button type="button" (click)="load()">
        Actualiser
      </button>
    </div>

    @if (error) {
      <p class="panel message" role="alert">{{ error }}</p>
    }

    <section class="panel data-section table-scroll">
      <table>
        <thead>
          <tr>
            <th>Cellule</th>
            <th>Débit (Mbps)</th>
            <th>Latence (ms)</th>
            <th>Pertes (%)</th>
            <th>Utilisation (%)</th>
            <th>Horodatage</th>
          </tr>
        </thead>

        <tbody>
          @for (kpi of items; track kpi.cellId + kpi.timestamp) {
            <tr>
              <td>{{ kpi.cellId }}</td>
              <td>{{ kpi.throughputMbps | number:'1.1-2' }}</td>
              <td>{{ kpi.latencyMs | number:'1.1-2' }}</td>
              <td>{{ kpi.packetLossPct | number:'1.1-2' }}</td>
              <td>
                {{ kpi.resourceUtilizationPct | number:'1.1-2' }}
              </td>
              <td>{{ kpi.timestamp | date:'short' }}</td>
            </tr>
          }
        </tbody>
      </table>

      @if (!items.length) {
        <p class="muted">Aucun KPI disponible.</p>
      }
    </section>
  `,
  styles: [`
    .page-heading {
      display: flex;
      align-items: center;
      justify-content: space-between;
      flex-wrap: wrap;
      gap: 16px;
      margin-bottom: 22px;
    }

    .message {
      padding: 14px;
    }
  `]
})
export class KpiMonitoringComponent {
  private readonly service = inject(KpiService);
  private readonly destroyRef = inject(DestroyRef);

  items: RanKpi[] = [];
  error = '';

  constructor() {
    this.load();
  }

  load(): void {
    this.service.getLatest()
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: items => {
          this.items = items;
          this.error = '';
        },
        error: () => {
          this.error = 'Impossible de récupérer les KPI.';
        }
      });
  }
}
EOF

# ------------------------------------------------------------
# 5. Vérification des fichiers
# ------------------------------------------------------------

echo ""
echo "Verification du dashboard et des KPI"

for FILE in \
  "$SRC/app/pages/dashboard/dashboard.component.ts" \
  "$SRC/app/pages/dashboard/dashboard.component.html" \
  "$SRC/app/pages/dashboard/dashboard.component.scss" \
  "$SRC/app/pages/kpi-monitoring/kpi-monitoring.component.ts"
do
  if [ -f "$FILE" ]; then
    echo "OK : $FILE"
  else
    echo "ERREUR : $FILE"
    exit 1
  fi
done

echo ""
echo "Partie 6/8 terminee."
echo "Dashboard et KPI prepares."
echo "Aucune dependance installee."
echo "Aucune compilation executee."
echo "Aucun service demarre."


# ============================================================
# PARTIE 7/8 - CONGESTION, ACTIONS, PARTICIPANTS, CONFIGURATION
# ============================================================

set -eu

ROOT="ran-congestion-ui"
SRC="$ROOT/src"

echo "Partie 7/8 : ecrans de supervision"

mkdir -p \
  "$SRC/app/pages/congestion" \
  "$SRC/app/pages/actions" \
  "$SRC/app/pages/participants" \
  "$SRC/app/pages/settings"

# ------------------------------------------------------------
# 1. ECRAN CONGESTION
# ------------------------------------------------------------

cat > "$SRC/app/pages/congestion/congestion.component.ts" <<'EOF'
import { Component, DestroyRef, inject } from '@angular/core';
import { DatePipe, DecimalPipe } from '@angular/common';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';

import { CongestionService } from '../../core/services/congestion.service';
import { CongestionEvent } from '../../core/models/congestion.model';

@Component({
  selector: 'app-congestion',
  standalone: true,
  imports: [DatePipe, DecimalPipe],
  template: `
    <h2>Congestion et prédictions</h2>
    <p class="muted">
      Événements transmis par le service de prédiction.
    </p>

    <button type="button" (click)="load()">Actualiser</button>

    @if (error) {
      <p class="panel message" role="alert">{{ error }}</p>
    }

    <section class="panel data-section table-scroll">
      <table>
        <thead>
          <tr>
            <th>Cellule</th>
            <th>Gravité</th>
            <th>Score</th>
            <th>Prédiction</th>
            <th>Description</th>
            <th>Date</th>
          </tr>
        </thead>
        <tbody>
          @for (event of events; track event.id) {
            <tr>
              <td>{{ event.cellId }}</td>
              <td>{{ event.severity }}</td>
              <td>{{ event.congestionScore | number:'1.1-2' }}</td>
              <td>{{ event.predicted ? 'Oui' : 'Non' }}</td>
              <td>{{ event.description || '—' }}</td>
              <td>{{ event.timestamp | date:'short' }}</td>
            </tr>
          }
        </tbody>
      </table>

      @if (!events.length && !error) {
        <p class="muted">Aucun événement disponible.</p>
      }
    </section>
  `,
  styles: [`
    .message {
      padding: 14px;
    }
  `]
})
export class CongestionComponent {
  private readonly service = inject(CongestionService);
  private readonly destroyRef = inject(DestroyRef);

  events: CongestionEvent[] = [];
  error = '';

  constructor() {
    this.load();
  }

  load(): void {
    this.service.getEvents()
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: events => {
          this.events = events;
          this.error = '';
        },
        error: () => {
          this.error = 'Impossible de charger les congestions.';
        }
      });
  }
}
EOF

# ------------------------------------------------------------
# 2. ECRAN HISTORIQUE DES ACTIONS
# ------------------------------------------------------------

cat > "$SRC/app/pages/actions/actions.component.ts" <<'EOF'
import { Component, DestroyRef, inject } from '@angular/core';
import { DatePipe } from '@angular/common';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';

import { ActionService } from '../../core/services/action.service';
import { ActionEvent } from '../../core/models/action.model';

@Component({
  selector: 'app-actions',
  standalone: true,
  imports: [DatePipe],
  template: `
    <h2>Historique des actions réseau</h2>
    <p class="muted">
      Résultats des actions rapportés par le backend.
    </p>

    <button type="button" (click)="load()">Actualiser</button>

    @if (error) {
      <p class="panel message" role="alert">{{ error }}</p>
    }

    <section class="panel data-section table-scroll">
      <table>
        <thead>
          <tr>
            <th>Identifiant</th>
            <th>Cellule</th>
            <th>Action</th>
            <th>Statut</th>
            <th>Durée (ms)</th>
            <th>Date</th>
            <th>Message</th>
          </tr>
        </thead>
        <tbody>
          @for (action of actions; track action.id) {
            <tr>
              <td>{{ action.id }}</td>
              <td>{{ action.cellId }}</td>
              <td>{{ action.actionType }}</td>
              <td>{{ action.status }}</td>
              <td>{{ action.durationMs ?? '—' }}</td>
              <td>{{ action.timestamp | date:'short' }}</td>
              <td>{{ action.message || '—' }}</td>
            </tr>
          }
        </tbody>
      </table>

      @if (!actions.length && !error) {
        <p class="muted">Aucune action disponible.</p>
      }
    </section>
  `,
  styles: [`
    .message {
      padding: 14px;
    }
  `]
})
export class ActionsComponent {
  private readonly service = inject(ActionService);
  private readonly destroyRef = inject(DestroyRef);

  actions: ActionEvent[] = [];
  error = '';

  constructor() {
    this.load();
  }

  load(): void {
    this.service.getHistory()
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: actions => {
          this.actions = actions;
          this.error = '';
        },
        error: () => {
          this.error = 'Impossible de charger les actions.';
        }
      });
  }
}
EOF

# ------------------------------------------------------------
# 3. ECRAN PARTICIPANTS RESEAU
# ------------------------------------------------------------

cat > "$SRC/app/pages/participants/participants.component.ts" <<'EOF'
import { Component, DestroyRef, inject } from '@angular/core';
import { DatePipe } from '@angular/common';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';

import {
  ParticipantService
} from '../../core/services/participant.service';

import {
  ParticipantStatus
} from '../../core/models/participant.model';

@Component({
  selector: 'app-participants',
  standalone: true,
  imports: [DatePipe],
  template: `
    <h2>Participants réseau</h2>
    <p class="muted">
      État communiqué par les participants et adaptateurs réseau.
    </p>

    <button type="button" (click)="load()">Actualiser</button>

    @if (error) {
      <p class="panel message" role="alert">{{ error }}</p>
    }

    <section class="panel data-section table-scroll">
      <table>
        <thead>
          <tr>
            <th>Identifiant</th>
            <th>Nom</th>
            <th>Type</th>
            <th>État</th>
            <th>Dernière activité</th>
          </tr>
        </thead>
        <tbody>
          @for (participant of participants; track participant.id) {
            <tr>
              <td>{{ participant.id }}</td>
              <td>{{ participant.name }}</td>
              <td>{{ participant.type }}</td>
              <td>{{ participant.status }}</td>
              <td>
                {{
                  participant.lastSeen
                    ? (participant.lastSeen | date:'short')
                    : '—'
                }}
              </td>
            </tr>
          }
        </tbody>
      </table>

      @if (!participants.length && !error) {
        <p class="muted">Aucun participant disponible.</p>
      }
    </section>
  `,
  styles: [`
    .message {
      padding: 14px;
    }
  `]
})
export class ParticipantsComponent {
  private readonly service = inject(ParticipantService);
  private readonly destroyRef = inject(DestroyRef);

  participants: ParticipantStatus[] = [];
  error = '';

  constructor() {
    this.load();
  }

  load(): void {
    this.service.getStatuses()
      .pipe(takeUntilDestroyed(this.destroyRef))
      .subscribe({
        next: participants => {
          this.participants = participants;
          this.error = '';
        },
        error: () => {
          this.error = 'Impossible de charger les participants.';
        }
      });
  }
}
EOF

# ------------------------------------------------------------
# 4. ECRAN CONFIGURATION
# ------------------------------------------------------------

cat > "$SRC/app/pages/settings/settings.component.ts" <<'EOF'
import { Component } from '@angular/core';
import { FormsModule } from '@angular/forms';

import { environment } from '../../../environments/environment';

@Component({
  selector: 'app-settings',
  standalone: true,
  imports: [FormsModule],
  template: `
    <h2>Configuration</h2>
    <p class="muted">
      Paramètres de connexion de l'interface.
    </p>

    <section class="panel data-section">
      <h3>API Spring Boot</h3>

      <p>
        URL configurée :
        <strong>{{ apiBaseUrl }}</strong>
      </p>

      <p>
        Actualisation automatique :
        <strong>{{ refreshIntervalMs }} ms</strong>
      </p>

      <p class="muted">
        Ces valeurs sont définies dans le fichier
        environment.ts. Cette page est informative :
        elle ne modifie pas la configuration du backend.
      </p>
    </section>

    <section class="panel data-section">
      <h3>Services attendus</h3>
      <ul>
        <li>ran-kpi-service</li>
        <li>ran-predictor-service</li>
        <li>ran-control-service</li>
        <li>ran-action-service</li>
        <li>Participants réseau</li>
      </ul>

      <p class="muted">
        La disponibilité réelle doit être confirmée
        par les endpoints de santé du backend.
      </p>
    </section>
  `
})
export class SettingsComponent {
  readonly apiBaseUrl = environment.apiBaseUrl;
  readonly refreshIntervalMs = environment.refreshIntervalMs;
}
EOF

# ------------------------------------------------------------
# 5. Vérification des fichiers
# ------------------------------------------------------------

echo ""
echo "Verification des quatre ecrans"

for FILE in \
  "$SRC/app/pages/congestion/congestion.component.ts" \
  "$SRC/app/pages/actions/actions.component.ts" \
  "$SRC/app/pages/participants/participants.component.ts" \
  "$SRC/app/pages/settings/settings.component.ts"
do
  if [ -f "$FILE" ]; then
    echo "OK : $FILE"
  else
    echo "ERREUR : $FILE"
    exit 1
  fi
done

echo ""
echo "Partie 7/8 terminee."
echo "Quatre ecrans crees."
echo "Aucune dependance installee."
echo "Aucune action reseau executee."
echo "Aucune compilation executee."


# ============================================================
# PARTIE 8/8 - CONFIGURATION FINALE ET CONTROLES STATIQUES
# ============================================================

set -eu

ROOT="ran-congestion-ui"
SRC="$ROOT/src"

echo "Partie 8/8 : configuration finale"

mkdir -p \
  "$SRC/environments" \
  "$SRC/app"

# ------------------------------------------------------------
# 1. Environnement Angular
# ------------------------------------------------------------

cat > "$SRC/environments/environment.ts" <<'EOF'
export const environment = {
  production: false,
  apiBaseUrl: '/api',
  refreshIntervalMs: 5000
} as const;
EOF

cat > "$SRC/environments/environment.prod.ts" <<'EOF'
export const environment = {
  production: true,
  apiBaseUrl: '/api',
  refreshIntervalMs: 5000
} as const;
EOF

# ------------------------------------------------------------
# 2. Configuration TypeScript principale
# ------------------------------------------------------------

cat > "$ROOT/tsconfig.json" <<'EOF'
{
  "compileOnSave": false,
  "compilerOptions": {
    "baseUrl": ".",
    "outDir": "./dist/out-tsc",
    "strict": true,
    "noImplicitOverride": true,
    "noPropertyAccessFromIndexSignature": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "sourceMap": true,
    "declaration": false,
    "experimentalDecorators": true,
    "moduleResolution": "bundler",
    "importHelpers": true,
    "target": "ES2022",
    "module": "preserve",
    "lib": [
      "ES2022",
      "dom"
    ],
    "useDefineForClassFields": false
  },
  "angularCompilerOptions": {
    "strictInjectionParameters": true,
    "strictInputAccessModifiers": true,
    "strictTemplates": true
  }
}
EOF

# ------------------------------------------------------------
# 3. Configuration TypeScript de l'application
# ------------------------------------------------------------

cat > "$ROOT/tsconfig.app.json" <<'EOF'
{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    "outDir": "./out-tsc/app",
    "types": []
  },
  "files": [
    "src/main.ts"
  ],
  "include": [
    "src/**/*.d.ts"
  ]
}
EOF

# ------------------------------------------------------------
# 4. Configuration Angular CLI
# ------------------------------------------------------------

cat > "$ROOT/angular.json" <<'EOF'
{
  "$schema": "./node_modules/@angular/cli/lib/config/schema.json",
  "version": 1,
  "newProjectRoot": "projects",
  "projects": {
    "ran-congestion-ui": {
      "projectType": "application",
      "root": "",
      "sourceRoot": "src",
      "prefix": "app",
      "architect": {
        "build": {
          "builder": "@angular/build:application",
          "options": {
            "outputPath": "dist/ran-congestion-ui",
            "index": "src/index.html",
            "browser": "src/main.ts",
            "polyfills": [
              "zone.js"
            ],
            "tsConfig": "tsconfig.app.json",
            "inlineStyleLanguage": "scss",
            "styles": [
              "src/styles.scss"
            ],
            "assets": []
          },
          "configurations": {
            "production": {
              "optimization": true,
              "outputHashing": "all",
              "sourceMap": false
            },
            "development": {
              "optimization": false,
              "extractLicenses": false,
              "sourceMap": true
            }
          },
          "defaultConfiguration": "production"
        }
      }
    }
  }
}
EOF

# ------------------------------------------------------------
# 5. Proxy de developpement vers Spring Boot
# ------------------------------------------------------------

cat > "$ROOT/proxy.conf.json" <<'EOF'
{
  "/api": {
    "target": "http://localhost:8080",
    "secure": false,
    "changeOrigin": true,
    "logLevel": "warn",
    "pathRewrite": {
      "^/api": ""
    }
  }
}
EOF

# ------------------------------------------------------------
# 6. Manifeste des dependances
# Aucun paquet n'est installe par ce script.
# ------------------------------------------------------------

cat > "$ROOT/package.json" <<'EOF'
{
  "name": "ran-congestion-ui",
  "version": "1.0.0",
  "private": true,
  "description": "Interface de supervision RAN Congestion Control",
  "dependencies": {
    "@angular/common": "^20.0.0",
    "@angular/compiler": "^20.0.0",
    "@angular/core": "^20.0.0",
    "@angular/platform-browser": "^20.0.0",
    "@angular/router": "^20.0.0",
    "rxjs": "~7.8.0",
    "tslib": "^2.8.0",
    "zone.js": "~0.15.0"
  },
  "devDependencies": {
    "@angular/build": "^20.0.0",
    "@angular/cli": "^20.0.0",
    "@angular/compiler-cli": "^20.0.0",
    "typescript": "~5.8.0"
  }
}
EOF

# ------------------------------------------------------------
# 7. Documentation du projet
# ------------------------------------------------------------

cat > "$ROOT/README.md" <<'EOF'
# RAN Congestion Control UI

Interface Angular de supervision des services RAN.

## Modules

- Dashboard
- KPI Monitoring
- Congestion et prédictions
- Historique des actions
- Participants réseau
- Configuration

## Backend

L'interface utilise une API HTTP accessible sous /api.

Le proxy de développement cible par défaut :

http://localhost:8080

Cette adresse doit être adaptée si les services Spring Boot
utilisent un autre port ou une API Gateway différente.

## Endpoints attendus

- GET /dashboard/summary
- GET /kpis/latest
- GET /kpis/history
- GET /congestion/events
- GET /actions
- GET /actions/{id}
- GET /participants

Ces routes sont des conventions frontend.
Leur existence doit être vérifiée dans le backend.

## Installation

Les fichiers sont préparés manuellement.
Aucune dépendance n'est installée par le script de création.

Avant toute compilation future, vérifier les versions
compatibles d'Angular, de Node.js et de TypeScript.

## Sécurité

Les actions réseau restent pilotées par le backend.
Ne pas exposer Kafka directement au navigateur.
Les opérations de contrôle doivent être protégées
par une authentification et des autorisations adaptées.
EOF

# ------------------------------------------------------------
# 8. Verification des fichiers de configuration
# ------------------------------------------------------------

echo ""
echo "Verification des fichiers de configuration"

for FILE in \
  "$SRC/environments/environment.ts" \
  "$SRC/environments/environment.prod.ts" \
  "$ROOT/tsconfig.json" \
  "$ROOT/tsconfig.app.json" \
  "$ROOT/angular.json" \
  "$ROOT/proxy.conf.json" \
  "$ROOT/package.json" \
  "$ROOT/README.md"
do
  if [ -f "$FILE" ]; then
    echo "OK : $FILE"
  else
    echo "ERREUR : $FILE"
    exit 1
  fi
done

# ------------------------------------------------------------
# 9. Verification des pages et services essentiels
# ------------------------------------------------------------

echo ""
echo "Verification des composants et services"

for FILE in \
  "$SRC/main.ts" \
  "$SRC/app/app.config.ts" \
  "$SRC/app/app.routes.ts" \
  "$SRC/app/layout/shell/shell.component.ts" \
  "$SRC/app/pages/dashboard/dashboard.component.ts" \
  "$SRC/app/pages/kpi-monitoring/kpi-monitoring.component.ts" \
  "$SRC/app/pages/congestion/congestion.component.ts" \
  "$SRC/app/pages/actions/actions.component.ts" \
  "$SRC/app/pages/participants/participants.component.ts" \
  "$SRC/app/pages/settings/settings.component.ts" \
  "$SRC/app/core/services/kpi.service.ts" \
  "$SRC/app/core/services/congestion.service.ts" \
  "$SRC/app/core/services/action.service.ts" \
  "$SRC/app/core/services/participant.service.ts" \
  "$SRC/app/core/services/dashboard.service.ts"
do
  if [ -f "$FILE" ]; then
    echo "OK : $FILE"
  else
    echo "MANQUANT : $FILE"
  fi
done

echo ""
echo "Partie 8/8 terminee."
echo "Configuration Angular preparee."
echo "Proxy Spring Boot prepare."
echo "Manifeste des dependances cree."
echo "Aucune installation effectuee."
echo "Aucune compilation effectuee."
echo "Aucun service demarre."
echo ""
echo "Les 8 parties du script sont terminees."
