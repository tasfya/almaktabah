/**
 * API client for interacting with the Rails backend
 */


const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000/api';

type RequestOptions = {
  method?: 'GET' | 'POST' | 'PUT' | 'DELETE';
  headers?: Record<string, string>;
  body?: any;
  cache?: RequestCache;
  requiresAuth?: boolean;
};

type ApiErrorType = {
  message: string;
  status: number;
  data?: any;
  name: string;
};

export const createApiError = async (message: string, status: number, data?: any): Promise<ApiErrorType> => ({
  message,
  status,
  data,
  name: 'ApiError'
});

async function apiRequest<T>(endpoint: string, options: RequestOptions = {}): Promise<T> {
  const {
    method = 'GET',
    headers = {},
    body,
    cache = 'default',
    requiresAuth = true,
  } = options;

  const requestHeaders: Record<string, string> = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    ...headers,
  };

  // Add authorization header if needed
//   if (requiresAuth) {
//     try {
//       const cookieStore = await cookies();
//       const authToken = cookieStore.get('authToken')?.value;
      
//       if (authToken) {
//         requestHeaders['Authorization'] = `Bearer ${authToken}`;
//       }
//     } catch (error) {
//       // cookies() can only be used in a Server Component or Route Handler
//       console.warn('Unable to access cookies for auth token');
//     }
//   }

  const requestOptions: RequestInit = {
    method,
    headers: requestHeaders,
    cache,
  };

  if (body) {
    requestOptions.body = JSON.stringify(body);
  }

  const url = `${API_BASE_URL}${endpoint.startsWith('/') ? endpoint : `/${endpoint}`}`;
  
  try {
    const response = await fetch(url, requestOptions);
    
    // Handle non-JSON responses
    const contentType = response.headers.get('content-type');
    if (contentType && contentType.indexOf('application/json') !== -1) {
      const data = await response.json();
      
      if (!response.ok) {
        throw createApiError(
          data.error || 'An error occurred while making the request',
          response.status,
          data
        );
      }      
      return data as T;
    } else {
      if (!response.ok) {
        const text = await response.text();
        throw createApiError(
          text || 'An error occurred while making the request',
          response.status
        );
      }
      
      const text = await response.text();
      return text as unknown as T;
    }
  } catch (error) {
    if (error && typeof error === 'object' && 'name' in error && error.name === 'ApiError') {
      throw error;
    }
    
    throw createApiError(
      error instanceof Error ? error.message : 'An unknown error occurred',
      500
    );
  }
}

// Helper methods for common HTTP methods
export const api = {
    get: async <T>(endpoint: string, options?: Omit<RequestOptions, 'method' | 'body'>) => 
        await apiRequest<T>(endpoint, { ...options, method: 'GET' }),
        
    post: async <T>(endpoint: string, body: any, options?: Omit<RequestOptions, 'method'>) => 
        await apiRequest<T>(endpoint, { ...options, method: 'POST', body }),
        
    put: async <T>(endpoint: string, body: any, options?: Omit<RequestOptions, 'method'>) => 
        await apiRequest<T>(endpoint, { ...options, method: 'PUT', body }),
        
    delete: async <T>(endpoint: string, options?: Omit<RequestOptions, 'method'>) => 
        await apiRequest<T>(endpoint, { ...options, method: 'DELETE' }),
};