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
