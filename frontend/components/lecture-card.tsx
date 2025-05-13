"use client";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import {
    Calendar,
    Clock,
    Eye,
    Volume2,
    Play,
    Share2,
    BookmarkPlus,
} from "lucide-react";
import Link from "next/link";
import Image from "next/image";
import { formatDate, resourceUrl } from "@/lib/utils";
import { Badge } from "@/components/ui/badge";
import { Lecture } from "@/lib/services/lectures-service";
import { useAudioPlayer } from "@/context/AudioPlayerContext";
import { AudioTrack } from "@/types"

export const LectureCard = ({ lecture }: { lecture: Lecture }) => {
    const player = useAudioPlayer();
    const track: AudioTrack = {
        id: 0,
        title: lecture.title,
        audioUrl: resourceUrl(lecture.audio_url),
        thumbnailUrl: resourceUrl(lecture.thumbnail_url),
        duration: lecture.duration,
        type: "lecture",
        artist: "الشيخ عبد الله",
    }
    return (
        <Card className="border-gray-100 shadow-sm hover:shadow-md transition-shadow overflow-hidden">
            <CardContent className="p-0">
                <div className="grid grid-cols-1 md:grid-cols-[250px,1fr]">
                    <div className="relative h-48 md:h-full">
                        <Image
                            src={resourceUrl(lecture.thumbnail_url)}
                            alt={lecture.title}
                            fill
                            className="object-cover"
                        />
                        <div className="absolute inset-0 bg-gradient-to-t from-black/70 to-transparent flex items-center justify-center">
                            <Button
                                variant="outline"
                                size="sm"
                                onClick={() => player.setTrack(track)}
                                className="rounded-full bg-white/20 border-white/40 text-white hover:bg-white/30 hover:text-white"
                            >
                                <Play className="size-4" />
                                <span>استماع</span>
                            </Button>
                        </div>
                        <div className="absolute top-2 right-2">
                            <Badge>{lecture.category}</Badge>
                        </div>
                    </div>
                    <div className="p-5">
                        <div className="flex justify-between items-start mb-3">
                            <div className="flex items-center text-xs text-gray-500 gap-1">
                                <Calendar className="size-3" />
                                <span>{formatDate(lecture.published_date)}</span>
                            </div>
                        </div>
                        <Link href={`/lectures/${lecture.id}`} className="block">
                            <h3 className="text-xl font-semibold mb-2 hover:underline transition-colors">
                                {lecture.title}
                            </h3>
                        </Link>
                        <p className="text-sm text-gray-600 mb-4 line-clamp-2">
                            {lecture.description}
                        </p>
                        <div className="flex flex-wrap gap-4 mb-4">
                            <div className="flex items-center text-xs text-gray-500 gap-1">
                                <Clock className="size-3" />
                                <span>{lecture.duration} دقيقة</span>
                            </div>
                            <div className="flex items-center text-xs text-gray-500 gap-1">
                                <Volume2 className="size-3" />
                                <span>صوت فقط</span>
                            </div>
                            <div className="flex items-center text-xs text-gray-500 gap-1">
                                <Eye className="size-3" />
                                <span>{lecture.views.toLocaleString()} مشاهدة</span>
                            </div>
                        </div>
                        <div className="flex items-center justify-between">
                            <Button variant="link" className="p-0 h-auto " asChild>
                                <Link href={`/lectures/${lecture.id}`}>
                                    عرض التفاصيل
                                </Link>
                            </Button>
                            <div className="flex space-x-2 space-x-reverse">
                                <Button
                                    variant="ghost"
                                    size="sm"
                                >
                                    <BookmarkPlus className="size-4" />
                                </Button>
                                <Button
                                    variant="ghost"
                                    size="sm"
                                >
                                    <Share2 className="size-4" />
                                </Button>
                            </div>
                        </div>
                    </div>
                </div>
            </CardContent>
        </Card>
    );
};