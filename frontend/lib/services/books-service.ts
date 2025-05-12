'use server';

import { api, RequestOptions } from '@/lib/api-client';

export type Author = {
  id: string;
  first_name: string;
  last_name: string;
  created_at: Date;
  updated_at: Date;
}
export type Book = {
    id: string;
    title: string;
    description: string;
    year: number;
    downloads: number;
    views: number;
    pages: number;
    volumes: number;
    category: string;
    cover_image_url: string;
    file_url: string
    published_date: Date;
    author: Author   
}


type Response = {
  books: Book[];
  meta: {
    current_page: number,
    per_page: number,
    total_items: number,
    total_pages: number,
    offset: number,
    categories: string[],
  }
}


export async function getAllBooks(page: number = 1, query: string = '', category= ''): Promise<Response> {
  const options: Omit<RequestOptions, 'method' | 'body'> = {
    params: {
      page,
      title: query,
      category
    },
  };
  const response = await api.get<Response>('books', options);
  return response;
}


export async function getRecentBooks(): Promise<Book[]> {
  const response = await api.get<Book[]>('books/recent/');    
  return response;
}

export async function getMostDownloadedBooks(): Promise<Book[]> {
  const response = await api.get<Book[]>('books/most_downloaded');
  return response;
}

export async function getMostViewedBooks(): Promise<Book[]> {
  const response = await api.get<Book[]>('books/most_viewed');
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
