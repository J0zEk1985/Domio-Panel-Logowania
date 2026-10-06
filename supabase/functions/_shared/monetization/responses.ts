/**
 * Standard HTTP Response Helpers for Edge Functions
 */

import type { ApiResponse } from './types.ts';

export function successResponse<T>(
  data: T,
  status: number = 200
): Response {
  const response: ApiResponse<T> = {
    success: true,
    data
  };

  return new Response(
    JSON.stringify(response),
    {
      status,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type'
      }
    }
  );
}

export function errorResponse(
  code: string,
  message: string,
  status: number = 400,
  details?: any
): Response {
  const response: ApiResponse = {
    success: false,
    error: {
      code,
      message,
      details
    }
  };

  return new Response(
    JSON.stringify(response),
    {
      status,
      headers: {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type'
      }
    }
  );
}

export function validationError(errors: any): Response {
  return errorResponse(
    'VALIDATION_ERROR',
    'Invalid request data',
    400,
    errors
  );
}

export function unauthorizedError(message: string = 'Unauthorized'): Response {
  return errorResponse(
    'UNAUTHORIZED',
    message,
    401
  );
}

export function forbiddenError(message: string = 'Forbidden'): Response {
  return errorResponse(
    'FORBIDDEN',
    message,
    403
  );
}

export function notFoundError(resource: string = 'Resource'): Response {
  return errorResponse(
    'NOT_FOUND',
    `${resource} not found`,
    404
  );
}

export function internalError(message: string = 'Internal server error'): Response {
  return errorResponse(
    'INTERNAL_ERROR',
    message,
    500
  );
}

export function methodNotAllowedError(allowedMethods: string[]): Response {
  return new Response(
    JSON.stringify({
      success: false,
      error: {
        code: 'METHOD_NOT_ALLOWED',
        message: `Method not allowed. Allowed methods: ${allowedMethods.join(', ')}`
      }
    }),
    {
      status: 405,
      headers: {
        'Content-Type': 'application/json',
        'Allow': allowedMethods.join(', '),
        'Access-Control-Allow-Origin': '*'
      }
    }
  );
}

export function corsPreflightResponse(): Response {
  return new Response(null, {
    status: 204,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      'Access-Control-Max-Age': '86400'
    }
  });
}
