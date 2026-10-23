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
