import { Button } from "@/components/ui/button"
import { Calendar, Copy, Share2, Bookmark } from "lucide-react"
import Link from "next/link"
import { useState } from "react"
import AudioPlayer from "@/components/audio-player/audio-player"
import type { AudioTrack } from "@/types"
import { Card, CardContent } from "@/components/ui/card"
import { ArrowLeft, Play, FileText, Download } from "lucide-react"

export default function LessonSection() {
  const [currentTrack, setCurrentTrack] = useState<AudioTrack | null>(null)
  const [showPlayer, setShowPlayer] = useState(false)

  const lessons = [
    {
      id: 101,
      title: "القواعد الأربع - الدرس الأول",
      date: "2023/09/10",
      type: "دروس علمية",
      category: "التوحيد",
    },
    {
      id: 102,
      title: "القواعد الأربع - الدرس الثاني",
      date: "2023/09/17",
      type: "دروس علمية",
      category: "التوحيد",
    },
    {
      id: 103,
      title: "القواعد الأربع - الدرس الثالث",
      date: "2023/09/24",
      type: "دروس علمية",
      category: "التوحيد",
    },
  ]

  // Sample audio tracks with internet URLs
  const audioTracks: { [key: number]: AudioTrack } = {
    101: {
      id: 101,
      title: "القواعد الأربع - الدرس الأول",
      artist: "الشيخ محمد",
      audioUrl: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3",
      duration: 286,
      thumbnailUrl: "/placeholder.svg",
      type: "lesson"
    },
    102: {
      id: 102,
      title: "القواعد الأربع - الدرس الثاني",
      artist: "الشيخ محمد",
      audioUrl: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3",
      duration: 315,
      thumbnailUrl: "/placeholder.svg",
      type: "lesson"
    },
    103: {
      id: 103,
      title: "القواعد الأربع - الدرس الثالث",
      artist: "الشيخ محمد",
      audioUrl: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3",
      duration: 330,
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
    <section className="py-8">
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        {/* Main Content */}
        <div className="md:col-span-3">
          <div className="bg-gray-900 text-white rounded-lg overflow-hidden">
            <div className="p-6 md:p-10">
              <div className="flex items-center justify-end mb-2 text-sm">
                <div className="flex items-center gap-1 text-gray-400">
                  <Calendar className="h-4 w-4" />
                  <span>2018/03/13</span>
                </div>
                <span className="mr-2 bg-emerald-700 px-2 py-0.5 rounded text-xs">دروس علمية</span>
              </div>

              <h1 className="text-2xl md:text-3xl font-bold mb-6 text-center">
                العقيدة الطحاوية 1 من بداية الكتاب - إلى قوله وَلا شَيْءَ مِثْلُهُ
              </h1>

              <p className="text-sm md:text-base leading-relaxed text-gray-300 text-right mb-8">
                البداية الربانية في شرح العقيدة الطحاوية عقيدة أهل السنة والجماعة بسم الله الرحمن الرحيم الحمد لله رب
                العالمين، والصلاة والسلام على أشرف الأنبياء والمرسلين، نبينا...
              </p>

              <div className="flex justify-between items-center">
                <div className="flex gap-2">
                  <Button variant="ghost" size="icon" className="h-8 w-8 text-gray-400 hover:text-white">
                    <Share2 className="h-4 w-4" />
                  </Button>
                  <Button variant="ghost" size="icon" className="h-8 w-8 text-gray-400 hover:text-white">
                    <Bookmark className="h-4 w-4" />
                  </Button>
                  <Button variant="ghost" size="icon" className="h-8 w-8 text-gray-400 hover:text-white">
                    <Copy className="h-4 w-4" />
                  </Button>
                </div>
                <Button className="bg-gray-700 hover:bg-gray-600 text-white">المزيد</Button>
              </div>
            </div>
          </div>
        </div>

        {/* Sidebar */}
        <div className="md:col-span-1">
          <div className="bg-white rounded-lg shadow p-4">
            <h2 className="text-xl font-bold mb-4 text-center">توحيد وعقيدة</h2>
            <div className="border-t pt-4">
              <nav className="space-y-2">
                <Link
                  href="#"
                  className="flex items-center justify-between p-2 text-sm hover:bg-gray-100 rounded text-emerald-700"
                >
                  <span>العقائد</span>
                </Link>
                <Link href="#" className="flex items-center justify-between p-2 text-sm hover:bg-gray-100 rounded">
                  <span>الألوهية والربوبية</span>
                </Link>
                <Link href="#" className="flex items-center justify-between p-2 text-sm hover:bg-gray-100 rounded">
                  <span>الأسماء والصفات</span>
                </Link>
                <Link href="#" className="flex items-center justify-between p-2 text-sm hover:bg-gray-100 rounded">
                  <span>مذاهب وفرق</span>
                </Link>
                <Link href="#" className="flex items-center justify-between p-2 text-sm hover:bg-gray-100 rounded">
                  <span>الإسلام والأديان</span>
                </Link>
                <Link href="#" className="flex items-center justify-between p-2 text-sm hover:bg-gray-100 rounded">
                  <span>الشبهات والبدع</span>
                </Link>
                <Link href="#" className="flex items-center justify-between p-2 text-sm hover:bg-gray-100 rounded">
                  <span>الشرك والكفر</span>
                </Link>
                <Link href="#" className="flex items-center justify-between p-2 text-sm hover:bg-gray-100 rounded">
                  <span>فضائل الصحابة</span>
                </Link>
                <Link href="#" className="flex items-center justify-between p-2 text-sm hover:bg-gray-100 rounded">
                  <span>القدر</span>
                </Link>
                <Link href="#" className="flex items-center justify-between p-2 text-sm hover:bg-gray-100 rounded">
                  <span>صفات المنافقين</span>
                </Link>
              </nav>
            </div>
          </div>
        </div>
      </div>

      <div className="flex justify-between items-center mb-6">
        <h2 className="text-2xl font-bold">الدروس المميزة</h2>
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
