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
