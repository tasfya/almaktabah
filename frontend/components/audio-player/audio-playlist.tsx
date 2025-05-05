"use client"

import type { AudioTrack, PlaylistItem } from "@/types"
import { formatTime } from "@/lib/utils"
import { Play } from "lucide-react"
import Image from "next/image"

interface AudioPlaylistProps {
  playlist: PlaylistItem[]
  currentTrackId: number
  onSelectTrack: (track: AudioTrack) => void
}

export default function AudioPlaylist({ playlist, currentTrackId, onSelectTrack }: AudioPlaylistProps) {
  return (
    <div className="bg-white border-t border-gray-200 max-h-64 overflow-y-auto">
      <div className="container mx-auto px-4 py-2">
        <h3 className="text-sm font-medium mb-2">قائمة التشغيل ({playlist.length})</h3>
        <ul className="space-y-1">
          {playlist.map((item) => (
            <li
              key={item.id}
              className={`flex items-center p-2 rounded-md cursor-pointer ${
                item.id === currentTrackId ? "bg-emerald-50" : "hover:bg-gray-50"
              }`}
              onClick={() => onSelectTrack(item)}
            >
              <div className="relative h-10 w-10 rounded overflow-hidden mr-3">
                <Image
                  src={item.thumbnailUrl || "/placeholder.svg?height=40&width=40"}
                  alt={item.title}
                  fill
                  className="object-cover"
                />
                {item.id === currentTrackId && (
                  <div className="absolute inset-0 flex items-center justify-center bg-black/30">
                    <Play className="h-4 w-4 text-white" />
                  </div>
                )}
              </div>
              <div className="flex-1 min-w-0">
                <h4 className="text-sm font-medium truncate">{item.title}</h4>
                <p className="text-xs text-gray-500 truncate">{item.artist}</p>
              </div>
              <div className="flex items-center">
                {item.progress > 0 && item.progress < 100 && (
                  <div className="w-16 h-1 bg-gray-200 rounded-full mr-2">
                    <div className="h-full bg-emerald-600 rounded-full" style={{ width: `${item.progress}%` }} />
                  </div>
                )}
                <span className="text-xs text-gray-500">{formatTime(item.duration)}</span>
              </div>
            </li>
          ))}
        </ul>
      </div>
    </div>
  )
}
