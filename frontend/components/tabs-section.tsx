import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Card, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Copy, Share2 } from "lucide-react"
import Link from "next/link"

export default function TabsSection() {
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
    <section className="py-6 bg-gray-50 -mx-4 px-4 my-6">
      <Tabs defaultValue="tab1" className="w-full">
        <div className="border-b mb-4">
          <TabsList className="bg-transparent border-b-0 justify-center">
            <TabsTrigger
              value="tab1"
              className="data-[state=active]:border-b-2 data-[state=active]:border-emerald-600 data-[state=active]:text-emerald-600 rounded-none px-6"
            >
              التحذير من الأعمال السيئة
            </TabsTrigger>
            <TabsTrigger
              value="tab2"
              className="data-[state=active]:border-b-2 data-[state=active]:border-emerald-600 data-[state=active]:text-emerald-600 rounded-none px-6"
            >
              وقفة للمحاسبة
            </TabsTrigger>
            <TabsTrigger
              value="tab3"
              className="data-[state=active]:border-b-2 data-[state=active]:border-emerald-600 data-[state=active]:text-emerald-600 rounded-none px-6"
            >
              وجوب التوكل وخطر التنطع
            </TabsTrigger>
          </TabsList>
        </div>

        <TabsContent value="tab1" className="mt-0">
          <Card className="border-0 shadow-sm">
            <CardContent className="p-4">
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center text-sm text-gray-500">
                  <span>2018/01/01</span>
                </div>
                <span className="bg-emerald-100 text-emerald-800 px-2 py-0.5 rounded text-xs">خطب</span>
              </div>
              <h3 className="text-xl font-semibold mb-4">التحذير من الأعمال السيئة</h3>
              <p className="text-gray-600 mb-4">
                هذا المقال يتناول موضوع التحذير من الأعمال السيئة وأثرها على الفرد والمجتمع، ويبين كيفية تجنبها والتوبة
                منها.
              </p>
              <div className="flex justify-between items-center">
                <Link href="/article/1">
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
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="tab2" className="mt-0">
          <Card className="border-0 shadow-sm">
            <CardContent className="p-4">
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center text-sm text-gray-500">
                  <span>2018/01/01</span>
                </div>
              </div>
              <h3 className="text-xl font-semibold mb-4">وقفة للمحاسبة</h3>
              <p className="text-gray-600 mb-4">
                هذا المقال يتناول أهمية محاسبة النفس وتقييم الأعمال بشكل دوري، ويقدم نصائح عملية لكيفية القيام بذلك
                بفعالية.
              </p>
              <div className="flex justify-between items-center">
                <Link href="/article/2">
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
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="tab3" className="mt-0">
          <Card className="border-0 shadow-sm">
            <CardContent className="p-4">
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center text-sm text-gray-500">
                  <span>2023/08/28</span>
                </div>
                <span className="bg-emerald-100 text-emerald-800 px-2 py-0.5 rounded text-xs">خطب</span>
              </div>
              <h3 className="text-xl font-semibold mb-4">وجوب التوكل وخطر التنطع</h3>
              <p className="text-gray-600 mb-4">
                يتناول هذا المقال أهمية التوكل على الله في جميع الأمور، ويحذر من خطر التنطع والتشدد في الدين بغير علم.
              </p>
              <div className="flex justify-between items-center">
                <Link href="/article/3">
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
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </section>
  )
}
