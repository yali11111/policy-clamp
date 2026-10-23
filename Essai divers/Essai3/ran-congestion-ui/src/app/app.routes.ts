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
