'use server';

import { api, RequestOptions } from '@/lib/api-client';
import { title } from 'process';

export type Lesson = {
  id: string;
  title: string;
  duration: number;
  category: string;
  description: string;
  thumbnail_url: string;
  content: RichText;
  audio_url: string;
  published_date: Date;
}

export type RichText = {
  name: string;
  body: string;
  id: string;
}

export type LessonsResponse = {
  lessons: Lesson[];
  meta: {
    current_page: number,
    per_page: number,
    total_items: number,
    total_pages: number,
    offset: number,
    categories: string[],
  }
}

export async function getAllLessons(page: number = 1, query: string = '', category= ''): Promise<LessonsResponse> {
  const options: Omit<RequestOptions, 'method' | 'body'> = {
    params: {
      page,
      title: query,
      category
    },
  };
  const response = await api.get<LessonsResponse>('lessons', options);
  return response;
}

export async function getRecentLessons(): Promise<Lesson[]> {
  const response = await api.get<Lesson[]>('lessons/recent');  
  return response;
}


export async function getLessonById(id: number | string): Promise<Lesson> {
  const response = await api.get<Lesson>(`lessons/${id}`);
  return response;
}

export async function createLesson(data: Partial<Lesson>): Promise<Lesson> {
  const response = await api.post<Lesson>('lessons', { Lesson: data });
  return response;
}

export async function updateLesson(id: number | string, data: Partial<Lesson>): Promise<Lesson> {
  const response = await api.put<Lesson>(`lessons/${id}`, { Lesson: data });
  return response;
}

export async function deleteLesson(id: number | string): Promise<void> {
  await api.delete(`lessons/${id}`);
}
