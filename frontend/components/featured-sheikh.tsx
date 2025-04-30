import Image from "next/image"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { ExternalLink } from "lucide-react"

export default function FeaturedSheikh() {
  return (
    <Card className="border border-gray-100 shadow-sm">
      <CardHeader className="pb-2">
        <CardTitle className="text-xl">تعرف على الشيخ</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="flex flex-col items-center text-center">
          <div className="relative w-32 h-32 mb-4">
            <Image
              src="/placeholder.svg?height=128&width=128"
              alt="الشيخ"
              width={128}
              height={128}
              className="rounded-full border-4 border-emerald-100"
            />
          </div>
          <h3 className="text-xl font-semibold mb-2">الشيخ عبدالعزيز الراجحي</h3>
          <p className="text-sm text-gray-600 mb-4">
            عالم وداعية إسلامي، له العديد من المؤلفات والدروس العلمية في مختلف العلوم الشرعية. يتميز بأسلوبه السهل
            الميسر في شرح المسائل العلمية.
          </p>
          <Button className="bg-emerald-600 hover:bg-emerald-700 w-full">
            <ExternalLink className="h-4 w-4 ml-2" />
            السيرة الذاتية للشيخ
          </Button>
        </div>
      </CardContent>
    </Card>
  )
}
