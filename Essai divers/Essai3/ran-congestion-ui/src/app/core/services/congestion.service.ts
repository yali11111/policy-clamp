import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';

import { environment } from '../../../environments/environment';
import { API_ENDPOINTS } from '../config/api.config';
import { CongestionEvent } from '../models/congestion.model';

@Injectable({ providedIn: 'root' })
export class CongestionService {
  private readonly http = inject(HttpClient);
  private readonly url =
    `${environment.apiBaseUrl}${API_ENDPOINTS.congestionEvents}`;

  getEvents(severity?: string): Observable<CongestionEvent[]> {
    let params = new HttpParams();

    if (severity) {
      params = params.set('severity', severity);
    }

    return this.http.get<CongestionEvent[]>(
      this.url,
      { params }
    );
  }
}
