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
