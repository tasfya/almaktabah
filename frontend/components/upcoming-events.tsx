import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Calendar, Clock, MapPin } from "lucide-react"
import Link from "next/link"

export default function UpcomingEvents() {
  const events = [
    {
      id: 1,
      title: "درس في شرح صحيح البخاري",
      date: "2023/10/15",
      time: "بعد صلاة العشاء",
      location: "المسجد الكبير",
    },
    {
      id: 2,
      title: "محاضرة عن فضل العلم وآداب طالب العلم",
      date: "2023/10/18",
      time: "بعد صلاة المغرب",
      location: "قاعة المحاضرات الرئيسية",
    },
    {
      id: 3,
      title: "درس في شرح كتاب التوحيد",
      date: "2023/10/20",
      time: "بعد صلاة العصر",
      location: "المسجد الكبير",
    },
    {
      id: 4,
      title: "لقاء مفتوح مع الشيخ",
      date: "2023/10/25",
      time: "بعد صلاة العشاء",
      location: "المركز الثقافي الإسلامي",
    },
  ]

  return (
    <Card className="border border-gray-100 shadow-sm">
      <CardHeader className="pb-2">
        <CardTitle className="text-xl">الفعاليات القادمة</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="flex flex-col gap-3">
          {events.map((event) => (
            <Link key={event.id} href={`/event/${event.id}`}>
              <div className="p-3 rounded-md border border-gray-100 hover:bg-gray-50 transition-colors">
                <h3 className="font-medium mb-2">{event.title}</h3>
                <div className="flex flex-wrap text-sm text-gray-600 gap-x-4 gap-y-1">
                  <div className="flex items-center gap-1">
                    <Calendar className="h-4 w-4 ml-1 text-primary" />
                    <span>{event.date}</span>
                  </div>
                  <div className="flex items-center gap-1">
                    <Clock className="h-4 w-4 ml-1 text-primary" />
                    <span>{event.time}</span>
                  </div>
                  <div className="flex items-center gap-1">
                    <MapPin className="h-4 w-4 ml-1 text-primary" />
                    <span>{event.location}</span>
                  </div>
                </div>
              </div>
            </Link>
          ))}
        </div>
      </CardContent>
    </Card>
  )
}
