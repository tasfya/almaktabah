import Link from "next/link"
import { Card, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Calendar, Share2, Copy } from "lucide-react"

export default function FeaturedArticles() {
  const articles = [
    {
      id: 1,
      title: "التحذير من الأعمال السيئة",
      date: "2018/01/01",
      type: "خطب",
    },
    {
      id: 2,
      title: "وقفة المحاسبة",
      date: "2018/01/01",
      type: "",
    },
    {
      id: 3,
      title: "وجوب التوكل وخطر التنطع",
      date: "2023/08/28",
      type: "خطب",
    },
  ]

  return (
    <section className="py-6">
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {articles.map((article) => (
          <Card key={article.id} className="overflow-hidden border-0 shadow-sm">
            <CardContent className="p-0">
              <div className="p-4 flex flex-col h-full">
                <div className="flex items-center justify-between mb-4">
                  <div className="flex items-center text-sm text-gray-500">
                    <Calendar className="h-4 w-4 ml-1" />
                    <span>{article.date}</span>
                  </div>
                  {article.type && (
                    <span className="bg-gray-200 px-2 py-0.5 rounded text-xs text-gray-700">{article.type}</span>
                  )}
                </div>
                <h3 className="text-xl font-semibold mb-4">{article.title}</h3>
                <div className="mt-auto flex items-center justify-between">
                  <Link href={`/article/${article.id}`}>
                    <Button variant="link" className="p-0 h-auto text-emerald-600">
                      قراءة المزيد
                    </Button>
                  </Link>
                  <div className="flex space-x-2 space-x-reverse">
                    <Button variant="ghost" size="icon" className="h-8 w-8">
                      <Share2 className="h-4 w-4" />
                    </Button>
                    <Button variant="ghost" size="icon" className="h-8 w-8">
                      <Copy className="h-4 w-4" />
                    </Button>
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>
    </section>
  )
}
