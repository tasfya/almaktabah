"use client"
import { Button } from "@/components/ui/button"
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu"
import { Clock } from "lucide-react"

interface AudioSpeedControlProps {
  speed: number
  onSpeedChange: (speed: number) => void
}

export default function AudioSpeedControl({ speed, onSpeedChange }: AudioSpeedControlProps) {
  const speeds = [0.5, 0.75, 1, 1.25, 1.5, 1.75, 2]

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="ghost" size="sm" className="h-8 px-2 text-xs text-gray-500">
          <Clock className="h-3 w-3 mr-1" />
          {speed}x
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end">
        {speeds.map((value) => (
          <DropdownMenuItem
            key={value}
            className={speed === value ? "bg-emerald-50 text-emerald-600" : ""}
            onClick={() => onSpeedChange(value)}
          >
            {value}x
          </DropdownMenuItem>
        ))}
      </DropdownMenuContent>
    </DropdownMenu>
  )
}
