import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';

import { environment } from '../../../environments/environment';
import { API_ENDPOINTS } from '../config/api.config';
import { RanKpi } from '../models/ran-kpi.model';

@Injectable({ providedIn: 'root' })
export class KpiService {
  private readonly http = inject(HttpClient);
  private readonly baseUrl = environment.apiBaseUrl;

  getLatest(cellId?: string): Observable<RanKpi[]> {
    let params = new HttpParams();

    if (cellId) {
      params = params.set('cellId', cellId);
    }

    return this.http.get<RanKpi[]>(
      `${this.baseUrl}${API_ENDPOINTS.kpis}`,
      { params }
    );
  }

  getHistory(
    cellId: string,
    from: string,
    to: string
  ): Observable<RanKpi[]> {
    const params = new HttpParams()
      .set('cellId', cellId)
      .set('from', from)
      .set('to', to);

    return this.http.get<RanKpi[]>(
      `${this.baseUrl}${API_ENDPOINTS.kpiHistory}`,
      { params }
    );
  }
}
