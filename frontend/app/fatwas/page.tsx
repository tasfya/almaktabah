import { Breadcrumb, BreadcrumbItem, BreadcrumbLink, BreadcrumbList, BreadcrumbSeparator } from "@/components/ui/breadcrumb"
import { Card, CardContent } from "@/components/ui/card"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Button } from "@/components/ui/button"
import { Copy, Share2, Search, Calendar, Filter, ArrowUpDown, Tag, MessageSquare, Eye, BookmarkPlus } from "lucide-react"
import Link from "next/link"
import Image from "next/image"
import PageSidebar from "@/components/page-sidebar"

export default function FatwasPage() {
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
              <BreadcrumbLink>الفتاوى</BreadcrumbLink>
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
                  <h1 className="text-3xl font-bold mb-2 text-gray-900">الفتاوى</h1>
                  <p className="text-gray-600">فتاوى الشيخ في مختلف المسائل الشرعية</p>
                </div>
                <div className="mt-4 md:mt-0 flex flex-wrap gap-4">
                  <div className="bg-emerald-50 rounded-lg p-3 text-center min-w-[100px]">
                    <span className="block text-2xl font-bold text-emerald-600">1250+</span>
                    <span className="text-xs text-gray-600">فتوى</span>
                  </div>
                  <div className="bg-emerald-50 rounded-lg p-3 text-center min-w-[100px]">
                    <span className="block text-2xl font-bold text-emerald-600">45+</span>
                    <span className="text-xs text-gray-600">باب فقهي</span>
                  </div>
                </div>
              </div>
            </div>

            {/* Search and Questions Section */}
            <div className="grid grid-cols-1 md:grid-cols-[2fr,1fr] gap-6 mb-8">
              {/* Search Section */}
              <div>
                <Card className="border-gray-100 shadow-sm h-full">
                  <CardContent className="p-4">
                    <h2 className="text-lg font-bold mb-4">ابحث في الفتاوى</h2>
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
                          صلاة
                        </Button>
                        <Button variant="outline" size="sm" className="h-7 rounded-full text-xs border-gray-200 hover:border-emerald-200 hover:bg-emerald-50">
                          صيام
                        </Button>
                        <Button variant="outline" size="sm" className="h-7 rounded-full text-xs border-gray-200 hover:border-emerald-200 hover:bg-emerald-50">
                          زكاة
                        </Button>
                        <Button variant="outline" size="sm" className="h-7 rounded-full text-xs border-gray-200 hover:border-emerald-200 hover:bg-emerald-50">
                          حج
                        </Button>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              </div>

              {/* Ask Question Section */}
              <div>
                <Card className="border-gray-100 shadow-sm h-full bg-emerald-50 border-emerald-100">
                  <CardContent className="p-4">
                    <div className="flex flex-col items-center text-center">
                      <MessageSquare className="h-12 w-12 text-emerald-600 mb-3" />
                      <h3 className="text-lg font-bold mb-2">لديك سؤال شرعي؟</h3>
                      <p className="text-sm text-gray-600 mb-4">
                        يمكنك ارسال استفسارك وسيقوم الشيخ بالإجابة عليه قريباً
                      </p>
                      <Button className="w-full bg-emerald-600 hover:bg-emerald-700">
                        اسأل الشيخ
                      </Button>
                    </div>
                  </CardContent>
                </Card>
              </div>
            </div>

            {/* Main Fatwa Categories */}
            <div className="mb-8">
              <h2 className="text-xl font-bold mb-6 border-r-4 border-emerald-600 pr-3">أبواب الفتاوى</h2>
              <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
                {["العقيدة", "الطهارة", "الصلاة", "الزكاة", "الصيام", "الحج", "المعاملات", "الأسرة"].map((category, index) => (
                  <Card key={index} className="border-gray-100 shadow-sm hover:shadow-md transition-shadow overflow-hidden group">
                    <Link href="#">
                      <div className="flex flex-col items-center p-4 text-center">
                        <div className="w-12 h-12 rounded-full bg-emerald-100 flex items-center justify-center mb-3 group-hover:bg-emerald-200 transition-colors">
                          <Tag className="h-6 w-6 text-emerald-600" />
                        </div>
                        <h3 className="font-semibold mb-1">{category}</h3>
                        <p className="text-xs text-gray-500">{(index + 1) * 25} فتوى</p>
                      </div>
                    </Link>
                  </Card>
                ))}
              </div>
            </div>

            {/* Latest Fatwas */}
            <div className="mb-8">
              <Tabs defaultValue="latest" className="w-full">
                <TabsList className="bg-white border rounded-lg p-1 mb-6 w-fit mx-auto">
                  <TabsTrigger
                    value="latest"
                    className="data-[state=active]:bg-emerald-600 data-[state=active]:text-white rounded-md px-6"
                  >
                    أحدث الفتاوى
                  </TabsTrigger>
                  <TabsTrigger
                    value="popular"
                    className="data-[state=active]:bg-emerald-600 data-[state=active]:text-white rounded-md px-6"
                  >
                    الأكثر قراءة
                  </TabsTrigger>
                  <TabsTrigger
                    value="featured"
                    className="data-[state=active]:bg-emerald-600 data-[state=active]:text-white rounded-md px-6"
                  >
                    فتاوى مختارة
                  </TabsTrigger>
                </TabsList>

                <TabsContent value="latest" className="mt-0">
                  <div className="space-y-6">
                    {[1, 2, 3, 4, 5].map((item) => (
                      <Card key={item} className="border-gray-100 shadow-sm hover:shadow-md transition-shadow overflow-hidden">
                        <CardContent className="p-0">
                          <div className="p-6">
                            <div className="flex justify-between items-start mb-3">
                              <div className="bg-emerald-100 px-2 py-1 rounded text-xs text-emerald-700">
                                {item % 3 === 0 ? "العقيدة" : item % 3 === 1 ? "الصلاة" : "المعاملات"}
                              </div>
                              <div className="flex items-center text-xs text-gray-500">
                                <Calendar className="h-3.5 w-3.5 ml-1" />
                                <span>2023/0{item}/15</span>
                              </div>
                            </div>
                            <Link href="#">
                              <h3 className="text-lg font-semibold mb-2 hover:text-emerald-700 transition-colors">
                                {item % 3 === 0 ? "حكم التوسل بالأولياء والصالحين" : 
                                 item % 3 === 1 ? "حكم الجمع بين الصلوات في السفر" : 
                                 "حكم التعامل بالفوائد البنكية"}
                              </h3>
                            </Link>
                            <div className="text-sm text-gray-600 mb-4">
                              <p>
                                {item % 3 === 0 ? 
                                "السؤال: ما حكم التوسل بالأولياء والصالحين ودعائهم من دون الله عز وجل؟" : 
                                item % 3 === 1 ? 
                                "السؤال: هل يجوز الجمع بين الصلوات في السفر حتى لو كان السفر مريحاً؟" : 
                                "السؤال: ما حكم التعامل مع البنوك التي تتعامل بالفوائد الربوية؟"}
                              </p>
                            </div>
                            <div className="flex items-center justify-between">
                              <div className="flex items-center space-x-4 space-x-reverse">
                                <div className="flex items-center text-xs text-gray-500">
                                  <Eye className="h-3.5 w-3.5 ml-1" />
                                  <span>{(item * 123) + 340} مشاهدة</span>
                                </div>
                                <div className="flex items-center text-xs text-gray-500">
                                  <MessageSquare className="h-3.5 w-3.5 ml-1" />
                                  <span>{item * 2} تعليق</span>
                                </div>
                              </div>
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
                          <div className="border-t p-4 bg-gray-50">
                            <div className="flex items-start gap-3">
                              <div className="w-6 h-6 rounded-full bg-emerald-100 flex items-center justify-center flex-shrink-0">
                                <MessageSquare className="h-3 w-3 text-emerald-600" />
                              </div>
                              <div>
                                <h4 className="font-medium text-sm mb-1">الجواب:</h4>
                                <p className="text-sm text-gray-700 line-clamp-2">
                                  {item % 3 === 0 ? 
                                  "لا يجوز التوسل بالأولياء والصالحين ودعاؤهم من دون الله، فهذا من الشرك الذي نهى الله عنه..." : 
                                  item % 3 === 1 ? 
                                  "نعم، يجوز الجمع بين الصلوات في السفر مطلقاً سواء كان السفر مريحاً أم لا، وهذه رخصة من الله..." : 
                                  "التعامل مع البنوك التي تتعامل بالفوائد الربوية محرم شرعاً، والربا من كبائر الذنوب..."}
                                </p>
                                <Button variant="link" className="p-0 h-6 text-emerald-600 text-xs">
                                  اقرأ الإجابة كاملة
                                </Button>
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

                <TabsContent value="popular" className="mt-0">
                  <div className="text-center py-10 text-gray-500">الفتاوى الأكثر قراءة</div>
                </TabsContent>

                <TabsContent value="featured" className="mt-0">
                  <div className="text-center py-10 text-gray-500">الفتاوى المختارة</div>
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
