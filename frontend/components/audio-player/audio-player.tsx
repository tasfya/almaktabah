"use client"

import { useState, useEffect, useRef } from "react"
import { Button } from "@/components/ui/button"
import { Slider } from "@/components/ui/slider"
import {
  Play,
  Pause,
  Volume2,
  VolumeX,
  Repeat,
  X,
  Bookmark,
  BookmarkCheck,
  Minimize2,
  Maximize2
} from "lucide-react"
import { formatTime } from "@/lib/utils"
import type { AudioTrack } from "@/types"
import Image from "next/image"
import AudioSpeedControl from "./audio-speed-control"

interface AudioPlayerProps {
  track?: AudioTrack
  onClose?: () => void
  autoplay?: boolean
}

export default function AudioPlayer({
  track,
  onClose,
  autoplay = false,
}: AudioPlayerProps) {
  // Player state
  const [isPlaying, setIsPlaying] = useState(false)
  const [currentTime, setCurrentTime] = useState(0)
  const [duration, setDuration] = useState(0)
  const [volume, setVolume] = useState(0.8)
  const [isMuted, setIsMuted] = useState(false)
  const [isRepeat, setIsRepeat] = useState(false)
  const [playbackSpeed, setPlaybackSpeed] = useState(1)
  const [isBookmarked, setIsBookmarked] = useState(false)
  const [isMinimized, setIsMinimized] = useState(false)
  
  // Refs
  const audioRef = useRef<HTMLAudioElement | null>(null)
  const intervalRef = useRef<NodeJS.Timeout | null>(null)
  
  // Setup audio element when component mounts
  useEffect(() => {
    const audio = new Audio(track?.audioUrl || "")
    audioRef.current = audio
    
    // Set initial audio properties
    audio.volume = volume
    audio.loop = isRepeat
    
    // Setup event listeners
    audio.addEventListener("loadedmetadata", () => {
      setDuration(audio.duration)
      if (autoplay) {
        handlePlay()
      }
    })
    
    audio.addEventListener("timeupdate", () => {
      setCurrentTime(audio.currentTime)
    })
    
    audio.addEventListener("ended", () => {
      if (!isRepeat) {
        setIsPlaying(false)
      }
    })
    
    // Cleanup on unmount
    return () => {
      clearInterval(intervalRef.current as NodeJS.Timeout)
      audio.pause()
      audio.src = ""
      audio.removeAttribute("src")
      audioRef.current = null
    }
  }, [track, autoplay])
  
  // Update audio properties when state changes
  useEffect(() => {
    const audio = audioRef.current
    if (!audio) return
    
    audio.volume = isMuted ? 0 : volume
  }, [volume, isMuted])
  
  useEffect(() => {
    const audio = audioRef.current
    if (!audio) return
    
    audio.playbackRate = playbackSpeed
  }, [playbackSpeed])
  
  useEffect(() => {
    const audio = audioRef.current
    if (!audio) return
    
    audio.loop = isRepeat
  }, [isRepeat])
  
  // Progress tracking interval for lesson progress
  useEffect(() => {
    if (isPlaying && track?.type === "lesson") {
      intervalRef.current = setInterval(() => {
        const audio = audioRef.current
        if (!audio) return
        
        const progress = Math.round((audio.currentTime / audio.duration) * 100)
        // TODO: Update lesson progress in the database
      }, 1000)
    }
    
    return () => {
      if (intervalRef.current) {
        clearInterval(intervalRef.current)
      }
    }
  }, [isPlaying, track, isBookmarked])
  
  // Handle play/pause safely
  const handlePlay = () => {
    const audio = audioRef.current
    if (!audio) return
    
    audio.play()
      .then(() => {
        setIsPlaying(true)
      })
      .catch(error => {
        console.error("Playback failed:", error)
      })
  }
  
  const handlePause = () => {
    const audio = audioRef.current
    if (!audio) return
    
    audio.pause()
    setIsPlaying(false)
  }
  
  const togglePlay = () => {
    if (isPlaying) {
      handlePause()
    } else {
      handlePlay()
    }
  }
  
  const toggleMute = () => {
    setIsMuted(!isMuted)
  }
  
  const toggleRepeat = () => {
    setIsRepeat(!isRepeat)
  }
  
  const toggleMinimize = () => {
    setIsMinimized(!isMinimized)
  }
  
  const toggleBookmark = () => {
    setIsBookmarked(!isBookmarked)
    
    if (track?.type === "lesson") {
      // throw new Error(`Bookmark toggled for lesson: ${track.title}`)
      // TODO: Handle bookmarking logic
    }
  }
  
  const handleSeek = (value: number[]) => {
    const audio = audioRef.current
    if (!audio) return
    
    const newTime = value[0]
    audio.currentTime = newTime
    setCurrentTime(newTime)
  }
  
  const handleVolumeChange = (value: number[]) => {
    const newVolume = value[0]
    setVolume(newVolume)
    
    if (newVolume > 0 && isMuted) {
      setIsMuted(false)
    }
  }
  
  const handleClose = () => {
    // Pause audio before closing
    const audio = audioRef.current
    if (audio) {
      audio.pause()
    }
    
    // Call the onClose callback if provided
    if (onClose) {
      onClose()
    }
  }
  
  if (!track) return null
  
  // Minimized player view
  if (isMinimized) {
    return (
      <div className="fixed bottom-0 right-0 bg-white border-t border-l border-gray-200 shadow-lg z-50 rounded-tl-lg">
        <div className="flex flex-col p-2 w-[280px]">
          <div className="flex items-center mb-1">
            <div className="relative h-8 w-8 rounded overflow-hidden mr-2">
              <Image
                src={track.thumbnailUrl || "/placeholder.svg?height=32&width=32"}
                alt={track.title}
                fill
                className="object-cover"
              />
            </div>
            
            <div className="flex-1 min-w-0 max-w-[140px] mx-2">
              <h4 className="text-xs font-medium truncate">{track.title}</h4>
            </div>
            
            <Button
              variant="ghost"
              size="icon"
              className="h-7 w-7 text-gray-500"
              onClick={togglePlay}
            >
              {isPlaying ? <Pause className="h-4 w-4" /> : <Play className="h-4 w-4" />}
            </Button>
            
            <Button
              variant="ghost"
              size="icon"
              className="h-7 w-7 text-gray-500"
              onClick={toggleMinimize}
            >
              <Maximize2 className="h-4 w-4" />
            </Button>
            
            <Button
              variant="ghost"
              size="icon"
              className="h-7 w-7 text-gray-500"
              onClick={handleClose}
            >
              <X className="h-4 w-4" />
            </Button>
          </div>
          
          {/* Progress bar for minimized view */}
          <div className="flex items-center space-x-2 gap-1 px-1">
            <span className="text-[10px] text-gray-500 w-6 text-right">{formatTime(currentTime)}</span>
            <div className="relative flex-1 h-1 bg-gray-200 rounded-full">
              <div 
                className="absolute h-full  rounded-full" 
                style={{ width: `${duration ? (currentTime / duration) * 100 : 0}%` }}
              />
            </div>
            <span className="text-[10px] text-gray-500 w-6">{formatTime(duration)}</span>
          </div>
        </div>
      </div>
    )
  }
  
  // Full player view
  return (
    <div className="fixed bottom-0 left-0 right-0 bg-white border-t border-gray-200 shadow-lg z-50">
      <div className="container mx-auto px-4 py-3">
        <div className="flex flex-col md:flex-row items-center">
          {/* Track Info */}
          <div className="flex items-center w-full md:w-1/4 mb-3 md:mb-0">
            <div className="relative h-12 w-12 rounded-md overflow-hidden mr-3">
              <Image
                src={track.thumbnailUrl || "/placeholder.svg?height=48&width=48"}
                alt={track.title}
                fill
                className="object-cover"
              />
            </div>
            <div className="flex-1 min-w-0">
              <h4 className="text-sm font-medium truncate">{track.title}</h4>
              <p className="text-xs text-gray-500 truncate">{track.artist}</p>
            </div>
            <Button
              variant="outline"
              size="icon"
              onClick={toggleBookmark}
            >
              {isBookmarked ? <BookmarkCheck className="h-5 w-5 text-primary" /> : <Bookmark className="h-5 w-5" />}
            </Button>
          </div>

          {/* Player Controls */}
          <div className="flex flex-col w-full md:w-2/4 px-0 md:px-4">
            <div className="flex items-center justify-center space-x-4 mb-2">
              <Button
                variant="ghost"
                size="icon"
                onClick={togglePlay}
              >
                {isPlaying ? <Pause className="h-5 w-5" /> : <Play className="h-5 w-5" />}
              </Button>

              <Button
                variant="ghost"
                size="icon"
                className={`h-8 w-8 ${isRepeat ? "text-primary" : "text-gray-500"}`}
                onClick={toggleRepeat}
              >
                <Repeat className="h-4 w-4" />
              </Button>
            </div>

            <div className="flex items-center space-x-2">
              <span className="text-xs text-gray-500 w-10 text-right">{formatTime(currentTime)}</span>

              <Slider
                value={[currentTime]}
                min={0}
                max={duration || 100}
                step={1}
                onValueChange={handleSeek}
                className="flex-1"
              />

              <span className="text-xs text-gray-500 w-10">{formatTime(duration)}</span>
            </div>
          </div>

          {/* Additional Controls */}
          <div className="flex items-center justify-end w-full md:w-1/4 mt-3 md:mt-0">
            <div className="flex items-center space-x-2 mr-2">
              <Button variant="ghost" size="icon" className="h-8 w-8 text-gray-500" onClick={toggleMute}>
                {isMuted ? <VolumeX className="h-4 w-4" /> : <Volume2 className="h-4 w-4" />}
              </Button>

              <Slider
                value={[isMuted ? 0 : volume]}
                min={0}
                max={1}
                step={0.01}
                onValueChange={handleVolumeChange}
                className="w-20"
              />
            </div>

            <AudioSpeedControl speed={playbackSpeed} onSpeedChange={setPlaybackSpeed} />
            
            <Button
              variant="ghost"
              size="icon"
              className="h-8 w-8 text-gray-500"
              onClick={toggleMinimize}
              title="Minimize player"
            >
              <Minimize2 className="h-4 w-4" />
            </Button>

            <Button 
              variant="ghost" 
              size="icon" 
              className="h-8 w-8 text-gray-500"
              onClick={handleClose}
              title="Close player"
            >
              <X className="h-4 w-4" />
            </Button>
          </div>
        </div>
      </div>
    </div>
  )
}
