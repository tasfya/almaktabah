import { type ClassValue, clsx } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function formatTime(seconds: number): string {
  if (isNaN(seconds) || seconds < 0) return "00:00"

  const minutes = Math.floor(seconds / 60)
  const remainingSeconds = Math.floor(seconds % 60)

  const formattedMinutes = String(minutes).padStart(2, "0")
  const formattedSeconds = String(remainingSeconds).padStart(2, "0")

  return `${formattedMinutes}:${formattedSeconds}`
}

export function resourceUrl(path: string): string {
  const base_url = process.env.NEXT_PUBLIC_API_URL ? (process.env.NEXT_PUBLIC_API_URL ) : "http://localhost:3000/"
  return `${base_url}${path}`
}

export function formatDuration(minutes: number): string {
  if (isNaN(minutes) || minutes < 0) return "0 دقيقة"

  const hours = Math.floor(minutes / 60)
  const remainingMinutes = minutes % 60

  if (hours > 0) {
    return `${hours} ساعة ${remainingMinutes > 0 ? `و ${remainingMinutes} دقيقة` : ""}`
  }

  return `${remainingMinutes} دقيقة`
}

export function formatDate(date: Date | string | number | null | undefined): string {
  try {
    const validDate = date ? new Date(date) : new Date()
    
    if (isNaN(validDate.getTime())) {
      return "تاريخ غير صالح"
    }
    
    const options: Intl.DateTimeFormatOptions = {
      year: "numeric",
      month: "long",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    }
    return new Intl.DateTimeFormat("ar-EG", options).format(validDate)
  } catch (error) {
    return "تاريخ غير صالح"
  }
}

export function truncateText(text: string, maxLength: number): string {
  if (text.length <= maxLength) return text
  return text.slice(0, maxLength) + "..."
}

export function calculateReadingTime(text: string): number {
  const wordsPerMinute = 200
  const wordCount = text.split(/\s+/).length
  return Math.ceil(wordCount / wordsPerMinute)
}
