import { Breadcrumb, BreadcrumbItem, BreadcrumbLink, BreadcrumbList, BreadcrumbSeparator } from "@/components/ui/breadcrumb"
import { Card, CardContent } from "@/components/ui/card"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Button } from "@/components/ui/button"
import { Copy, Share2, Search, Calendar, Filter, ArrowUpDown, Tag, MessageSquare, Eye, BookmarkPlus, Play, Clock, Volume2 } from "lucide-react"
import Link from "next/link"
import Image from "next/image"
import PageSidebar from "@/components/page-sidebar"

export default function LecturesPage() {
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
              <BreadcrumbLink href="/lectures">المحاضرات والكلمات</BreadcrumbLink>
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
                  <h1 className="text-3xl font-bold mb-2 text-gray-900">المحاضرات والكلمات</h1>
                  <p className="text-gray-600">تصفح جميع المحاضرات والكلمات للشيخ في مختلف المناسبات</p>
                </div>
                <div className="mt-4 md:mt-0 flex flex-wrap gap-4">
                  <div className="bg-emerald-50 rounded-lg p-3 text-center min-w-[100px]">
                    <span className="block text-2xl font-bold text-emerald-600">750+</span>
                    <span className="text-xs text-gray-600">محاضرة</span>
                  </div>
                  <div className="bg-emerald-50 rounded-lg p-3 text-center min-w-[100px]">
                    <span className="block text-2xl font-bold text-emerald-600">320+</span>
                    <span className="text-xs text-gray-600">كلمة</span>
                  </div>
                </div>
              </div>
            </div>

            {/* Search and Featured Section */}
            <div className="grid grid-cols-1 md:grid-cols-[2fr,1fr] gap-6 mb-8">
              {/* Search Section */}
              <div>
                <Card className="border-gray-100 shadow-sm h-full">
                  <CardContent className="p-4">
                    <h2 className="text-lg font-bold mb-4">ابحث في المحاضرات والكلمات</h2>
                    <div className="grid grid-cols-1 gap-4">
                      <div className="relative">
                        <input
                          type="search"
                          placeholder="ابحث باسم الموضوع أو الكلمات المفتاحية..."
                          className="w-full p-2 pl-10 pr-4 border rounded-md border-gray-200"
                        />
                        <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" size={18} />
                      </div>
                      <div className="flex flex-wrap gap-2">
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
                      <div className="flex flex-wrap gap-2 mt-2">
                        <span className="text-sm text-gray-500 ml-2">الأكثر بحثاً:</span>
                        <Button variant="outline" size="sm" className="h-7 rounded-full text-xs border-gray-200 hover:border-emerald-200 hover:bg-emerald-50">
                          رمضان
                        </Button>
                        <Button variant="outline" size="sm" className="h-7 rounded-full text-xs border-gray-200 hover:border-emerald-200 hover:bg-emerald-50">
                          التربية
                        </Button>
                        <Button variant="outline" size="sm" className="h-7 rounded-full text-xs border-gray-200 hover:border-emerald-200 hover:bg-emerald-50">
                          العقيدة
                        </Button>
                        <Button variant="outline" size="sm" className="h-7 rounded-full text-xs border-gray-200 hover:border-emerald-200 hover:bg-emerald-50">
                          الأخلاق
                        </Button>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              </div>

              {/* Featured Lecture Section */}
              <div>
                <Card className="border-gray-100 shadow-sm h-full bg-emerald-50 border-emerald-100">
                  <CardContent className="p-4">
                    <div className="flex flex-col items-center text-center">
                      <div className="relative w-full h-32 mb-3 rounded-md overflow-hidden">
                        <Image src="/placeholder.svg?height=200&width=400" alt="محاضرة مميزة" fill className="object-cover" />
                        <div className="absolute inset-0 bg-black/40 flex items-center justify-center">
                          <Play className="h-12 w-12 text-white" />
                        </div>
                      </div>
                      <h3 className="text-lg font-bold mb-2">محاضرة الأسبوع</h3>
                      <p className="text-sm text-gray-600 mb-4">
                        منهج أهل السنة والجماعة في فهم نصوص الكتاب والسنة
                      </p>
                      <Button className="w-full bg-emerald-600 hover:bg-emerald-700">
                        استماع الآن
                      </Button>
                    </div>
                  </CardContent>
                </Card>
              </div>
            </div>

            {/* Lecture Categories */}
            <div className="mb-8">
              <h2 className="text-xl font-bold mb-6 border-r-4 border-emerald-600 pr-3">تصنيفات المحاضرات</h2>
              <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
                {["العقيدة", "الفقه", "التفسير", "الحديث", "السيرة", "التربية", "الأخلاق", "الآداب"].map((category, index) => (
                  <Card key={index} className="border-gray-100 shadow-sm hover:shadow-md transition-shadow overflow-hidden group">
                    <Link href="#">
                      <div className="flex flex-col items-center p-4 text-center">
                        <div className="w-12 h-12 rounded-full bg-emerald-100 flex items-center justify-center mb-3 group-hover:bg-emerald-200 transition-colors">
                          <Tag className="h-6 w-6 text-emerald-600" />
                        </div>
                        <h3 className="font-semibold mb-1">{category}</h3>
                        <p className="text-xs text-gray-500">{(index + 1) * 18} محاضرة</p>
                      </div>
                    </Link>
                  </Card>
                ))}
              </div>
            </div>

            {/* Tabbed Lectures Content */}
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
                    value="lectures"
                    className="data-[state=active]:bg-emerald-600 data-[state=active]:text-white rounded-md px-6"
                  >
                    المحاضرات
                  </TabsTrigger>
                  <TabsTrigger
                    value="talks"
                    className="data-[state=active]:bg-emerald-600 data-[state=active]:text-white rounded-md px-6"
                  >
                    الكلمات
                  </TabsTrigger>
                </TabsList>

                <TabsContent value="all" className="mt-0">
                  <div className="space-y-6">
                    {[1, 2, 3, 4, 5].map((item) => (
                      <Card key={item} className="border-gray-100 shadow-sm hover:shadow-md transition-shadow overflow-hidden">
                        <CardContent className="p-0">
                          <div className="grid grid-cols-1 md:grid-cols-[250px,1fr]">
                            <div className="relative h-48 md:h-full">
                              <Image src="/placeholder.svg?height=200&width=300" alt={`محاضرة ${item}`} fill className="object-cover" />
                              <div className="absolute inset-0 bg-gradient-to-t from-black/70 to-transparent flex items-center justify-center">
                                <Button variant="outline" size="sm" className="rounded-full bg-white/20 border-white/40 text-white hover:bg-white/30 hover:text-white">
                                  <Play className="h-4 w-4 ml-1" />
                                  <span>استماع</span>
                                </Button>
                              </div>
                              <div className="absolute top-2 right-2">
                                <span className="bg-emerald-600 text-white px-2 py-1 rounded text-xs">
                                  {item % 2 === 0 ? "محاضرة" : "كلمة"}
                                </span>
                              </div>
                            </div>
                            <div className="p-5">
                              <div className="flex justify-between items-start mb-3">
                                <div className="bg-emerald-100 px-2 py-1 rounded text-xs text-emerald-700">
                                  {item % 4 === 0 ? "العقيدة" : item % 4 === 1 ? "الفقه" : item % 4 === 2 ? "التفسير" : "الأخلاق"}
                                </div>
                                <div className="flex items-center text-xs text-gray-500">
                                  <Calendar className="h-3.5 w-3.5 ml-1" />
                                  <span>2023/0{item}/15</span>
                                </div>
                              </div>
                              <Link href="#">
                                <h3 className="text-lg font-semibold mb-2 hover:text-emerald-700 transition-colors">
                                  {item % 4 === 0 ? "منهج أهل السنة في فهم النصوص الشرعية" : 
                                  item % 4 === 1 ? "أحكام الصيام وآدابه في شهر رمضان" : 
                                  item % 4 === 2 ? "تفسير سورة الكهف - دروس وعبر" : 
                                  "أخلاق المسلم في التعامل مع غير المسلمين"}
                                </h3>
                              </Link>
                              <p className="text-sm text-gray-600 mb-4 line-clamp-2">
                                {item % 4 === 0 ? "محاضرة تناقش منهجية أهل السنة والجماعة في فهم النصوص الشرعية والتعامل معها..." : 
                                item % 4 === 1 ? "شرح مفصل لأحكام الصيام في رمضان وما يتعلق به من آداب وسنن..." : 
                                item % 4 === 2 ? "دروس مستفادة من قصص سورة الكهف وتطبيقاتها على واقعنا المعاصر..." : 
                                "محاضرة تبين أخلاق المسلم في التعامل مع غير المسلمين في ضوء الكتاب والسنة..."}
                              </p>
                              <div className="flex flex-wrap gap-4 mb-4">
                                <div className="flex items-center text-xs text-gray-500">
                                  <Clock className="h-3.5 w-3.5 ml-1" />
                                  <span>{35 + (item * 8)} دقيقة</span>
                                </div>
                                <div className="flex items-center text-xs text-gray-500">
                                  <Volume2 className="h-3.5 w-3.5 ml-1" />
                                  <span>صوت فقط</span>
                                </div>
                                <div className="flex items-center text-xs text-gray-500">
                                  <Eye className="h-3.5 w-3.5 ml-1" />
                                  <span>{(item * 123) + 340} مشاهدة</span>
                                </div>
                              </div>
                              <div className="flex items-center justify-between">
                                <Button variant="link" className="p-0 h-auto text-emerald-600">
                                  عرض التفاصيل
                                </Button>
                                <div className="flex space-x-2 space-x-reverse">
                                  <Button variant="ghost" size="sm" className="h-8 w-8 p-0 text-gray-500 hover:text-emerald-600 hover:bg-emerald-50">
                                    <BookmarkPlus className="h-4 w-4" />
                                  </Button>
                                  <Button variant="ghost" size="sm" className="h-8 w-8 p-0 text-gray-500 hover:text-emerald-600 hover:bg-emerald-50">
                                    <Share2 className="h-4 w-4" />
                                  </Button>
                                </div>
                              </div>
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

                <TabsContent value="lectures" className="mt-0">
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                    {[1, 2, 3, 4, 5, 6].map((item) => (
                      <Card key={item} className="overflow-hidden border-0 shadow-sm">
                        <div className="relative h-48">
                          <Image src="/placeholder.svg?height=200&width=400" alt="عنوان المحاضرة" fill className="object-cover" />
                          <div className="absolute inset-0 bg-gradient-to-t from-black/70 to-transparent"></div>
                          <div className="absolute bottom-0 right-0 p-4">
                            <span className="bg-emerald-600 text-white px-2 py-1 rounded text-xs">محاضرات</span>
                          </div>
                          <Button variant="outline" size="sm" className="absolute top-2 left-2 rounded-full bg-white/20 border-white/40 text-white hover:bg-white/30 hover:text-white h-8 w-8 p-0">
                            <Play className="h-4 w-4" />
                          </Button>
                        </div>
                        <CardContent className="p-4">
                          <div className="flex items-center text-sm text-gray-500 mb-2">
                            <Calendar className="h-4 w-4 ml-1" />
                            <span>2023/06/{15 + item}</span>
                            <span className="mx-2">•</span>
                            <Clock className="h-4 w-4 ml-1" />
                            <span>{35 + (item * 5)} دقيقة</span>
                          </div>
                          <h3 className="text-lg font-semibold mb-3">أهمية العلم الشرعي - محاضرة {item}</h3>
                          <p className="text-gray-600 text-sm mb-4 line-clamp-2">
                            محاضرة تتناول أهمية طلب العلم الشرعي وكيفية تحصيله والصبر عليه...
                          </p>
                          <div className="flex justify-between items-center">
                            <Link href={`/lecture/${item}`}>
                              <Button variant="link" className="p-0 h-auto text-emerald-600">
                                التفاصيل
                              </Button>
                            </Link>
                            <div className="flex space-x-2 space-x-reverse">
                              <Button variant="ghost" size="icon" className="h-8 w-8 p-0 text-gray-500 hover:text-emerald-600">
                                <BookmarkPlus className="h-4 w-4" />
                              </Button>
                              <Button variant="ghost" size="icon" className="h-8 w-8 p-0 text-gray-500 hover:text-emerald-600">
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
                    </div>
                  </div>
                </TabsContent>

                <TabsContent value="talks" className="mt-0">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    {[1, 2, 3, 4].map((item) => (
                      <Card key={item} className="overflow-hidden border-gray-100 shadow-sm">
                        <CardContent className="p-0">
                          <div className="flex items-start">
                            <div className="relative h-24 w-24 flex-shrink-0">
                              <Image src="/placeholder.svg?height=100&width=100" alt="عنوان الكلمة" fill className="object-cover" />
                              <div className="absolute inset-0 bg-black/30 flex items-center justify-center">
                                <Play className="h-8 w-8 text-white" />
                              </div>
                            </div>
                            <div className="p-4">
                              <div className="flex justify-between">
                                <span className="bg-emerald-100 text-emerald-700 px-2 py-0.5 rounded text-xs mb-2">كلمة</span>
                                <div className="flex items-center text-xs text-gray-500">
                                  <Clock className="h-3.5 w-3.5 ml-1" />
                                  <span>{10 + (item * 2)} دقيقة</span>
                                </div>
                              </div>
                              <h3 className="text-md font-semibold mb-1">كلمة حول {item % 2 === 0 ? "فضل العلم" : "أهمية الصدقة"}</h3>
                              <p className="text-xs text-gray-600 mb-2 line-clamp-2">
                                كلمة قصيرة حول {item % 2 === 0 ? "فضل العلم وأهميته للمسلم..." : "فضل الصدقة وأهميتها في حياة المسلم..."}
                              </p>
                              <div className="flex justify-between">
                                <Button variant="link" className="p-0 h-6 text-xs text-emerald-600">
                                  استماع
                                </Button>
                                <div className="flex gap-1">
                                  <Button variant="ghost" size="sm" className="h-6 w-6 p-0 text-gray-500">
                                    <Share2 className="h-3 w-3" />
                                  </Button>
                                </div>
                              </div>
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
                    </div>
                  </div>
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