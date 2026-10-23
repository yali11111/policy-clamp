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
