import Image from "next/image"
import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { ArrowLeft, ArrowRight, Book } from "lucide-react"
import Link from "next/link"

export default function BooksSection() {
  const books = [
    {
      id: 1,
      title: "السبيل المحني للمسلم من الفتن",
      image: "/placeholder.svg?height=300&width=200",
      pages: 53,
      year: 1437,
      type: "الأولى",
      description: "توضيح في بيان السبيل الذي ينجي من الفتن",
    },
    {
      id: 2,
      title: "القول البين الأظهر",
      image: "/placeholder.svg?height=300&width=200",
      pages: 196,
      year: 1437,
      type: "الثانية",
      description: "القول البين الأظهر في الدعوة إلى الله والأمر بالمعروف والنهي عن المنكر",
    },
    {
      id: 3,
      title: "توضيح البر المنعم بشرح صحيح الإمام مسلم 3",
      image: "/placeholder.svg?height=300&width=200",
      pages: 5111,
      volumes: 9,
      year: 1439,
      type: "الأولى",
      description: "متوسط الحجم، شامل لجميع أحاديث الصحيح بميزة التعقب",
    },
    {
      id: 4,
      title: "شرح كتاب التوحيد",
      image: "/placeholder.svg?height=300&width=200",
      pages: 320,
      year: 1440,
      type: "الثالثة",
      description: "شرح مفصل لكتاب التوحيد للإمام محمد بن عبد الوهاب",
    },
  ]

  return (
    <section>
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-2xl font-bold">كتب الشيخ</h2>
        <div className="flex items-center gap-2">
          <Button variant="outline" size="icon" className="h-8 w-8 rounded-md">
            <ArrowRight className="h-4 w-4" />
          </Button>
          <Button variant="outline" size="icon" className="h-8 w-8 rounded-md">
            <ArrowLeft className="h-4 w-4" />
          </Button>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {books.map((book) => (
          <Card
            key={book.id}
            className="overflow-hidden border border-gray-100 shadow-sm hover:shadow-md transition-shadow"
          >
            <CardContent className="p-0">
              <div className="flex flex-col">
                <div className="relative h-48 bg-gradient-to-b from-emerald-50 to-white flex items-center justify-center">
                  <Image
                    src={book.image || "/placeholder.svg"}
                    alt={book.title}
                    width={120}
                    height={180}
                    className="h-40 w-auto object-cover shadow-md"
                  />
                </div>
                <div className="p-4">
                  <div className="flex items-center gap-2 mb-2">
                    <div className="flex items-center justify-center w-8 h-8 rounded-full bg-emerald-50 text-emerald-600">
                      <Book className="h-4 w-4" />
                    </div>
                    <span className="text-xs text-gray-500">{book.year} هـ</span>
                  </div>
                  <h3 className="text-lg font-semibold mb-3 line-clamp-1">{book.title}</h3>
                  <div className="text-sm text-gray-600 space-y-1 mb-4">
                    <p className="flex justify-between">
                      <span>عدد الصفحات:</span>
                      <span className="font-medium">{book.pages}</span>
                    </p>
                    {book.volumes && (
                      <p className="flex justify-between">
                        <span>عدد المجلدات:</span>
                        <span className="font-medium">{book.volumes}</span>
                      </p>
                    )}
                    <p className="flex justify-between">
                      <span>رقم الطبعة:</span>
                      <span className="font-medium">{book.type}</span>
                    </p>
                  </div>
                  <Link href={`/book/${book.id}`}>
                    <Button className="w-full bg-emerald-600 hover:bg-emerald-700">قراءة الكتاب</Button>
                  </Link>
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="flex justify-center mt-8">
        <Button variant="outline" className="bg-emerald-600 text-white hover:bg-emerald-700">
          عرض المزيد من الكتب
        </Button>
      </div>
    </section>
  )
}
