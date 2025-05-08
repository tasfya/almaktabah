import { Breadcrumb, BreadcrumbItem, BreadcrumbLink, BreadcrumbList, BreadcrumbSeparator } from "@/components/ui/breadcrumb"
import { Card, CardContent } from "@/components/ui/card"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Button } from "@/components/ui/button"
import { Copy, Share2, Search, Calendar, Filter, ArrowUpDown, Clock, Play, Mic, Headphones, Download, BookmarkPlus } from "lucide-react"
import Link from "next/link"
import Image from "next/image"
import PageSidebar from "@/components/page-sidebar"

export default function SermonsPage() {
  return (
    <div className="bg-gray-50 min-h-screen py-8">
      <div className="container mx-auto px-4">
        {/* Breadcrumb */}
        <Breadcrumb className="mb-4">
          <BreadcrumbList>
            <BreadcrumbItem>
              <BreadcrumbLink href="/">الرئيسية</BreadcrumbLink>
            </BreadcrumbItem>
            <BreadcrumbSeparator />
            <BreadcrumbItem>
              <BreadcrumbLink href="/sermons">الخطب</BreadcrumbLink>
            </BreadcrumbItem>
          </BreadcrumbList>
        </Breadcrumb>

        {/* Main Layout */}
        <div className="grid grid-cols-1 lg:grid-cols-4 gap-8">
          {/* Main Content */}
          <div className="lg:col-span-3">
            {/* Page Title with Stats */}
            <div className="mb-8 bg-white p-6 rounded-lg border border-gray-100 shadow-sm">
              <div className="flex flex-col md:flex-row md:items-center md:justify-between mb-4">
                <div>
                  <h1 className="text-3xl font-bold mb-2 text-gray-900">الخطب</h1>
                  <p className="text-gray-600">خطب الجمعة والمناسبات للشيخ</p>
                </div>
                <div className="mt-4 md:mt-0 flex flex-wrap gap-4">
                  <div className="bg-emerald-50 rounded-lg p-3 text-center min-w-[100px]">
                    <span className="block text-2xl font-bold text-emerald-600">520+</span>
                    <span className="text-xs text-gray-600">خطبة</span>
                  </div>
                  <div className="bg-emerald-50 rounded-lg p-3 text-center min-w-[100px]">
                    <span className="block text-2xl font-bold text-emerald-600">35+</span>
                    <span className="text-xs text-gray-600">موضوع</span>
                  </div>
                </div>
              </div>
            </div>

            {/* Featured Sermon */}
            <div className="mb-8">
              <Card className="border-gray-100 shadow-sm overflow-hidden">
                <div className="relative">
                  <div className="relative h-64 w-full">
                    <Image 
                      src="/placeholder.svg?height=400&width=800" 
                      alt="خطبة مميزة"
                      fill
                      className="object-cover"
                    />
                    <div className="absolute inset-0 bg-gradient-to-t from-black/90 via-black/60 to-transparent"></div>
                    <div className="absolute inset-0 flex items-center justify-center">
                      <Button variant="ghost" size="icon" className="h-16 w-16 rounded-full bg-white/20 backdrop-blur-sm text-white hover:bg-white/30 hover:scale-110 transition-all">
                        <Play className="h-8 w-8" />
                      </Button>
                    </div>
                    <div className="absolute top-4 right-4">
                      <span className="bg-emerald-600 text-white px-2 py-1 rounded text-xs">الخطبة الأخيرة</span>
                    </div>
                  </div>
                  <div className="absolute bottom-0 right-0 left-0 p-6 text-white">
                    <h2 className="text-2xl font-bold mb-2">أهمية الصدق والأمانة في حياة المسلم</h2>
                    <div className="flex flex-wrap items-center gap-4 mb-3">
                      <div className="flex items-center text-sm">
                        <Calendar className="h-4 w-4 ml-1" />
                        <span>الجمعة 12 رجب 1445هـ</span>
                      </div>
                      <div className="flex items-center text-sm">
                        <Clock className="h-4 w-4 ml-1" />
                        <span>35 دقيقة</span>
                      </div>
                      <div className="flex items-center text-sm">
                        <Headphones className="h-4 w-4 ml-1" />
                        <span>2.5K استماع</span>
                      </div>
                    </div>
                    <div className="flex gap-3">
                      <Button className="bg-emerald-600 hover:bg-emerald-700">
                        <Headphones className="h-4 w-4 ml-2" />
                        استماع الآن
                      </Button>
                      <Button variant="outline" className="border-white text-white hover:bg-white/20">
                        <Download className="h-4 w-4 ml-2" />
                        تحميل
                      </Button>
                      <Button variant="ghost" className="bg-white/10 hover:bg-white/20">
                        <BookmarkPlus className="h-4 w-4 ml-2" />
                        حفظ
                      </Button>
                    </div>
                  </div>
                </div>
              </Card>
            </div>

            {/* Search and Filter Section */}
            <div className="mb-6">
              <Card className="border-gray-100 shadow-sm">
                <CardContent className="p-4">
                  <div className="grid grid-cols-1 md:grid-cols-[1fr,auto] gap-4">
                    <div className="relative">
                      <input
                        type="search"
                        placeholder="ابحث في الخطب..."
                        className="w-full p-2 pl-10 pr-4 border rounded-md border-gray-200"
                      />
                      <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" size={18} />
                    </div>
                    <div className="flex gap-2">
                      <Button variant="outline" className="text-emerald-600 border-emerald-200 hover:bg-emerald-50">
                        <Filter className="h-4 w-4 ml-2" />
                        تصفية
                      </Button>
                      <Button variant="outline" className="text-emerald-600 border-emerald-200 hover:bg-emerald-50">
                        <ArrowUpDown className="h-4 w-4 ml-2" />
                        ترتيب
                      </Button>
                      <Button className="bg-emerald-600 hover:bg-emerald-700">بحث</Button>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </div>

            {/* Popular Topics */}
            <div className="mb-8">
              <h2 className="text-xl font-bold mb-4 border-r-4 border-emerald-600 pr-3">المواضيع الشائعة</h2>
              <div className="flex flex-wrap gap-2">
                {["التقوى", "الإيمان", "العبادات", "الأخلاق", "الأسرة", "المجتمع", "الصبر", "الرزق", "التوبة", "الدعاء"].map((topic, index) => (
                  <Button 
                    key={index} 
                    variant="outline" 
                    className="rounded-full text-emerald-700 border-emerald-200 hover:bg-emerald-50"
                  >
                    {topic}
                  </Button>
                ))}
              </div>
            </div>

            {/* Sermons List */}
            <div className="mb-8">
              <Tabs defaultValue="all" className="w-full">
                <TabsList className="bg-white border rounded-lg p-1 mb-6 w-fit mx-auto">
                  <TabsTrigger
                    value="all"
                    className="data-[state=active]:bg-emerald-600 data-[state=active]:text-white rounded-md px-6"
                  >
                    الكل
                  </TabsTrigger>
                  <TabsTrigger
                    value="text"
                    className="data-[state=active]:bg-emerald-600 data-[state=active]:text-white rounded-md px-6"
                  >
                    نصوص
                  </TabsTrigger>
                  <TabsTrigger
                    value="audio"
                    className="data-[state=active]:bg-emerald-600 data-[state=active]:text-white rounded-md px-6"
                  >
                    صوتيات
                  </TabsTrigger>
                  <TabsTrigger
                    value="video"
                    className="data-[state=active]:bg-emerald-600 data-[state=active]:text-white rounded-md px-6"
                  >
                    مرئيات
                  </TabsTrigger>
                </TabsList>

                <TabsContent value="all" className="mt-0">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    {[1, 2, 3, 4, 5, 6].map((item) => (
                      <Card key={item} className="overflow-hidden border-0 shadow-sm group hover:shadow-md transition-shadow flex flex-col h-full">
                        <div className="relative h-48">
                          <Image src="/placeholder.svg?height=200&width=400" alt="عنوان الخطبة" fill className="object-cover group-hover:scale-105 transition-transform" />
                          <div className="absolute inset-0 bg-gradient-to-t from-black/70 to-transparent"></div>
                          <div className="absolute top-3 right-3">
                            <span className="bg-emerald-600 text-white px-2 py-1 rounded text-xs">خطبة</span>
                          </div>
                          <div className="absolute bottom-0 inset-x-0 p-4 text-white">
                            <div className="flex justify-between items-center mb-2">
                              <div className="flex items-center text-xs">
                                <Calendar className="h-3 w-3 ml-1" />
                                <span>2023/03/{10 + item}</span>
                              </div>
                              <div className="flex items-center text-xs">
                                <Headphones className="h-3 w-3 ml-1" />
                                <span>{item * 120} استماع</span>
                              </div>
                            </div>
                            <h3 className="text-lg font-semibold line-clamp-1">
                              {item % 3 === 0 ? "أثر الإيمان في استقرار المجتمع" : 
                              item % 3 === 1 ? "فضل التقوى والعمل الصالح" :
                              "وسائل تقوية الصلة بالله"}
                            </h3>
                          </div>
                          <div className="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                            <Button variant="ghost" size="icon" className="h-12 w-12 rounded-full bg-white/20 backdrop-blur-sm text-white hover:bg-white/30">
                              <Play className="h-6 w-6" />
                            </Button>
                          </div>
                        </div>
                        <CardContent className="p-4 flex-1 flex flex-col">
                          <p className="text-gray-600 text-sm mb-4 line-clamp-2 flex-1">
                            {item % 3 === 0 ? 
                            "خطبة تتناول أثر الإيمان في استقرار المجتمع وتماسكه وكيف أن الإيمان يحقق الأمن النفسي والاجتماعي..." : 
                            item % 3 === 1 ? 
                            "خطبة جمعة تتناول فضل التقوى والعمل الصالح وأثرهما على الفرد والمجتمع في الدنيا والآخرة..." : 
                            "خطبة تتحدث عن وسائل تقوية الصلة بالله عز وجل والإكثار من ذكره والتقرب إليه بالطاعات..."}
                          </p>
                          <div className="flex justify-between items-center">
                            <Link href={`/sermon/${item}`}>
                              <Button variant="link" className="p-0 h-auto text-emerald-600">
                                قراءة المزيد
                              </Button>
                            </Link>
                            <div className="flex gap-2">
                              <Button variant="ghost" size="sm" className="h-8 w-8 p-0 text-gray-500 hover:text-emerald-600 hover:bg-emerald-50">
                                <Download className="h-4 w-4" />
                              </Button>
                              <Button variant="ghost" size="sm" className="h-8 w-8 p-0 text-gray-500 hover:text-emerald-600 hover:bg-emerald-50">
                                <Share2 className="h-4 w-4" />
                              </Button>
                            </div>
                          </div>
                        </CardContent>
                      </Card>
                    ))}
                  </div>

                  {/* Pagination */}
                  <div className="flex justify-center mt-8">
                    <div className="flex gap-1">
                      <Button variant="outline" size="sm" className="h-8 w-8 p-0">1</Button>
                      <Button variant="ghost" size="sm" className="h-8 w-8 p-0">2</Button>
                      <Button variant="ghost" size="sm" className="h-8 w-8 p-0">3</Button>
                      <Button variant="ghost" size="sm" className="h-8 w-8 p-0">4</Button>
                      <Button variant="ghost" size="sm" className="h-8 w-8 p-0">5</Button>
                    </div>
                  </div>
                </TabsContent>

                <TabsContent value="text" className="mt-0">
                  <div className="text-center py-10 text-gray-500">نصوص الخطب</div>
                </TabsContent>

                <TabsContent value="audio" className="mt-0">
                  <div className="text-center py-10 text-gray-500">الخطب الصوتية</div>
                </TabsContent>

                <TabsContent value="video" className="mt-0">
                  <div className="text-center py-10 text-gray-500">الخطب المرئية</div>
                </TabsContent>
              </Tabs>
            </div>
          </div>

          {/* Sidebar */}
          <div className="lg:col-span-1">
            <PageSidebar />
          </div>
        </div>
      </div>
    </div>
  )
}