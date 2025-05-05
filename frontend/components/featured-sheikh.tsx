import Image from "next/image"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { ExternalLink, Link } from "lucide-react"

export default function FeaturedSheikh() {
  return (
    <Card className="border border-gray-100 shadow-sm">
      <CardHeader className="pb-2">
      </CardHeader>
      <CardContent>
        <div className="flex flex-col items-center text-center">
          <div className="relative mb-4">
            <Image
              src="/logo.png"
              alt="الشيخ"
              width={300}
              height={300}
              className="rounded-full"
            />
          </div>
          <p className="text-sm text-gray-600 mb-4">
            عالم وداعية إسلامي، له العديد من المؤلفات والدروس العلمية في مختلف العلوم الشرعية. يتميز بأسلوبه السهل
            الميسر في شرح المسائل العلمية.
          </p>
          <Link href="/about">
            <Button>
              <ExternalLink className="h-4 w-4 ml-2" />
              <span>السيرة الذاتية للشيخ</span>
            </Button>
          </Link>
        </div>
      </CardContent>
    </Card>
  )
}
