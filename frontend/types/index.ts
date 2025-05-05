
export interface AudioTrack {
  id: number
  title: string
  artist: string
  audioUrl: string
  duration: number
  thumbnailUrl: string
  type: "lesson" | "fatwa" | "sermon" | "lecture"
}

export interface PlaylistItem extends AudioTrack {
  progress: number // 0-100
}

export interface UserPreferences {
  playbackSpeed: number
  autoplay: boolean
  theme: "light" | "dark"
  language: "ar"
  notifications: boolean
  showCompletedContent: boolean
}

export type Article = {
  id: number
  title: string
  content: string
}

export type User = {
  id: number
  name: string
  email: string
  password: string
}


export type Fatwa = {}
export type Sermon = {}
export type Lecture = {}
export type Scholar = {}