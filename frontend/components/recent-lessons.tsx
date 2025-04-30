"use client"
import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { ArrowLeft, Play, FileText, Download } from "lucide-react"
import Link from "next/link"
import { useState } from "react"
import AudioPlayer from "@/components/audio-player/audio-player"
import type { AudioTrack } from "@/types"

export default function RecentLessons() {
  const [currentTrack, setCurrentTrack] = useState<AudioTrack | null>(null)
  const [showPlayer, setShowPlayer] = useState(false)

  const lessons = [
    {
      id: 1,
      title: "العقيدة الطحاوية 1 من بداية الكتاب - إلى قوله وَلا شَيْءَ مِثْلُهُ",
      date: "2018/03/13",
      type: "دروس علمية",
      category: "العقيدة",
    },
    {
      id: 2,
      title: "كتاب الحج - حل العقدة في شرح العمدة -7",
      date: "2023/05/20",
      type: "دروس علمية",
      category: "الفقه",
    },
    {
      id: 3,
      title: "كتاب الحج - حل العقدة في شرح العمدة -8",
      date: "2023/06/15",
      type: "دروس علمية",
      category: "الفقه",
    },
    {
      id: 4,
      title: "كتاب الحج - حل العقدة في شرح العمدة -9",
      date: "2023/07/10",
      type: "دروس علمية",
      category: "الفقه",
    },
    {
      id: 5,
      title: "كتاب الحج - حل العقدة في شرح العمدة -10",
      date: "2023/08/05",
      type: "دروس علمية",
      category: "الفقه",
    },
  ]

  // Sample audio tracks with internet URLs
  const audioTracks: { [key: number]: AudioTrack } = {
    1: {
      id: 1,
      title: "العقيدة الطحاوية 1 من بداية الكتاب - إلى قوله وَلا شَيْءَ مِثْلُهُ",
      artist: "الشيخ عبد الله",
      audioUrl: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
      duration: 372,
      thumbnailUrl: "/placeholder.svg",
      type: "lesson"
    },
    2: {
      id: 2,
      title: "كتاب الحج - حل العقدة في شرح العمدة -7",
      artist: "الشيخ عبد الله",
      audioUrl: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3",
      duration: 247,
      thumbnailUrl: "/placeholder.svg",
      type: "lesson"
    },
    3: {
      id: 3,
      title: "كتاب الحج - حل العقدة في شرح العمدة -8",
      artist: "الشيخ عبد الله",
      audioUrl: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3",
      duration: 328,
      thumbnailUrl: "/placeholder.svg",
      type: "lesson"
    },
    4: {
      id: 4,
      title: "كتاب الحج - حل العقدة في شرح العمدة -9",
      artist: "الشيخ عبد الله",
      audioUrl: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3",
      duration: 412,
      thumbnailUrl: "/placeholder.svg",
      type: "lesson"
    },
    5: {
      id: 5,
      title: "كتاب الحج - حل العقدة في شرح العمدة -10",
      artist: "الشيخ عبد الله",
      audioUrl: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3",
      duration: 284,
      thumbnailUrl: "/placeholder.svg",
      type: "lesson"
    },
  }

  const handlePlayClick = (lessonId: number) => {
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
        <Button variant="ghost" className="text-emerald-600 hover:text-emerald-700">
          عرض الكل <ArrowLeft className="h-4 w-4 mr-1" />
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
                <div className="flex-shrink-0 flex items-center justify-center w-12 h-12 rounded-full bg-emerald-50 text-emerald-600">
                  <FileText className="h-6 w-6" />
                </div>
                <div className="flex-1">
                  <div className="flex flex-wrap items-center gap-2 mb-1">
                    <span className="text-xs text-gray-500">{lesson.date}</span>
                    <span className="bg-emerald-50 text-emerald-700 px-2 py-0.5 rounded text-xs">{lesson.type}</span>
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
                  <Link href={`/lesson/${lesson.id}`}>
                    <Button variant="ghost" size="sm" className="text-emerald-600">
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
