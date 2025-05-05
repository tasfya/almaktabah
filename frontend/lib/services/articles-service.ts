'use server';

import { api } from '../api-client';
import { Article } from '@/types';

type ArticleResponse = { data: Article };
type ArticlesResponse = { data: Article[] };

export async function getAllArticles(): Promise<Article[]> {
  const response = await api.get<ArticlesResponse>('articles');
  return response.data;
}

export async function getArticleById(id: number | string): Promise<Article> {
  const response = await api.get<ArticleResponse>(`articles/${id}`);
  return response.data;
}

export async function createArticle(data: Partial<Article>): Promise<Article> {
  const response = await api.post<ArticleResponse>('articles', { article: data });
  return response.data;
}

export async function updateArticle(id: number | string, data: Partial<Article>): Promise<Article> {
  const response = await api.put<ArticleResponse>(`articles/${id}`, { article: data });
  return response.data;
}

export async function deleteArticle(id: number | string): Promise<void> {
  await api.delete(`articles/${id}`);
}