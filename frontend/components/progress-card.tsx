"use client"

import { Card, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Play, Book, FileText, Clock, Calendar } from "lucide-react"
import Link from "next/link"
import { formatTime } from "@/lib/utils"
import { lessons, books, fatwas, getUserProgress } from "@/lib/data"
import type { Lesson, Fatwa } from "@/types"

interface ProgressCardProps {
  id: number
  type: "lesson" | "book" | "fatwa"
  onPlay?: (lesson: Lesson) => void
}

export default function ProgressCard({ id, type, onPlay }: ProgressCardProps) {
  const userProgress = getUserProgress()

  // Get content based on type
  let content: Lesson | Book | Fatwa | undefined
  let progress = 0
  let lastPosition = 0
  let lastAccessed = ""

  if (type === "lesson") {
    content = lessons.find((lesson) => lesson.id === id)
    progress = userProgress.lessons[id]?.progress || 0
    lastPosition = userProgress.lessons[id]?.lastPosition || 0
    lastAccessed = userProgress.lessons[id]?.lastAccessed || ""
  } else if (type === "book") {
    content = books.find((book) => book.id === id)
    progress = userProgress.books[id]?.progress || 0
    lastAccessed = userProgress.books[id]?.lastAccessed || ""
  } else if (type === "fatwa") {
    content = fatwas.find((fatwa) => fatwa.id === id)
    lastAccessed = userProgress.fatwas[id]?.lastAccessed || ""
  }

  if (!content) return null

  return (
    <Card className="overflow-hidden border border-gray-100 shadow-sm hover:shadow-md transition-shadow">
      <CardContent className="p-4">
        <div className="flex items-start gap-4">
          <div className="flex-shrink-0 flex items-center justify-center w-10 h-10 rounded-full bg-emerald-50 text-emerald-600 mt-1">
            {type === "lesson" && <Play className="h-5 w-5" />}
            {type === "book" && <Book className="h-5 w-5" />}
            {type === "fatwa" && <FileText className="h-5 w-5" />}
          </div>

          <div className="flex-1">
            <div className="flex flex-wrap items-center gap-2 mb-1">
              <span className="text-xs text-gray-500">
                {lastAccessed ? new Date(lastAccessed).toLocaleDateString("ar-SA") : ""}
              </span>

              {type === "lesson" && (
                <span className="bg-emerald-50 text-emerald-700 px-2 py-0.5 rounded text-xs">
                  {(content as Lesson).type}
                </span>
              )}

              {type === "lesson" && (
                <span className="bg-gray-100 text-gray-700 px-2 py-0.5 rounded text-xs">
                  {(content as Lesson).category}
                </span>
              )}

              {type === "book" && <span className="bg-blue-50 text-blue-700 px-2 py-0.5 rounded text-xs">كتاب</span>}

              {type === "fatwa" && (
                <span className="bg-amber-50 text-amber-700 px-2 py-0.5 rounded text-xs">
                  {(content as Fatwa).category}
                </span>
              )}
            </div>

            <h3 className="text-lg font-medium mb-2">{content.title}</h3>

            {progress > 0 && (
              <div className="mb-3">
                <div className="flex justify-between text-xs text-gray-500 mb-1">
                  <span>التقدم</span>
                  <span>{progress}%</span>
                </div>
                <div className="w-full h-1.5 bg-gray-100 rounded-full">
                  <div className="h-full bg-emerald-600 rounded-full" style={{ width: `${progress}%` }} />
                </div>
              </div>
            )}

            <div className="flex flex-wrap items-center gap-4 mt-3">
              {type === "lesson" && lastPosition > 0 && (
                <div className="flex items-center text-sm text-gray-600">
                  <Clock className="h-4 w-4 ml-1" />
                  <span>{formatTime(lastPosition)}</span>
                </div>
              )}

              {type === "lesson" && (
                <div className="flex items-center text-sm text-gray-600">
                  <Calendar className="h-4 w-4 ml-1" />
                  <span>{(content as Lesson).date}</span>
                </div>
              )}
            </div>

            <div className="flex flex-wrap items-center gap-2 mt-3">
              {type === "lesson" && onPlay && (
                <Button
                  variant="default"
                  size="sm"
                  className="bg-emerald-600 hover:bg-emerald-700"
                  onClick={() => onPlay(content as Lesson)}
                >
                  <Play className="h-4 w-4 ml-1" />
                  {lastPosition > 0 ? "استكمال الاستماع" : "استماع"}
                </Button>
              )}

              <Link href={`/${type}/${id}`}>
                <Button variant="outline" size="sm">
                  {type === "lesson" ? "عرض الدرس" : type === "book" ? "عرض الكتاب" : "عرض الفتوى"}
                </Button>
              </Link>
            </div>
          </div>
        </div>
      </CardContent>
    </Card>
  )
}
