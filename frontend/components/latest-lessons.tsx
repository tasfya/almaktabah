import Link from "next/link"
import { Card, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Copy, Share2 } from "lucide-react"

export default function LatestLessons() {
  const lessons = [
    {
      id: 1,
      title: "كتاب الحج - حل العقدة في شرح العمدة -7",
      type: "lessons",
    },
    {
      id: 2,
      title: "كتاب الحج - حل العقدة في شرح العمدة -8",
      type: "lessons",
    },
    {
      id: 3,
      title: "كتاب الحج - حل العقدة في شرح العمدة -9",
      type: "lessons",
    },
    {
      id: 4,
      title: "كتاب الحج - حل العقدة في شرح العمدة -10",
      type: "lessons",
    },
    {
      id: 5,
      title: "كتاب الحج - حل العقدة في شرح العمدة -11",
      type: "lessons",
    },
  ]

  return (
    <section className="py-10">
      <Tabs defaultValue="lessons" className="w-full">
        <div className="border-b">
          <TabsList className="bg-transparent border-b-0">
            <TabsTrigger
              value="lessons"
              className="data-[state=active]:border-b-2 data-[state=active]:border-emerald-600 data-[state=active]:text-emerald-600 rounded-none"
            >
              الخطب
            </TabsTrigger>
            <TabsTrigger
              value="lectures"
              className="data-[state=active]:border-b-2 data-[state=active]:border-emerald-600 data-[state=active]:text-emerald-600 rounded-none"
            >
              المحاضرات
            </TabsTrigger>
            <TabsTrigger
              value="benefits"
              className="data-[state=active]:border-b-2 data-[state=active]:border-emerald-600 data-[state=active]:text-emerald-600 rounded-none"
            >
              الفوائد
            </TabsTrigger>
          </TabsList>
        </div>

        <TabsContent value="lessons" className="mt-6">
          <div className="space-y-4">
            {lessons.map((lesson) => (
              <Card key={lesson.id} className="overflow-hidden">
                <CardContent className="p-4">
                  <div className="flex items-center justify-between">
                    <Link href={`/lesson/${lesson.id}`} className="flex-1">
                      <h3 className="text-lg font-medium">{lesson.title}</h3>
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
                </CardContent>
              </Card>
            ))}
          </div>
        </TabsContent>

        <TabsContent value="lectures" className="mt-6">
          <div className="text-center py-10 text-gray-500">لا توجد محاضرات حالياً</div>
        </TabsContent>

        <TabsContent value="benefits" className="mt-6">
          <div className="text-center py-10 text-gray-500">لا توجد فوائد حالياً</div>
        </TabsContent>
      </Tabs>
    </section>
  )
}
