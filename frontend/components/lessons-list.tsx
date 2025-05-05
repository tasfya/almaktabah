"use client"
import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { ArrowLeft, Play, FileText, Download, PlusCircle, Eye } from "lucide-react"
import Link from "next/link"
import { useState } from "react"
import AudioPlayer from "@/components/audio-player/audio-player"
import type { AudioTrack } from "@/types"
import { Lesson } from "@/lib/services/lessons-service"
import { formatDate } from "@/lib/utils"
import Image from "next/image"
import { Badge } from "./ui/badge"
import { useAudioPlayer } from "@/context/AudioPlayerContext"

export function RecentLessons({ lessons }: { lessons: Lesson[] }) {
  const { setTrack } = useAudioPlayer()
  


  const audioTracks: { [key: string]: AudioTrack } = lessons.reduce(
    (acc, lesson) => ({
      ...acc,
      [lesson.id]: {
        id: Number(lesson.id),
        title: lesson.title,
        artist: "الشيخ عبد الله",
        audioUrl: ("http://localhost:3000/" + lesson.audio_url),
        duration: lesson.duration || 300,
        thumbnailUrl: lesson.thumbnail_url || "/placeholder.svg",
        type: "lesson"
      }
    }),
    {}
  );

  const handlePlayClick = (lessonId: string) => {
    setTrack(audioTracks[lessonId])
  }

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
                  <Button variant="outline" size="sm" className="rounded-md">
                    <Download className="h-4 w-4 ml-1" />
                    <span>تحميل</span>
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
        ))}
      </div>

    </section>
  )
}

export function LessonsList({ lessons }: { lessons: Lesson[] }) {
  const [currentTrack, setCurrentTrack] = useState<AudioTrack | null>(null)
  const [showPlayer, setShowPlayer] = useState(false)


  const audioTracks: { [key: string]: AudioTrack } = lessons.reduce(
    (acc, lesson) => ({
      ...acc,
      [lesson.id]: {
        id: Number(lesson.id),
        title: lesson.title,
        artist: "الشيخ عبد الله",
        audioUrl: ("http://localhost:3000/" + lesson.audio_url),
        duration: lesson.duration || 300,
        thumbnailUrl: lesson.thumbnail_url || "/placeholder.svg",
        type: "lesson"
      }
    }),
    {}
  );

  const handlePlayClick = (lessonId: string) => {
    setCurrentTrack(audioTracks[lessonId])
    setShowPlayer(true)
  }

  const handleClosePlayer = () => {
    setShowPlayer(false)
  }

  return (
    <section>
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-2xl font-bold">أحدث الدروس العلمية</h2>
      </div>

      <div className="space-y-4">
        {lessons.map((lesson) => (
          <Card
            key={lesson.id}
            className="overflow-hidden border border-gray-100 shadow-sm hover:shadow-md transition-shadow"
          >
            <CardContent className="relative h-48 md:h-64" key={lesson.id}>
              <Image
                src={"http://localhost:3000/" + lesson.thumbnail_url || "/placeholder.svg?height=300&width=800"}
                alt={lesson.title}
                fill
                className="object-cover"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/50 to-transparent"></div>
              <div className="absolute bottom-0 right-0 p-6 text-white">
                <span className="bg-emerald-600 text-white px-2 py-1 rounded text-xs mb-3 inline-block">{lesson.category}</span>
                <h2 className="text-2xl font-bold mb-2">{lesson.title}</h2>
                <p className="text-gray-200 mb-3 max-w-xl">
                  سلسلة دروس في شرح كتاب التوحيد للإمام محمد بن عبد الوهاب، يتناول فيها الشيخ أهم مسائل العقيدة.
                </p>
                <div className="flex gap-3 text-black">
                  <Button
                    variant="outline"
                    size="sm"
                    className="rounded-md"
                    onClick={() => handlePlayClick(lesson.id)}
                  >
                    <Play className="h-4 w-4 ml-1" />
                    <span>استماع</span>
                  </Button>
                  <Button variant="outline" size="sm">
                    <Download className="h-4 w-4 ml-1" />
                    <span>تحميل</span>
                  </Button>
                  <Link href={`/lessons/${lesson.id}`}>
                    <Button>
                      <Eye className="h-4 w-4 ml-1" />
                      قراءة
                    </Button>
                  </Link>
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Audio Player */}
      {showPlayer && currentTrack && (
        <AudioPlayer
          track={currentTrack}
          onClose={handleClosePlayer}
          autoplay={true}
        />
      )}
    </section>
  )
}
