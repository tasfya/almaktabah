"use client"
import Image from "next/image"
import { Button } from "@/components/ui/button"
import { Badge } from "./ui/badge"
import { formatDate } from "@/lib/utils"
import { Lesson } from "@/lib/services/lessons-service"
import { useAudioPlayer } from "@/context/AudioPlayerContext"
import { AudioTrack } from "@/types"
import Link from "next/link"

export default function Hero({ lesson }: { lesson: Lesson }) {
  const { setTrack } = useAudioPlayer()
  const track: AudioTrack = {
    id: Number(lesson.id),
    title: lesson.title,
    artist: "الشيخ عبد الله",
    audioUrl: ("http://localhost:3000/" + lesson.audio_url),
    duration: lesson.duration || 300,
    thumbnailUrl: ("http://localhost:3000" + lesson.thumbnail_url) || "/placeholder.svg",
    type: "lesson"
  }
  return (
    <section className="relative w-full h-[500px] overflow-hidden">
      {/* Background Image */}
      <div className="absolute inset-0">
        <Image
          src={"http://localhost:3000/" + lesson.thumbnail_url}
          alt="Hero background"
          fill
          className="object-cover"
          priority
        />
        <div className="absolute inset-0 bg-black/20"></div>
      </div>

      {/* Content */}
      <div className="relative container mx-auto h-full flex flex-col justify-center p-6 md:p-12">
        <div className="max-w-3xl">
          <div className="flex items-center text-sm mb-3 gap-2">
            <Badge className="text-slate-50">{lesson.category}</Badge>
            <span className="text-white">{formatDate(lesson.published_date)}</span>
          </div>
          <h1 className="text-3xl md:text-5xl font-bold mb-6 text-white"> {lesson.title}</h1>
          <p className="text-sm md:text-base mb-8 leading-relaxed text-white">{lesson.description}</p>
          <div className="flex flex-wrap gap-4">
            <Link href={`/lessons/${lesson.id}`}>
              <Button>قراءة المزيد</Button>
            </Link>
            <Button variant="outline" onClick={() => setTrack(track)}>
              استماع للخطبة
            </Button>
          </div>
        </div>
      </div>
    </section>
  )
}
