"use client"

import { Button } from "@/components/ui/button"
import { Play } from "lucide-react"
import { useAudioPlayer } from "@/context/AudioPlayerContext"
import { AudioTrack } from "@/types"

interface AudioPlayerButtonProps {
  track: AudioTrack
  variant?: "default" | "outline" | "secondary" | "ghost" | "destructive" | "link" | null
  size?: "default" | "sm" | "lg" | "icon" | null
  className?: string,
  isGhost?: boolean
}

export default function AudioPlayerButton({
  track,
  variant = "default",
  size = "default",
  className = "",
  isGhost = false
}: AudioPlayerButtonProps) {
  const { setTrack } = useAudioPlayer()

  const handlePlayClick = () => {
    console.log("Playing track:", track);
    
    setTrack(track)
  }

  return (
    <Button
      onClick={handlePlayClick}
      variant={variant || "default"}
      size={size || "default"}
      className={className}
    >
      <Play className="h-5 w-5" />
      {isGhost ? "استمع الآن" : <span className="sr-only">استمع</span>}    
    </Button>
  )
}
