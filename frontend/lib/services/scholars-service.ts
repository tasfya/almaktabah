'use server';

import { api } from '../api-client';
import { Scholar } from '@/types';

type ScholarResponse = { data: Scholar };
type ScholarsResponse = { data: Scholar[] };

export async function getAllScholars(): Promise<Scholar[]> {
  const response = await api.get<ScholarsResponse>('scholars');
  return response.data;
}

export async function getScholarById(id: number | string): Promise<Scholar> {
  const response = await api.get<ScholarResponse>(`scholars/${id}`);
  return response.data;
}

export async function createScholar(data: Partial<Scholar>): Promise<Scholar> {
  const response = await api.post<ScholarResponse>('scholars', { scholar: data });
  return response.data;
}

export async function updateScholar(id: number | string, data: Partial<Scholar>): Promise<Scholar> {
  const response = await api.put<ScholarResponse>(`scholars/${id}`, { scholar: data });
  return response.data;
}

export async function deleteScholar(id: number | string): Promise<void> {
  await api.delete(`scholars/${id}`);
}