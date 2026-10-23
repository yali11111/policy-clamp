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
