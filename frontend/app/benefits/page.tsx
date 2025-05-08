import { Breadcrumb, BreadcrumbItem, BreadcrumbLink, BreadcrumbList, BreadcrumbSeparator } from "@/components/ui/breadcrumb"
import { Card, CardContent } from "@/components/ui/card"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Button } from "@/components/ui/button"
import { Copy, Share2, Search, Calendar, Filter, ArrowUpDown, Lightbulb, Tag, MessageSquare, BookmarkPlus, ThumbsUp } from "lucide-react"
import Link from "next/link"
import Image from "next/image"
import PageSidebar from "@/components/page-sidebar"

export default function BenefitsPage() {
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
              <BreadcrumbLink href="/benifits">الفوائد</BreadcrumbLink>
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
                  <h1 className="text-3xl font-bold mb-2 text-gray-900">الفوائد العلمية</h1>
                  <p className="text-gray-600">فوائد علمية منتقاة من دروس ومحاضرات الشيخ</p>
                </div>
                <div className="mt-4 md:mt-0 flex flex-wrap gap-4">
                  <div className="bg-emerald-50 rounded-lg p-3 text-center min-w-[100px]">
                    <span className="block text-2xl font-bold text-emerald-600">430+</span>
                    <span className="text-xs text-gray-600">فائدة علمية</span>
                  </div>
                  <div className="bg-emerald-50 rounded-lg p-3 text-center min-w-[100px]">
                    <span className="block text-2xl font-bold text-emerald-600">25+</span>
                    <span className="text-xs text-gray-600">تصنيف</span>
                  </div>
                </div>
              </div>
            </div>

            {/* Featured Benefits */}
            <div className="mb-8">
              <h2 className="text-xl font-bold mb-6 border-r-4 border-emerald-600 pr-3">مختارات الفوائد</h2>
              <div className="grid grid-cols-1 gap-4">
                <Card className="border-gray-100 shadow-sm hover:shadow-md transition-shadow bg-gradient-to-br from-emerald-50 to-white">
                  <CardContent className="p-6">
                    <div className="flex gap-4 items-center">
                      <div className="w-12 h-12 rounded-full bg-emerald-100 flex items-center justify-center flex-shrink-0">
                        <Lightbulb className="h-6 w-6 text-emerald-600" />
                      </div>
                      <div className="flex-1">
                        <h3 className="text-xl font-semibold mb-2 text-gray-900">"إنما الأعمال بالنيات"</h3>
                        <p className="text-gray-700 mb-3">
                          من أعظم الأحاديث النبوية التي تدل على أهمية النية في العمل، وأن قبول الأعمال وصحتها متوقف على النية، فالنية شرط لصحة العمل وقبوله عند الله.
                        </p>
                        <div className="flex items-center justify-between mt-4">
                          <div className="flex items-center text-sm text-gray-500">
                            <Tag className="h-4 w-4 ml-1" />
                            <span>حديث شريف</span>
                          </div>
                          <div className="flex items-center gap-3">
                            <Button variant="outline" size="sm" className="h-8 text-emerald-600 border-emerald-200 hover:bg-emerald-50">
                              <BookmarkPlus className="h-4 w-4 ml-2" />
                              حفظ
                            </Button>
                            <Button variant="outline" size="sm" className="h-8 text-emerald-600 border-emerald-200 hover:bg-emerald-50">
                              <Share2 className="h-4 w-4 ml-2" />
                              مشاركة
                            </Button>
                          </div>
                        </div>
                      </div>
                    </div>
                  </CardContent>
                </Card>

                <Card className="border-gray-100 shadow-sm hover:shadow-md transition-shadow bg-gradient-to-br from-emerald-50 to-white">
                  <CardContent className="p-6">
                    <div className="flex gap-4 items-center">
                      <div className="w-12 h-12 rounded-full bg-emerald-100 flex items-center justify-center flex-shrink-0">
                        <Lightbulb className="h-6 w-6 text-emerald-600" />
                      </div>
                      <div className="flex-1">
                        <h3 className="text-xl font-semibold mb-2 text-gray-900">"من كان يؤمن بالله واليوم الآخر فليقل خيراً أو ليصمت"</h3>
                        <p className="text-gray-700 mb-3">
                          حديث عظيم يدل على أهمية حفظ اللسان، وأن المؤمن يزن كلامه قبل أن يتكلم، فإن كان خيراً تكلم وإلا فالسكوت خير له.
                        </p>
                        <div className="flex items-center justify-between mt-4">
                          <div className="flex items-center text-sm text-gray-500">
                            <Tag className="h-4 w-4 ml-1" />
                            <span>حديث شريف</span>
                          </div>
                          <div className="flex items-center gap-3">
                            <Button variant="outline" size="sm" className="h-8 text-emerald-600 border-emerald-200 hover:bg-emerald-50">
                              <BookmarkPlus className="h-4 w-4 ml-2" />
                              حفظ
                            </Button>
                            <Button variant="outline" size="sm" className="h-8 text-emerald-600 border-emerald-200 hover:bg-emerald-50">
                              <Share2 className="h-4 w-4 ml-2" />
                              مشاركة
                            </Button>
                          </div>
                        </div>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              </div>
            </div>

            {/* Search and Filter Section */}
            <div className="mb-6">
              <Card className="border-gray-100 shadow-sm">
                <CardContent className="p-4">
                  <div className="grid grid-cols-1 md:grid-cols-[1fr,auto] gap-4">
                    <div className="relative">
                      <input
                        type="search"
                        placeholder="ابحث في الفوائد العلمية..."
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

            {/* Categories Tabs */}
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
                    value="aqeedah"
                    className="data-[state=active]:bg-emerald-600 data-[state=active]:text-white rounded-md px-6"
                  >
                    العقيدة
                  </TabsTrigger>
                  <TabsTrigger
                    value="fiqh"
                    className="data-[state=active]:bg-emerald-600 data-[state=active]:text-white rounded-md px-6"
                  >
                    الفقه
                  </TabsTrigger>
                  <TabsTrigger
                    value="akhlaq"
                    className="data-[state=active]:bg-emerald-600 data-[state=active]:text-white rounded-md px-6"
                  >
                    الأخلاق
                  </TabsTrigger>
                  <TabsTrigger
                    value="tafsir"
                    className="data-[state=active]:bg-emerald-600 data-[state=active]:text-white rounded-md px-6"
                  >
                    التفسير
                  </TabsTrigger>
                </TabsList>

                <TabsContent value="all" className="mt-0">
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                    {[1, 2, 3, 4, 5, 6].map((item) => (
                      <Card key={item} className="overflow-hidden border-0 shadow-sm group hover:shadow-md transition-shadow">
                        <div className="relative h-36">
                          <Image src="/placeholder.svg?height=144&width=400" alt="صورة الفائدة" fill className="object-cover group-hover:scale-105 transition-transform" />
                          <div className="absolute inset-0 bg-gradient-to-t from-black/70 to-transparent"></div>
                          <div className="absolute top-3 right-3">
                            <span className={`px-2 py-1 rounded text-xs text-white ${
                              item % 4 === 0 ? "bg-emerald-600" : 
                              item % 4 === 1 ? "bg-blue-600" : 
                              item % 4 === 2 ? "bg-amber-600" : 
                              "bg-purple-600"
                            }`}>
                              {item % 4 === 0 ? "الفقه" : 
                               item % 4 === 1 ? "العقيدة" : 
                               item % 4 === 2 ? "الأخلاق" : 
                               "التفسير"}
                            </span>
                          </div>
                          <div className="absolute bottom-3 left-3">
                            <div className="flex items-center gap-1">
                              <Button variant="ghost" size="icon" className="h-7 w-7 bg-white/80 text-emerald-600 hover:bg-white">
                                <ThumbsUp className="h-4 w-4" />
                              </Button>
                              <Button variant="ghost" size="icon" className="h-7 w-7 bg-white/80 text-emerald-600 hover:bg-white">
                                <BookmarkPlus className="h-4 w-4" />
                              </Button>
                            </div>
                          </div>
                        </div>
                        <CardContent className="p-4">
                          <div className="flex items-center justify-between text-sm text-gray-500 mb-2">
                            <div className="flex items-center">
                              <Calendar className="h-4 w-4 ml-1" />
                              <span>2023/05/{15 + item}</span>
                            </div>
                            <div className="flex items-center">
                              <ThumbsUp className="h-4 w-4 ml-1" />
                              <span>{item * 45 + 120}</span>
                            </div>
                          </div>
                          <h3 className="text-lg font-semibold mb-2 line-clamp-1">
                            {item % 3 === 0 ? "آداب طلب العلم الشرعي" : 
                            item % 3 === 1 ? "فضل الصيام وآدابه" :
                            "أهمية الإخلاص في العمل"}
                          </h3>
                          <p className="text-gray-600 text-sm mb-3 line-clamp-2">
                            {item % 3 === 0 ? 
                            "من أهم آداب طلب العلم الإخلاص والصبر والتدرج في الطلب، وتعظيم العلم وأهله..." : 
                            item % 3 === 1 ? 
                            "الصيام من أفضل العبادات التي يتقرب بها العبد إلى ربه، وله فوائد عظيمة على الصحة..." : 
                            "الإخلاص أساس قبول العمل عند الله تعالى، وهو سر من أسرار النجاح وتحقيق البركة..."}
                          </p>
                          <div className="flex justify-between items-center">
                            <Link href={`/benefit/${item}`}>
                              <Button variant="link" className="p-0 h-auto text-emerald-600">
                                قراءة كاملة
                              </Button>
                            </Link>
                            <Button variant="ghost" size="sm" className="h-8 w-8 p-0 text-gray-500 hover:text-emerald-600 hover:bg-emerald-50">
                              <Share2 className="h-4 w-4" />
                            </Button>
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

                <TabsContent value="aqeedah" className="mt-0">
                  <div className="text-center py-10 text-gray-500">فوائد في العقيدة</div>
                </TabsContent>

                <TabsContent value="fiqh" className="mt-0">
                  <div className="text-center py-10 text-gray-500">فوائد في الفقه</div>
                </TabsContent>

                <TabsContent value="akhlaq" className="mt-0">
                  <div className="text-center py-10 text-gray-500">فوائد في الأخلاق</div>
                </TabsContent>
                
                <TabsContent value="tafsir" className="mt-0">
                  <div className="text-center py-10 text-gray-500">فوائد في التفسير</div>
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