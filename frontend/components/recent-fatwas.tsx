import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { ArrowLeft, MessageCircle } from "lucide-react"
import Link from "next/link"

export default function RecentFatwas() {
  const fatwas = [
    {
      id: 1,
      title: "حكمة خلق الله الكافر مع علمه سبحانه أنه من أهل النار",
      date: "2023/02/10",
      category: "العقيدة",
    },
    {
      id: 2,
      title: 'ماذا علي من قال " علي الحرام أن أفعل كذا "',
      date: "2023/01/25",
      category: "الفقه",
    },
    {
      id: 3,
      title: "اقتصاص الكافر يوم القيامة من المسلم الذي ظلمه",
      date: "2023/03/05",
      category: "العقيدة",
    },
    {
      id: 4,
      title: "هل يمكن غسل الجمعة عن الوضوء",
      date: "2023/03/20",
      category: "الفقه",
    },
    {
      id: 5,
      title: "حكم دفع الزكاة لشراء سيارة",
      date: "2023/04/15",
      category: "الفقه",
    },
    {
      id: 6,
      title: "حكم الصلاة خلف إمام يرتكب بعض المعاصي",
      date: "2023/05/05",
      category: "الفقه",
    },
  ]

  return (
    <section>
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-2xl font-bold">أحدث الفتاوى</h2>
        <Button variant="ghost" className="text-emerald-600 hover:text-emerald-700">
          عرض الكل <ArrowLeft className="h-4 w-4 mr-1" />
        </Button>
      </div>

      <div className="grid grid-cols-1 gap-4">
        {fatwas.slice(0, 6).map((fatwa) => (
          <Card
            key={fatwa.id}
            className="overflow-hidden border border-gray-100 shadow-sm hover:shadow-md transition-shadow"
          >
            <CardContent className="p-4">
              <div className="flex items-start gap-4">
                <div className="flex-shrink-0 flex items-center justify-center w-10 h-10 rounded-full bg-emerald-50 text-emerald-600 mt-1">
                  <MessageCircle className="h-5 w-5" />
                </div>
                <div className="flex-1">
                  <div className="flex flex-wrap items-center gap-2 mb-1">
                    <span className="text-xs text-gray-500">{fatwa.date}</span>
                    <span className="bg-gray-100 text-gray-700 px-2 py-0.5 rounded text-xs">{fatwa.category}</span>
                  </div>
                  <h3 className="text-lg font-medium mb-2">{fatwa.title}</h3>
                  <Link href={`/fatwa/${fatwa.id}`}>
                    <Button variant="link" className="p-0 h-auto text-emerald-600">
                      قراءة الفتوى
                    </Button>
                  </Link>
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>
    </section>
  )
}
