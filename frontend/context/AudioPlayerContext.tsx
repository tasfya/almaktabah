"use client"

import { createContext, useState, useContext, ReactNode } from "react"
import { AudioTrack } from "@/types"
import AudioPlayer from "@/components/audio-player/audio-player"

interface AudioPlayerContextType {
  track: AudioTrack | null
  setTrack: (track: AudioTrack) => void
  clearTrack: () => void
  isPlaying: boolean
  setIsPlaying: (isPlaying: boolean) => void
}

const AudioPlayerContext = createContext<AudioPlayerContextType | undefined>(undefined)

export const AudioPlayerProvider = ({ children }: { children: ReactNode }) => {
  const [track, setTrackState] = useState<AudioTrack | null>(null)
  const [isPlaying, setIsPlaying] = useState(false)

  const setTrack = (newTrack: AudioTrack) => {
    setTrackState(newTrack)
  }

  const clearTrack = () => {
    setTrackState(null)
    setIsPlaying(false)
  }

  return (
    <AudioPlayerContext.Provider 
      value={{ 
        track, 
        setTrack, 
        clearTrack,
        isPlaying,
        setIsPlaying
      }}
    >
      {children}
      {track && (
        <AudioPlayer
          track={track}
          autoplay={true}
          onClose={clearTrack}
        />
      )}
    </AudioPlayerContext.Provider>
  )
}

export const useAudioPlayer = () => {
  const context = useContext(AudioPlayerContext)
  
  if (context === undefined) {
    throw new Error("useAudioPlayer must be used within an AudioPlayerProvider")
  }
  
  return context
}