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
