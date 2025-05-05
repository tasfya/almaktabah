"use client"
import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { ArrowLeft, Play, FileText, Eye } from "lucide-react"
import Link from "next/link"
import type { AudioTrack } from "@/types"
import { Lesson } from "@/lib/services/lessons-service"
import { formatDate, resourceUrl } from "@/lib/utils"
import { Badge } from "@/components/ui/badge"
import { useAudioPlayer } from "@/context/AudioPlayerContext"

function LessonCard({ lesson }: { lesson: Lesson }) {
  const { setTrack } = useAudioPlayer()
  const handlePlayClick = (lessonId: string) => {
    const audioTrack: AudioTrack = {
      id: Number(lessonId),
      title: lesson.title,
      artist: "الشيخ عبد الله",
      audioUrl: resourceUrl(lesson.audio_url),
      duration: lesson.duration || 300,
      thumbnailUrl: resourceUrl(lesson.thumbnail_url),
      type: "lesson"
    }
    setTrack(audioTrack)
  }
  return (
    <Card
      key={lesson.id}
      className="overflow-hidden border border-gray-100 shadow-sm hover:shadow-md transition-shadow"
    >
      <CardContent className="p-4">
        <div className="flex flex-col md:flex-row md:items-center gap-4">
          <div className="flex-shrink-0 flex items-center justify-center w-12 h-12 rounded-full border text-primary">
            <FileText className="h-6 w-6" />
          </div>
          <div className="flex-1">
            <div className="flex flex-wrap items-center gap-2 mb-1">
              <span className="text-xs text-gray-500">{formatDate(lesson.published_date)}</span>
              <Badge>{"دروس علمية"}</Badge>
              <span className="bg-gray-100 text-gray-700 px-2 py-0.5 rounded text-xs">{lesson.category}</span>
            </div>
            <h3 className="text-lg font-medium">{lesson.title}</h3>
          </div>
          <div className="flex flex-wrap items-center gap-2 mt-3 md:mt-0">
            <Button
              variant="outline"
              size="sm"
              className="rounded-md"
              onClick={() => handlePlayClick(lesson.id)}
            >
              <Play className="h-4 w-4 ml-1" />
              <span>استماع</span>
            </Button>
            <Link href={`/lessons/${lesson.id}`}>
              <Button size="sm">
                <Eye className="h-4 w-4 ml-1" />
                قراءة
              </Button>
            </Link>
          </div>
        </div>
      </CardContent>
    </Card>
  )
}

export function RecentLessons({ lessons }: { lessons: Lesson[] }) {

  return (
    <section>
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-2xl font-bold">أحدث الدروس العلمية</h2>
        <Button asChild variant="link">
          <Link href="/lessons">
            عرض الكل <ArrowLeft className="h-4 w-4 mr-1" />
          </Link>
        </Button>
      </div>

      <div className="space-y-4">
        {lessons.map((lesson) => (
          <LessonCard key={lesson.id} lesson={lesson} />
        ))}
      </div>

    </section>
  )
}

export function LessonsList({ lessons }: { lessons: Lesson[] }) {
  return (
    <section>
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-2xl font-bold">أحدث الدروس العلمية</h2>
      </div>

      <div className="space-y-4">
        {lessons.map((lesson) => (
          <LessonCard key={lesson.id} lesson={lesson} />
        ))}
      </div>
    </section>
  )
}
