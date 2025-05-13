'use server';

import { api, RequestOptions } from '@/lib/api-client';

export type Lecture = {
  id: string;
  title: string;
  category: string;
  description: string;
  duration: number;
  views: number;
  thumbnail_url: string;
  audio_url: string;
  published_date: string;
}

export type RichText = {
  name: string;
  body: string;
  id: string;
}

export type Response = {
  lectures: Lecture[];
  meta: {
    current_page: number,
    per_page: number,
    total_items: number,
    total_pages: number,
    offset: number,
    categories: string[],
  }
}

export async function getAllLectures(page: number = 1, query: string = '', category= ''): Promise<Response> {
  const options: Omit<RequestOptions, 'method' | 'body'> = {
    params: {
      page,
      title: query,
      category
    },
  };
  const response = await api.get<Response>('lectures', options);
  return response;
}

export async function getRecentLecturess(): Promise<Lecture[]> {
  const response = await api.get<Lecture[]>('lectures/recent');  
  return response;
}


export async function getLessonById(id: number | string): Promise<Lecture> {
  const response = await api.get<Lecture>(`lectures/${id}`);
  return response;
}

export async function createLesson(data: Partial<Lecture>): Promise<Lecture> {
  const response = await api.post<Lecture>('lectures', { lecture: data });
  return response;
}

export async function updateLesson(id: number | string, data: Partial<Lecture>): Promise<Lecture> {
  const response = await api.put<Lecture>(`lectures/${id}`, { lecture: data });
  return response;
}

export async function deleteLesson(id: number | string): Promise<void> {
  await api.delete(`lectures/${id}`);
}
