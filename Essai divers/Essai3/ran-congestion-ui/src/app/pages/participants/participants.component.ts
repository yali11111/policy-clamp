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
