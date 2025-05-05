import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Play, Calendar, Clock } from "lucide-react";
import { formatDuration, formatDate, resourceUrl } from "@/lib/utils";
import Image from "next/image";
import { AudioTrack, } from "@/types";
import FeaturedSheikh from "@/components/featured-sheikh";
import UpcomingEvents from "@/components/upcoming-events";
import { getLessonById } from "@/lib/services/lessons-service";

import { Breadcrumb, BreadcrumbItem, BreadcrumbLink, BreadcrumbList, BreadcrumbSeparator } from "@/components/ui/breadcrumb";
import PageSidebar from "@/components/page-sidebar";
import AudioPlayerButton from "@/components/audio-player/audio-player-button";

export default async function LessonPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;

  const lesson  = await getLessonById(id);

  if (!lesson) {
    return <div className="container mx-auto px-4 py-8">الدرس غير موجود</div>;
  }
  const audioTrack: AudioTrack = {
    id: Number(lesson.id),
    title: lesson.title,
    artist: "الشيخ عبد الله",
    audioUrl: resourceUrl(lesson.audio_url),
    duration: lesson.duration || 300,
    thumbnailUrl: resourceUrl(lesson.thumbnail_url),
    type: "lesson"
  };
  return (
    <div className="container mx-auto px-4 py-8">
      <div className="mb-6">
      <Breadcrumb className="mb-4">
          <BreadcrumbList>
            <BreadcrumbItem>
              <BreadcrumbLink href="/">الرئيسية</BreadcrumbLink>
            </BreadcrumbItem>
            <BreadcrumbSeparator />
            <BreadcrumbItem>
              <BreadcrumbLink href="/lessons">الدروس العلمية</BreadcrumbLink>
            </BreadcrumbItem>
            <BreadcrumbSeparator />
            <BreadcrumbItem>
              <BreadcrumbLink href={`/lessons/${lesson.id}`}>{lesson.title}</BreadcrumbLink>
            </BreadcrumbItem>
          </BreadcrumbList>
        </Breadcrumb>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
        <div className="md:col-span-2">
          <Card className="overflow-hidden border-0 shadow-md">
            <div className="relative h-48 md:h-64 bg-gray-900">
              <Image
                src={resourceUrl(lesson.thumbnail_url)}
                alt={lesson.title}
                fill
                className="object-cover opacity-70"
              />
              <div className="absolute inset-0 flex items-center justify-center">
                <AudioPlayerButton track={audioTrack} />
              </div>
            </div>

            <CardContent className="p-6">
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center gap-2">
                  <span className="bg-emerald-100 text-emerald-800 px-2 py-0.5 rounded text-xs">درس علمي</span>
                <span className="bg-gray-100 text-gray-800 px-2 py-0.5 rounded text-xs">{lesson.category}</span>
                </div>
              </div>

              <h1 className="text-2xl md:text-3xl font-bold mb-4">{lesson.title}</h1>

              <div className="flex flex-wrap items-center gap-4 mb-6 text-sm text-gray-600">
                <div className="flex items-center">
                  <Calendar className="h-4 w-4 ml-1" />
                  <span>{formatDate(lesson.published_date)}</span>
                </div>
                <div className="flex items-center">
                  <Clock className="h-4 w-4 ml-1" />
                  <span>{formatDuration(lesson.duration || 0)}</span>
                </div>
              </div>

              <div className="prose max-w-none">
                <p className="text-gray-700 leading-relaxed">{lesson.description}</p>
                {lesson.content && (
                  <div className="mt-4 max-h-[600px] overflow-y-auto pr-2 scrollbar-thin scrollbar-thumb-gray-300 scrollbar-track-gray-100" 
                       dangerouslySetInnerHTML={{ __html: lesson.content.body }} />
                )}
              </div>

              <div className="mt-8 flex flex-wrap gap-4">
                {lesson.audio_url && (
                  <Button variant="outline">تحميل الدرس</Button>
                )}
              </div>
            </CardContent>
          </Card>
        </div>

        <div className="md:col-span-1">
          <PageSidebar/>
        </div>
      </div>
    </div>
  );
}
