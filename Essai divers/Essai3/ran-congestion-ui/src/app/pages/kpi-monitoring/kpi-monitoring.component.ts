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
