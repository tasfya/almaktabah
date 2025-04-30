import type React from "react"
import Link from "next/link"
import { cn } from "@/lib/utils"
import { ChevronLeft } from "lucide-react"

interface SidebarNavProps extends React.HTMLAttributes<HTMLElement> {
  items: {
    href: string
    title: string
  }[]
}

export default function SidebarNav({ className, items, ...props }: SidebarNavProps) {
  return (
    <nav className={cn("flex flex-col space-y-1", className)} {...props}>
      {items.map((item) => (
        <Link
          key={item.href}
          href={item.href}
          className="flex items-center justify-between p-2 text-sm font-medium rounded-md hover:bg-gray-100"
        >
          {item.title}
          <ChevronLeft className="h-4 w-4" />
        </Link>
      ))}
    </nav>
  )
}
