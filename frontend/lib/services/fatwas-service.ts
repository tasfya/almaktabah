'use server';

import { api, RequestOptions } from '@/lib/api-client';

export type Fatwa = {
  id: string;
  title: string;
  question: RichText;
  answer: RichText;
  category: string;
  views: number;
  published_date: Date;
}

export type RichText = {
  name: string;
  body: string;
  id: string;
}

type Response = {
  fatwas: Fatwa[];
  meta: {
    current_page: number,
    per_page: number,
    total_items: number,
    total_pages: number,
    offset: number,
    categories: string[],
  }
}

export async function getAllFatwas(page: number = 1, query: string = '', category = ''): Promise<Response> {
  const options: Omit<RequestOptions, 'method' | 'body'> = {
    params: {
      page,
      title: query,
      category
    },
  };
  const response = await api.get<Response>('fatwas', options);
  return response;
}

export async function getRecentFatwas(): Promise<Fatwa[]> {
  const response = await api.get<Fatwa[]>('fatwas/recent');  
  return response;
}

export async function getFatwaById(id: number | string): Promise<Fatwa> {
  const response = await api.get<Fatwa>(`fatwas/${id}`);
  return response;
}

export async function createFatwa(data: Partial<Fatwa>): Promise<Fatwa> {
  const response = await api.post<Fatwa>('fatwas', { fatwa: data });
  return response;
}

export async function updateFatwa(id: number | string, data: Partial<Fatwa>): Promise<Fatwa> {
  const response = await api.put<Fatwa>(`fatwas/${id}`, { fatwa: data });
  return response;
}

export async function deleteFatwa(id: number | string): Promise<void> {
  await api.delete(`fatwas/${id}`);
}
