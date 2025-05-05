import Image from "next/image"
import { Card, CardContent, CardHeader, CardTitle, CardFooter } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { ExternalLink, Mail, BookOpen, Download } from "lucide-react"
import Link from "next/link"
import SocialLinks from "./social-links"

export default function PageSidebar() {
  return (
    <div className="space-y-6">
      {/* Sheikh Info Card */}
      <Card className="border border-gray-100 shadow-sm overflow-hidden">
        <CardContent className="pt-4">
          <div className="flex flex-col items-center text-center">
            <div className="relative mb-4">
              <Image
                src="/logo.png?height=300&width=300"
                alt="الشيخ"
                width={300}
                height={300}
                className="rounded-full"
              />
            </div>
            <div className="flex gap-2 w-full justify-center">
              <Button asChild>
                <Link href="/about">
                  <span className="flex items-center justify-center gap-1">
                    <ExternalLink className="h-3.5 w-3.5 ml-1" />
                    عن الشيخ
                  </span>
                </Link>
              </Button>
              <Button variant="outline" asChild>
                <Link href="/about">
                  <span className="flex items-center justify-center gap-1">
                    <Mail className="h-3.5 w-3.5 ml-1" />
                    تواصل
                  </span>
                </Link>
              </Button>
            </div>
          </div>
        </CardContent>
        <CardFooter className="flex justify-center py-2">
          <SocialLinks />
        </CardFooter>
      </Card>

      {/* Most Downloaded Books */}
      <Card className="border border-gray-100 shadow-sm">
        <CardHeader className="pb-2">
          <CardTitle className="text-lg text-primary">الكتب الأكثر تحميلاً</CardTitle>
        </CardHeader>
        <CardContent className="pt-4">
          <div className="space-y-3">
            {[1, 2, 3].map((item) => (
              <div key={`download-${item}`} className="flex items-center gap-3 pb-3 border-b border-gray-100 last:border-0 last:pb-0">
                <div className="relative w-14 h-20 flex-shrink-0">
                  <Image
                    src="/placeholder.svg?height=80&width=56"
                    alt={`كتاب ${item}`}
                    width={56}
                    height={80}
                    className="object-cover"
                  />
                </div>
                <div className="flex-1">
                  <h4 className="font-medium text-sm mb-1 line-clamp-1">شرح كتاب التوحيد - الجزء {item}</h4>
                  <div className="flex items-center text-xs text-gray-500 mb-2 gap-1">
                    <Download className="h-3 w-3 ml-1" />
                    <span>4.{item}K تحميل</span>
                  </div>
                  <Button variant='outline' size="sm">
                    <Download className="h-3 w-3 ml-1" />
                    تحميل
                  </Button>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Most Visited Content */}
      <Card className="border border-gray-100 shadow-sm">
        <CardHeader className="pb-2">
          <CardTitle className="text-lg text-primary">المحتوى الأكثر زيارة</CardTitle>
        </CardHeader>
        <CardContent className="pt-4">
          <div className="space-y-3">
            {[1, 2, 3].map((item) => (
              <div key={`visit-${item}`} className="flex gap-3 pb-3 border-b border-gray-100 last:border-0 last:pb-0">
                <div className="bg-primary text-white h-6 w-6 rounded-full flex items-center justify-center flex-shrink-0 font-medium text-sm">
                  {item}
                </div>
                <div className="flex-1">
                  <h4 className="font-medium text-sm mb-1 line-clamp-2">
                    {item === 1 ? "شرح حديث إنما الأعمال بالنيات" : 
                     item === 2 ? "فضل العلم الشرعي وطلبه" : 
                     "أحكام الصيام في رمضان"}
                  </h4>
                  <div className="flex items-center text-xs text-gray-500 gap-1">
                    <BookOpen className="h-3 w-3 ml-1" />
                    <span>{item + 6}K مشاهدة</span>
                  </div>
                </div>
              </div>
            ))}
            <Button className="mx-auto">
              عرض المزيد
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}