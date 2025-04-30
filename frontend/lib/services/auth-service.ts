'use server';

import { api } from '../api-client';
import { User } from '@/types';
import { cookies } from 'next/headers';

type AuthResponse = {
  token: string;
  user: {
    data: {
      id: string;
      type: string;
      attributes: User;
    }
  }
};

export async function login(email: string, password: string): Promise<{ user: User; token: string }> {
  try {
    const response = await api.post<AuthResponse>('login', { user: { email, password } }, { requiresAuth: false });
    
    // Set the token in a server cookie
    const cookieStore = await cookies();
    cookieStore.set('authToken', response.token, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      maxAge: 60 * 60 * 24 * 7, // 1 week
      path: '/',
    });
    
    return { 
      user: response.user.data.attributes,
      token: response.token 
    };
  } catch (error) {
    console.error('Login error:', error);
    throw error;
  }
}

export async function signup(email: string, password: string, passwordConfirmation: string): Promise<{ user: User; token: string }> {
  try {
    const response = await api.post<AuthResponse>('signup', { 
      user: { 
        email, 
        password, 
        password_confirmation: passwordConfirmation 
      } 
    }, { requiresAuth: false });
    
    // Set the token in a server cookie
    const cookieStore =await cookies();
    cookieStore.set('authToken', response.token, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      maxAge: 60 * 60 * 24 * 7, // 1 week
      path: '/',
    });
    
    return { 
      user: response.user.data.attributes,
      token: response.token 
    };
  } catch (error) {
    console.error('Signup error:', error);
    throw error;
  }
}

export async function logout(): Promise<void> {
  // Clear the auth cookie
  const cookieStore =await cookies();
  cookieStore.set('authToken', '', {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    maxAge: 0,
    path: '/',
  });
}

export async function getCurrentUser(): Promise<User | null> {
  try {
    const response = await api.get<{ data: { attributes: User } }>('current_user');
    return response.data.attributes;
  } catch (error) {
    // If there's an error (like 401), the user is not authenticated
    return null;
  }
}