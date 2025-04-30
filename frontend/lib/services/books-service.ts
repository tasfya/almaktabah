'use server';

import { api } from '@/lib/api-client';

type Author = {
  id: string;
  first_name: string;
  last_name: string;
  created_at: Date;
  updated_at: Date;
}
type Book = {
    id: string;
    created_at: Date;
    updated_at: Date;
    author: Author   
}


export async function getAllBooks(): Promise<Book[]> {
  const response = await api.get<Book[]>('books');
  return response;
}

export async function getBookById(id: number | string): Promise<Book> {
  const response = await api.get<Book>(`books/${id}`);
  return response;
}

export async function createBook(data: Partial<Book>): Promise<Book> {
  const response = await api.post<Book>('books', { book: data });
  return response;
}

export async function updateBook(id: number | string, data: Partial<Book>): Promise<Book> {
  const response = await api.put<Book>(`books/${id}`, { book: data });
  return response;
}

export async function deleteBook(id: number | string): Promise<void> {
  await api.delete(`books/${id}`);
}
