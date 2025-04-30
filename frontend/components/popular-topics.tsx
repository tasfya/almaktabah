import Link from "next/link"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { ChevronLeft } from "lucide-react"

export default function PopularTopics() {
  const topics = [
    { id: 1, title: "العقيدة الصحيحة", count: 120 },
    { id: 2, title: "فقه العبادات", count: 95 },
    { id: 3, title: "أحكام الصلاة", count: 87 },
    { id: 4, title: "فقه المعاملات", count: 76 },
    { id: 5, title: "أحكام الزكاة", count: 68 },
    { id: 6, title: "أحكام الصيام", count: 64 },
    { id: 7, title: "أحكام الحج والعمرة", count: 59 },
    { id: 8, title: "الأخلاق والآداب", count: 52 },
    { id: 9, title: "فقه الأسرة", count: 48 },
    { id: 10, title: "التفسير", count: 43 },
  ]

  return (
    <Card className="border border-gray-100 shadow-sm">
      <CardHeader className="pb-2">
        <CardTitle className="text-xl">المواضيع الشائعة</CardTitle>
      </CardHeader>
      <CardContent>
        <ul className="space-y-1">
          {topics.map((topic) => (
            <li key={topic.id}>
              <Link
                href={`/topic/${topic.id}`}
                className="flex items-center justify-between py-2 px-2 rounded-md hover:bg-emerald-50 transition-colors"
              >
                <span className="font-medium">{topic.title}</span>
                <div className="flex items-center">
                  <span className="text-sm text-gray-500 ml-2">{topic.count}</span>
                  <ChevronLeft className="h-4 w-4 text-emerald-600" />
                </div>
              </Link>
            </li>
          ))}
        </ul>
      </CardContent>
    </Card>
  )
}
