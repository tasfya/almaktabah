import { Breadcrumb, BreadcrumbItem, BreadcrumbLink, BreadcrumbList, BreadcrumbSeparator } from "@/components/ui/breadcrumb"
import { Card, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Search, MessageSquare, Calendar, ThumbsUp, Reply, Filter, ArrowUpDown } from "lucide-react"
import Link from "next/link"
import Image from "next/image"
import PageSidebar from "@/components/page-sidebar"

export default function CommentsPage() {
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
              <BreadcrumbLink href="/comments">التعليقات</BreadcrumbLink>
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
                  <h1 className="text-3xl font-bold mb-2 text-gray-900">التعليقات</h1>
                  <p className="text-gray-600">أسئلة وتعليقات الزوار على محتويات الموقع</p>
                </div>
                <div className="mt-4 md:mt-0 flex flex-wrap gap-4">
                  <div className="bg-emerald-50 rounded-lg p-3 text-center min-w-[100px]">
                    <span className="block text-2xl font-bold text-emerald-600">245+</span>
                    <span className="text-xs text-gray-600">تعليق</span>
                  </div>
                  <div className="bg-emerald-50 rounded-lg p-3 text-center min-w-[100px]">
                    <span className="block text-2xl font-bold text-emerald-600">180+</span>
                    <span className="text-xs text-gray-600">رد</span>
                  </div>
                </div>
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
                        placeholder="ابحث في التعليقات..."
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
                    value="questions"
                    className="data-[state=active]:bg-emerald-600 data-[state=active]:text-white rounded-md px-6"
                  >
                    الأسئلة
                  </TabsTrigger>
                  <TabsTrigger
                    value="comments"
                    className="data-[state=active]:bg-emerald-600 data-[state=active]:text-white rounded-md px-6"
                  >
                    التعليقات
                  </TabsTrigger>
                  <TabsTrigger
                    value="responses"
                    className="data-[state=active]:bg-emerald-600 data-[state=active]:text-white rounded-md px-6"
                  >
                    الردود
                  </TabsTrigger>
                </TabsList>

                <TabsContent value="all" className="mt-0">
                  <div className="space-y-6">
                    {/* Comment Cards - Would map over comments array in production */}
                    {[1, 2, 3, 4, 5].map((item) => (
                      <Card key={item} className="border-gray-100 shadow-sm hover:shadow-md transition-shadow">
                        <CardContent className="p-6">
                          <div className="flex gap-4">
                            <div className="flex-shrink-0">
                              <Image
                                src="/placeholder.svg?height=50&width=50"
                                alt="صورة المستخدم"
                                width={50}
                                height={50}
                                className="rounded-full border-2 border-emerald-100"
                              />
                            </div>
                            <div className="flex-1">
                              <div className="flex justify-between mb-2">
                                <h3 className="font-semibold text-gray-900">أحمد محمد</h3>
                                <div className="flex items-center text-xs text-gray-500">
                                  <Calendar className="h-3 w-3 ml-1" />
                                  <span>2023/07/15</span>
                                </div>
                              </div>
                              <div className="mb-3">
                                <p className="text-gray-700 text-sm">
                                  {item % 2 === 0 ? (
                                    "جزاك الله خيراً شيخنا الفاضل على هذه الفائدة القيمة. أحسن الله إليك وبارك في علمك وعمرك."
                                  ) : (
                                    "هل يمكن توضيح مسألة حكم صيام الست من شوال بعد قضاء رمضان؟ وجزاكم الله خيراً."
                                  )}
                                </p>
                              </div>
                              <div className="flex justify-between items-center">
                                <div className="text-xs text-gray-500">
                                  تعليق على: <Link href="#" className="text-emerald-600 hover:underline">شرح كتاب التوحيد - الدرس {item}</Link>
                                </div>
                                <div className="flex gap-3">
                                  <Button variant="ghost" size="sm" className="h-8 flex gap-1 items-center text-gray-600 hover:text-emerald-600 hover:bg-emerald-50">
                                    <ThumbsUp className="h-4 w-4" />
                                    <span>{12 + item}</span>
                                  </Button>
                                  <Button variant="ghost" size="sm" className="h-8 flex gap-1 items-center text-gray-600 hover:text-emerald-600 hover:bg-emerald-50">
                                    <Reply className="h-4 w-4" />
                                    <span>رد</span>
                                  </Button>
                                </div>
                              </div>

                              {/* Sample reply - only show for odd items */}
                              {item % 2 !== 0 && (
                                <div className="mt-4 pr-6 border-r-2 border-emerald-200">
                                  <div className="flex gap-3">
                                    <div className="flex-shrink-0">
                                      <Image
                                        src="/placeholder.svg?height=40&width=40"
                                        alt="صورة الشيخ"
                                        width={40}
                                        height={40}
                                        className="rounded-full border-2 border-emerald-100"
                                      />
                                    </div>
                                    <div className="flex-1">
                                      <div className="flex justify-between mb-1">
                                        <h4 className="font-semibold text-sm text-emerald-700">الشيخ عبدالعزيز الراجحي</h4>
                                        <div className="flex items-center text-xs text-gray-500">
                                          <Calendar className="h-3 w-3 ml-1" />
                                          <span>2023/07/16</span>
                                        </div>
                                      </div>
                                      <p className="text-gray-700 text-sm">
                                        نعم، الأفضل أن يبدأ بقضاء ما عليه من رمضان ثم يصوم الست من شوال، لكن لو صام الست قبل القضاء فصيامها صحيح، ويحصل له أجر صيام التطوع، والله أعلم.
                                      </p>
                                      <div className="flex justify-end mt-2">
                                        <Button variant="ghost" size="sm" className="h-7 flex gap-1 items-center text-emerald-600 hover:bg-emerald-50 text-xs">
                                          <ThumbsUp className="h-3 w-3" />
                                          <span>شكر الشيخ</span>
                                        </Button>
                                      </div>
                                    </div>
                                  </div>
                                </div>
                              )}
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

                <TabsContent value="questions" className="mt-0">
                  <div className="text-center py-10 text-gray-500">الأسئلة</div>
                </TabsContent>

                <TabsContent value="comments" className="mt-0">
                  <div className="text-center py-10 text-gray-500">التعليقات</div>
                </TabsContent>

                <TabsContent value="responses" className="mt-0">
                  <div className="text-center py-10 text-gray-500">الردود</div>
                </TabsContent>
              </Tabs>
            </div>

            {/* Add Comment Section */}
            <div className="mt-8">
              <Card className="border-gray-100 shadow-sm">
                <CardContent className="p-6">
                  <div className="flex items-center mb-4">
                    <MessageSquare className="h-5 w-5 text-emerald-600 mr-2" />
                    <h3 className="text-xl font-bold">إضافة تعليق جديد</h3>
                  </div>
                  <form className="space-y-4">
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      <div>
                        <label className="block text-sm font-medium mb-1">الاسم</label>
                        <input
                          type="text"
                          className="w-full p-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-emerald-200 focus:border-emerald-300"
                          placeholder="أدخل اسمك الكامل"
                        />
                      </div>
                      <div>
                        <label className="block text-sm font-medium mb-1">البريد الإلكتروني</label>
                        <input
                          type="email"
                          className="w-full p-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-emerald-200 focus:border-emerald-300"
                          placeholder="أدخل بريدك الإلكتروني"
                        />
                      </div>
                    </div>
                    <div>
                      <label className="block text-sm font-medium mb-1">التعليق</label>
                      <textarea
                        className="w-full p-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-emerald-200 focus:border-emerald-300"
                        rows={4}
                        placeholder="أدخل تعليقك"
                      ></textarea>
                    </div>
                    <div>
                      <Button className="bg-emerald-600 hover:bg-emerald-700">إرسال التعليق</Button>
                    </div>
                  </form>
                </CardContent>
              </Card>
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