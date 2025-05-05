import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Card, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Calendar, Copy, Share2, ArrowLeft } from "lucide-react"
import Link from "next/link"
import Image from "next/image"

export default function FeaturedContent() {
  return (
    <section className="py-6">
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-2xl font-bold">المحتوى المميز</h2>
        <Button variant="ghost" className="text-emerald-600 hover:text-emerald-700">
          عرض الكل <ArrowLeft className="h-4 w-4 mr-1" />
        </Button>
      </div>

      <Tabs defaultValue="lessons" className="w-full">
        <TabsList className="bg-white border rounded-lg p-1 mb-6 w-fit mx-auto">
          <TabsTrigger
            value="lessons"
            className="data-[state=active]:bg-emerald-600 data-[state=active]:text-white rounded-md px-6"
          >
            الدروس
          </TabsTrigger>
          <TabsTrigger
            value="fatwas"
            className="data-[state=active]:bg-emerald-600 data-[state=active]:text-white rounded-md px-6"
          >
            الفتاوى
          </TabsTrigger>
          <TabsTrigger
            value="sermons"
            className="data-[state=active]:bg-emerald-600 data-[state=active]:text-white rounded-md px-6"
          >
            الخطب
          </TabsTrigger>
          <TabsTrigger
            value="benefits"
            className="data-[state=active]:bg-emerald-600 data-[state=active]:text-white rounded-md px-6"
          >
            الفوائد
          </TabsTrigger>
        </TabsList>

        <TabsContent value="lessons" className="mt-0">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <Card className="overflow-hidden border-0 shadow-sm">
              <div className="relative h-48">
                <Image
                  src="/placeholder.svg?height=200&width=400"
                  alt="العقيدة الطحاوية"
                  fill
                  className="object-cover"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-black/70 to-transparent"></div>
                <div className="absolute bottom-0 right-0 p-4">
                  <span className="bg-emerald-600 text-white px-2 py-1 rounded text-xs">دروس علمية</span>
                </div>
              </div>
              <CardContent className="p-4">
                <div className="flex items-center text-sm text-gray-500 mb-2">
                  <Calendar className="h-4 w-4 ml-1" />
                  <span>2018/03/13</span>
                </div>
                <h3 className="text-xl font-semibold mb-3">
                  العقيدة الطحاوية 1 من بداية الكتاب - إلى قوله وَلا شَيْءَ مِثْلُهُ
                </h3>
                <p className="text-gray-600 text-sm mb-4 line-clamp-2">
                  البداية الربانية في شرح العقيدة الطحاوية عقيدة أهل السنة والجماعة بسم الله الرحمن الرحيم الحمد لله رب
                  العالمين...
                </p>
                <div className="flex justify-between items-center">
                  <Link href="/lesson/1">
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

            <Card className="overflow-hidden border-0 shadow-sm">
              <div className="relative h-48">
                <Image src="/placeholder.svg?height=200&width=400" alt="كتاب الحج" fill className="object-cover" />
                <div className="absolute inset-0 bg-gradient-to-t from-black/70 to-transparent"></div>
                <div className="absolute bottom-0 right-0 p-4">
                  <span className="bg-emerald-600 text-white px-2 py-1 rounded text-xs">دروس علمية</span>
                </div>
              </div>
              <CardContent className="p-4">
                <div className="flex items-center text-sm text-gray-500 mb-2">
                  <Calendar className="h-4 w-4 ml-1" />
                  <span>2023/05/20</span>
                </div>
                <h3 className="text-xl font-semibold mb-3">كتاب الحج - حل العقدة في شرح العمدة -7</h3>
                <p className="text-gray-600 text-sm mb-4 line-clamp-2">
                  شرح مفصل لكتاب الحج من كتاب العمدة، يتناول أحكام الحج والعمرة وشروطهما وأركانهما...
                </p>
                <div className="flex justify-between items-center">
                  <Link href="/lesson/2">
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

            <Card className="overflow-hidden border-0 shadow-sm">
              <div className="relative h-48">
                <Image src="/placeholder.svg?height=200&width=400" alt="شرح أصول السنة" fill className="object-cover" />
                <div className="absolute inset-0 bg-gradient-to-t from-black/70 to-transparent"></div>
                <div className="absolute bottom-0 right-0 p-4">
                  <span className="bg-emerald-600 text-white px-2 py-1 rounded text-xs">دروس علمية</span>
                </div>
              </div>
              <CardContent className="p-4">
                <div className="flex items-center text-sm text-gray-500 mb-2">
                  <Calendar className="h-4 w-4 ml-1" />
                  <span>2022/11/15</span>
                </div>
                <h3 className="text-xl font-semibold mb-3">شرح أصول السنة للإمام أحمد بن حنبل</h3>
                <p className="text-gray-600 text-sm mb-4 line-clamp-2">
                  شرح مفصل لكتاب أصول السنة للإمام أحمد بن حنبل، يتناول أصول العقيدة الصحيحة...
                </p>
                <div className="flex justify-between items-center">
                  <Link href="/lesson/3">
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
          </div>
        </TabsContent>

        <TabsContent value="fatwas" className="mt-0">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <Card className="overflow-hidden border-0 shadow-sm">
              <div className="relative h-48">
                <Image
                  src="/placeholder.svg?height=200&width=400"
                  alt="حكمة خلق الله الكافر"
                  fill
                  className="object-cover"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-black/70 to-transparent"></div>
                <div className="absolute bottom-0 right-0 p-4">
                  <span className="bg-blue-600 text-white px-2 py-1 rounded text-xs">فتاوى</span>
                </div>
              </div>
              <CardContent className="p-4">
                <div className="flex items-center text-sm text-gray-500 mb-2">
                  <Calendar className="h-4 w-4 ml-1" />
                  <span>2023/02/10</span>
                </div>
                <h3 className="text-xl font-semibold mb-3">حكمة خلق الله الكافر مع علمه سبحانه أنه من أهل النار</h3>
                <p className="text-gray-600 text-sm mb-4 line-clamp-2">
                  بيان حكمة الله تعالى في خلق الكافر مع علمه سبحانه أنه من أهل النار، وتوضيح مسألة القضاء والقدر...
                </p>
                <div className="flex justify-between items-center">
                  <Link href="/fatwa/1">
                    <Button variant="link" className="p-0 h-auto text-blue-600">
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

            <Card className="overflow-hidden border-0 shadow-sm">
              <div className="relative h-48">
                <Image src="/placeholder.svg?height=200&width=400" alt="حكم دفع الزكاة" fill className="object-cover" />
                <div className="absolute inset-0 bg-gradient-to-t from-black/70 to-transparent"></div>
                <div className="absolute bottom-0 right-0 p-4">
                  <span className="bg-blue-600 text-white px-2 py-1 rounded text-xs">فتاوى</span>
                </div>
              </div>
              <CardContent className="p-4">
                <div className="flex items-center text-sm text-gray-500 mb-2">
                  <Calendar className="h-4 w-4 ml-1" />
                  <span>2023/04/15</span>
                </div>
                <h3 className="text-xl font-semibold mb-3">حكم دفع الزكاة لشراء سيارة</h3>
                <p className="text-gray-600 text-sm mb-4 line-clamp-2">
                  بيان حكم دفع الزكاة لشراء سيارة للمحتاجين، وتوضيح مصارف الزكاة الشرعية...
                </p>
                <div className="flex justify-between items-center">
                  <Link href="/fatwa/2">
                    <Button variant="link" className="p-0 h-auto text-blue-600">
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

            <Card className="overflow-hidden border-0 shadow-sm">
              <div className="relative h-48">
                <Image src="/placeholder.svg?height=200&width=400" alt="غسل الجمعة" fill className="object-cover" />
                <div className="absolute inset-0 bg-gradient-to-t from-black/70 to-transparent"></div>
                <div className="absolute bottom-0 right-0 p-4">
                  <span className="bg-blue-600 text-white px-2 py-1 rounded text-xs">فتاوى</span>
                </div>
              </div>
              <CardContent className="p-4">
                <div className="flex items-center text-sm text-gray-500 mb-2">
                  <Calendar className="h-4 w-4 ml-1" />
                  <span>2023/03/20</span>
                </div>
                <h3 className="text-xl font-semibold mb-3">هل يمكن غسل الجمعة عن الوضوء</h3>
                <p className="text-gray-600 text-sm mb-4 line-clamp-2">
                  بيان حكم الاكتفاء بغسل الجمعة عن الوضوء، وتوضيح العلاقة بين الغسل والوضوء...
                </p>
                <div className="flex justify-between items-center">
                  <Link href="/fatwa/3">
                    <Button variant="link" className="p-0 h-auto text-blue-600">
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
          </div>
        </TabsContent>

        <TabsContent value="sermons" className="mt-0">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <Card className="overflow-hidden border-0 shadow-sm">
              <div className="relative h-48">
                <Image
                  src="/placeholder.svg?height=200&width=400"
                  alt="التحذير من الأعمال السيئة"
                  fill
                  className="object-cover"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-black/70 to-transparent"></div>
                <div className="absolute bottom-0 right-0 p-4">
                  <span className="bg-amber-600 text-white px-2 py-1 rounded text-xs">خطب</span>
                </div>
              </div>
              <CardContent className="p-4">
                <div className="flex items-center text-sm text-gray-500 mb-2">
                  <Calendar className="h-4 w-4 ml-1" />
                  <span>2018/01/01</span>
                </div>
                <h3 className="text-xl font-semibold mb-3">التحذير من الأعمال السيئة</h3>
                <p className="text-gray-600 text-sm mb-4 line-clamp-2">
                  خطبة تتناول التحذير من الأعمال السيئة وأثرها على الفرد والمجتمع، وكيفية التوبة منها...
                </p>
                <div className="flex justify-between items-center">
                  <Link href="/sermon/1">
                    <Button variant="link" className="p-0 h-auto text-amber-600">
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

            <Card className="overflow-hidden border-0 shadow-sm">
              <div className="relative h-48">
                <Image src="/placeholder.svg?height=200&width=400" alt="وقفة للمحاسبة" fill className="object-cover" />
                <div className="absolute inset-0 bg-gradient-to-t from-black/70 to-transparent"></div>
                <div className="absolute bottom-0 right-0 p-4">
                  <span className="bg-amber-600 text-white px-2 py-1 rounded text-xs">خطب</span>
                </div>
              </div>
              <CardContent className="p-4">
                <div className="flex items-center text-sm text-gray-500 mb-2">
                  <Calendar className="h-4 w-4 ml-1" />
                  <span>2018/01/01</span>
                </div>
                <h3 className="text-xl font-semibold mb-3">وقفة للمحاسبة</h3>
                <p className="text-gray-600 text-sm mb-4 line-clamp-2">
                  خطبة تتناول أهمية محاسبة النفس وتقييم الأعمال بشكل دوري، وكيفية القيام بذلك...
                </p>
                <div className="flex justify-between items-center">
                  <Link href="/sermon/2">
                    <Button variant="link" className="p-0 h-auto text-amber-600">
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

            <Card className="overflow-hidden border-0 shadow-sm">
              <div className="relative h-48">
                <Image src="/placeholder.svg?height=200&width=400" alt="وجوب التوكل" fill className="object-cover" />
                <div className="absolute inset-0 bg-gradient-to-t from-black/70 to-transparent"></div>
                <div className="absolute bottom-0 right-0 p-4">
                  <span className="bg-amber-600 text-white px-2 py-1 rounded text-xs">خطب</span>
                </div>
              </div>
              <CardContent className="p-4">
                <div className="flex items-center text-sm text-gray-500 mb-2">
                  <Calendar className="h-4 w-4 ml-1" />
                  <span>2023/08/28</span>
                </div>
                <h3 className="text-xl font-semibold mb-3">وجوب التوكل وخطر التنطع</h3>
                <p className="text-gray-600 text-sm mb-4 line-clamp-2">
                  خطبة تتناول أهمية التوكل على الله في جميع الأمور، والتحذير من خطر التنطع والتشدد...
                </p>
                <div className="flex justify-between items-center">
                  <Link href="/sermon/3">
                    <Button variant="link" className="p-0 h-auto text-amber-600">
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
          </div>
        </TabsContent>

        <TabsContent value="benefits" className="mt-0">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <Card className="overflow-hidden border-0 shadow-sm">
              <div className="relative h-48">
                <Image src="/placeholder.svg?height=200&width=400" alt="فضل الصلاة" fill className="object-cover" />
                <div className="absolute inset-0 bg-gradient-to-t from-black/70 to-transparent"></div>
                <div className="absolute bottom-0 right-0 p-4">
                  <span className="bg-teal-600 text-white px-2 py-1 rounded text-xs">فوائد</span>
                </div>
              </div>
              <CardContent className="p-4">
                <div className="flex items-center text-sm text-gray-500 mb-2">
                  <Calendar className="h-4 w-4 ml-1" />
                  <span>2023/01/15</span>
                </div>
                <h3 className="text-xl font-semibold mb-3">فضل الصلاة في وقتها</h3>
                <p className="text-gray-600 text-sm mb-4 line-clamp-2">
                  فائدة تتناول فضل الصلاة في وقتها وأهمية المحافظة على الصلوات الخمس...
                </p>
                <div className="flex justify-between items-center">
                  <Link href="/benefit/1">
                    <Button variant="link" className="p-0 h-auto text-teal-600">
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

            <Card className="overflow-hidden border-0 shadow-sm">
              <div className="relative h-48">
                <Image src="/placeholder.svg?height=200&width=400" alt="أهمية الصدق" fill className="object-cover" />
                <div className="absolute inset-0 bg-gradient-to-t from-black/70 to-transparent"></div>
                <div className="absolute bottom-0 right-0 p-4">
                  <span className="bg-teal-600 text-white px-2 py-1 rounded text-xs">فوائد</span>
                </div>
              </div>
              <CardContent className="p-4">
                <div className="flex items-center text-sm text-gray-500 mb-2">
                  <Calendar className="h-4 w-4 ml-1" />
                  <span>2023/02/20</span>
                </div>
                <h3 className="text-xl font-semibold mb-3">أهمية الصدق في القول والعمل</h3>
                <p className="text-gray-600 text-sm mb-4 line-clamp-2">
                  فائدة تتناول أهمية الصدق في القول والعمل وأثره على الفرد والمجتمع...
                </p>
                <div className="flex justify-between items-center">
                  <Link href="/benefit/2">
                    <Button variant="link" className="p-0 h-auto text-teal-600">
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

            <Card className="overflow-hidden border-0 shadow-sm">
              <div className="relative h-48">
                <Image src="/placeholder.svg?height=200&width=400" alt="فضل الصيام" fill className="object-cover" />
                <div className="absolute inset-0 bg-gradient-to-t from-black/70 to-transparent"></div>
                <div className="absolute bottom-0 right-0 p-4">
                  <span className="bg-teal-600 text-white px-2 py-1 rounded text-xs">فوائد</span>
                </div>
              </div>
              <CardContent className="p-4">
                <div className="flex items-center text-sm text-gray-500 mb-2">
                  <Calendar className="h-4 w-4 ml-1" />
                  <span>2023/03/10</span>
                </div>
                <h3 className="text-xl font-semibold mb-3">فضل الصيام وآدابه</h3>
                <p className="text-gray-600 text-sm mb-4 line-clamp-2">
                  فائدة تتناول فضل الصيام وآدابه وأثره على تزكية النفس وتهذيبها...
                </p>
                <div className="flex justify-between items-center">
                  <Link href="/benefit/3">
                    <Button variant="link" className="p-0 h-auto text-teal-600">
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
          </div>
        </TabsContent>
      </Tabs>
    </section>
  )
}
