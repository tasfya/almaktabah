import { Breadcrumb, BreadcrumbItem, BreadcrumbLink, BreadcrumbList, BreadcrumbSeparator } from "@/components/ui/breadcrumb"
import { Card, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Search, Book, FileText, Download, Bookmark, Star, Filter, ArrowUpDown, ChevronLeft, ChevronRight } from "lucide-react"
import Link from "next/link"
import Image from "next/image"
import PageSidebar from "@/components/page-sidebar"

export default function BooksPage() {
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
              <BreadcrumbLink>الكتب</BreadcrumbLink>
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
                  <h1 className="text-3xl font-bold mb-2 text-gray-900">الكتب والمؤلفات</h1>
                  <p className="text-gray-600">تصفح مؤلفات وكتب الشيخ</p>
                </div>
                <div className="mt-4 md:mt-0 flex flex-wrap gap-4">
                  <div className="bg-emerald-50 rounded-lg p-3 text-center min-w-[100px]">
                    <span className="block text-2xl font-bold text-emerald-600">75+</span>
                    <span className="text-xs text-gray-600">كتاب ومؤلف</span>
                  </div>
                  <div className="bg-emerald-50 rounded-lg p-3 text-center min-w-[100px]">
                    <span className="block text-2xl font-bold text-emerald-600">120K+</span>
                    <span className="text-xs text-gray-600">تحميل</span>
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
                        placeholder="ابحث في الكتب والمؤلفات..."
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
            
            {/* Featured Books Carousel */}
            <div className="mb-8">
              <div className="bg-white p-6 rounded-lg border border-gray-100 shadow-sm">
                <h2 className="text-xl font-bold mb-6 border-r-4 border-emerald-600 pr-3">أحدث الإصدارات</h2>
                <div className="relative">
                  <div className="flex gap-6 overflow-x-auto pb-4 scrollbar-hide">
                    {[1, 2, 3, 4, 5].map((item) => (
                      <div key={item} className="flex-shrink-0 w-[180px]">
                        <div className="group">
                          <div className="relative h-64 w-44 mb-3 mx-auto">
                            <Image 
                              src="/placeholder.svg?height=256&width=176" 
                              alt={`كتاب ${item}`} 
                              width={176}
                              height={256}
                              className="object-cover shadow-md group-hover:shadow-lg transition-shadow rounded"
                            />
                            <div className="absolute top-2 right-2">
                              {item === 1 && <span className="bg-emerald-600 text-white px-2 py-1 rounded text-xs">جديد</span>}
                            </div>
                            <div className="absolute bottom-2 right-2">
                              <Button variant="ghost" size="icon" className="h-8 w-8 bg-white/90 text-emerald-600 hover:bg-white">
                                <Bookmark className="h-4 w-4" />
                              </Button>
                            </div>
                          </div>
                          <h3 className="font-semibold text-center mb-1">شرح كتاب التوحيد {item}</h3>
                          <div className="flex justify-center items-center mb-2">
                            {[1, 2, 3, 4, 5].map((star) => (
                              <Star 
                                key={star} 
                                className={`h-4 w-4 ${star <= 4 ? 'text-amber-400 fill-amber-400' : 'text-gray-300'}`} 
                              />
                            ))}
                            <span className="text-xs text-gray-500 mr-1">(4.8)</span>
                          </div>
                          <div className="flex justify-center gap-2">
                            <Button size="sm" className="bg-emerald-600 hover:bg-emerald-700 px-2 py-1 h-8">عرض</Button>
                            <Button size="sm" variant="outline" className="border-emerald-200 text-emerald-700 hover:bg-emerald-50 px-2 py-1 h-8">
                              <Download className="h-3 w-3 ml-1" />
                              PDF
                            </Button>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                  <Button variant="ghost" size="icon" className="h-10 w-10 bg-white/80 hover:bg-white text-gray-700 rounded-full absolute top-1/2 right-0 transform -translate-y-1/2 shadow-sm">
                    <ChevronRight className="h-5 w-5" />
                  </Button>
                  <Button variant="ghost" size="icon" className="h-10 w-10 bg-white/80 hover:bg-white text-gray-700 rounded-full absolute top-1/2 left-0 transform -translate-y-1/2 shadow-sm">
                    <ChevronLeft className="h-5 w-5" />
                  </Button>
                </div>
              </div>
            </div>

            {/* Book Series Section */}
            <div className="mb-8">
              <div className="bg-white p-6 rounded-lg border border-gray-100 shadow-sm">
                <h2 className="text-xl font-bold mb-6 border-r-4 border-emerald-600 pr-3">سلاسل الكتب</h2>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  {[1, 2, 3, 4].map((item) => (
                    <Card key={item} className="border-gray-100 shadow-sm hover:shadow-md transition-shadow overflow-hidden group">
                      <div className="flex">
                        <div className="relative w-24 h-32 flex-shrink-0">
                          <Image 
                            src="/placeholder.svg?height=128&width=96" 
                            alt={`سلسلة ${item}`} 
                            width={96}
                            height={128}
                            className="object-cover group-hover:scale-105 transition-transform"
                          />
                        </div>
                        <CardContent className="p-4 flex-1">
                          <h3 className="font-semibold mb-1">سلسلة شرح العقيدة الطحاوية</h3>
                          <p className="text-sm text-gray-600 mb-2 line-clamp-2">
                            مجموعة من الكتب تشرح العقيدة الطحاوية بأسلوب ميسر وشامل.
                          </p>
                          <div className="flex items-center text-xs text-gray-500 mb-2">
                            <Book className="h-3 w-3 ml-1" />
                            <span>{item + 2} كتب</span>
                          </div>
                          <Button size="sm" className="bg-emerald-600 hover:bg-emerald-700 text-xs h-7">تصفح السلسلة</Button>
                        </CardContent>
                      </div>
                    </Card>
                  ))}
                </div>
              </div>
            </div>

            {/* Books Grid */}
            <div className="mb-8">
              <h2 className="text-xl font-bold mb-6 border-r-4 border-emerald-600 pr-3">جميع الكتب</h2>
              <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
                {/* Book Cards - Would map over books array in production */}
                {[1, 2, 3, 4, 5, 6, 7, 8].map((item) => (
                  <Card key={item} className="overflow-hidden border-gray-100 shadow-sm hover:shadow-md transition-shadow flex flex-col h-full">
                    <div className="aspect-[3/4] relative">
                      <Image 
                        src="/placeholder.svg?height=400&width=300" 
                        alt={`كتاب ${item}`} 
                        fill 
                        className="object-cover"
                      />
                    </div>
                    <CardContent className="p-4 flex-1 flex flex-col justify-between">
                      <div>
                        <h3 className="text-md font-semibold mb-2 line-clamp-1">كتاب التوحيد {item}</h3>
                        <div className="flex items-center text-xs text-gray-500 mb-3">
                          <Book className="h-3 w-3 ml-1" />
                          <span>320 صفحة</span>
                        </div>
                      </div>
                      <div className="flex flex-col space-y-2">
                        <Link href={`/book/${item}`}>
                          <Button className="w-full justify-center bg-emerald-600 hover:bg-emerald-700 text-xs h-8">
                            <Book className="h-3 w-3 ml-2" />
                            تصفح الكتاب
                          </Button>
                        </Link>
                        <Button variant="outline" className="w-full justify-center text-xs h-8 border-emerald-200 text-emerald-700 hover:bg-emerald-50">
                          <Download className="h-3 w-3 ml-2" />
                          تحميل PDF
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