import {
  HttpErrorResponse,
  HttpInterceptorFn
} from '@angular/common/http';

import { catchError, throwError } from 'rxjs';

export const apiErrorInterceptor: HttpInterceptorFn = (req, next) =>
  next(req).pipe(
    catchError((error: HttpErrorResponse) => {
      if (error.status === 0) {
        console.error('Backend inaccessible ou erreur réseau.');
      } else if (error.status === 401) {
        console.error('Authentification requise.');
      } else if (error.status === 403) {
        console.error('Accès interdit.');
      } else {
        console.error(
          `Erreur HTTP ${error.status}: ${error.message}`
        );
      }

      return throwError(() => error);
    })
  );
