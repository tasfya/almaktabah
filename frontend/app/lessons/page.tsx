"use server";
import { Breadcrumb, BreadcrumbItem, BreadcrumbLink, BreadcrumbList, BreadcrumbSeparator } from "@/components/ui/breadcrumb";
import { Card, CardContent } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Search, Filter, ArrowUpDown, Play, PlusCircle } from "lucide-react";
import Image from "next/image";
import PageSidebar from "@/components/page-sidebar";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import Link from "next/link";
import { formatDate } from "@/lib/utils";
import { Clock, BookMarked } from "lucide-react";
import { lessons } from "@/lib/data";


export default async function LessonsPage() {
  const lessonsGroupedByCat = {
    "الفقه": [
      {
        id: 1,
        title: "شرح كتاب الطهارة",
        description: "درس تفصيلي في أحكام الطهارة والوضوء",
        coverImage: "/placeholder.svg",
        category: "الفقه",
        duration: "45 دقيقة",
        createdAt: "2024-01-15"
      },
      {
        id: 2,
        title: "شرح كتاب الصلاة",
        description: "درس في أحكام الصلاة وشروطها",
        coverImage: "/placeholder.svg",
        category: "الفقه",
        duration: "50 دقيقة",
        createdAt: "2024-01-16"
      }
    ],
    "العقيدة": [
      {
        id: 3,
        title: "شرح العقيدة الواسطية",
        description: "درس في شرح العقيدة الواسطية لشيخ الإسلام ابن تيمية",
        coverImage: "/placeholder.svg",
        category: "العقيدة",
        duration: "60 دقيقة",
        createdAt: "2024-01-17"
      }
    ],
    "التفسير": [
      {
        id: 4,
        title: "تفسير سورة الفاتحة",
        description: "درس في تفسير سورة الفاتحة",
        coverImage: "/placeholder.svg",
        category: "التفسير",
        duration: "40 دقيقة",
        createdAt: "2024-01-18"
      }
    ]
  };
  
  const categories = Object.keys(lessonsGroupedByCat);
  
  return (
    <div className="bg-gray-50 min-h-screen py-8">
      <div className="container mx-auto px-4">
        <Breadcrumb className="mb-4">
          <BreadcrumbList>
            <BreadcrumbItem>
              <BreadcrumbLink href="/">الرئيسية</BreadcrumbLink>
            </BreadcrumbItem>
            <BreadcrumbSeparator />
            <BreadcrumbItem>
              <BreadcrumbLink>الدروس العلمية</BreadcrumbLink>
            </BreadcrumbItem>
          </BreadcrumbList>
        </Breadcrumb>

        <div className="grid grid-cols-1 lg:grid-cols-4 gap-8">
          <div className="lg:col-span-3">
            <div className="mb-8 bg-white p-6 rounded-lg border border-gray-100 shadow-sm">
              <div className="flex flex-col md:flex-row md:items-center md:justify-between mb-4">
                <div>
                  <h1 className="text-3xl font-bold mb-2 text-gray-900">الدروس العلمية</h1>
                  <p className="text-gray-600">تصفح جميع الدروس العلمية للشيخ</p>
                </div>
                <div className="mt-4 md:mt-0 flex flex-wrap gap-4">
                  <div className="bg-emerald-50 rounded-lg p-3 text-center min-w-[100px]">
                    <span className="block text-2xl font-bold text-emerald-600">350+</span>
                    <span className="text-xs text-gray-600">درس علمي</span>
                  </div>
                  <div className="bg-emerald-50 rounded-lg p-3 text-center min-w-[100px]">
                    <span className="block text-2xl font-bold text-emerald-600">20+</span>
                    <span className="text-xs text-gray-600">سلسلة علمية</span>
                  </div>
                  <div className="bg-emerald-50 rounded-lg p-3 text-center min-w-[100px]">
                    <span className="block text-2xl font-bold text-emerald-600">15K+</span>
                    <span className="text-xs text-gray-600">مستمع</span>
                  </div>
                </div>
              </div>
            </div>

            <div className="mb-6">
              <Card className="border-gray-100 shadow-sm">
                <CardContent className="p-4">
                  <div className="grid grid-cols-1 md:grid-cols-[1fr,auto] gap-4">
                    <div className="relative">
                      <input
                        type="search"
                        placeholder="ابحث في الدروس العلمية..."
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

                  <div className="mt-6 relative overflow-hidden rounded-lg">
                    <div className="relative h-48 md:h-64">
                      <Image
                        src="/placeholder.svg?height=300&width=800"
                        alt="سلسلة مميزة"
                        fill
                        className="object-cover"
                      />
                      <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/50 to-transparent"></div>
                      <div className="absolute bottom-0 right-0 p-6 text-white">
                        <span className="bg-emerald-600 text-white px-2 py-1 rounded text-xs mb-3 inline-block">سلسلة مميزة</span>
                        <h2 className="text-2xl font-bold mb-2">شرح كتاب التوحيد</h2>
                        <p className="text-gray-200 mb-3 max-w-xl">
                          سلسلة دروس في شرح كتاب التوحيد للإمام محمد بن عبد الوهاب، يتناول فيها الشيخ أهم مسائل العقيدة.
                        </p>
                        <div className="flex gap-3">
                          <Button className="bg-white text-emerald-700 hover:bg-gray-100">
                            <Play className="h-4 w-4 ml-2" />
                            مشاهدة السلسلة
                          </Button>
                          <Button variant="outline" className="text-black hover:text-emerald-600 border-gray-200 hover:bg-gray-50">
                            <PlusCircle className="h-4 w-4 ml-2" />
                            اشترك في السلسلة
                          </Button>
                        </div>
                      </div>
                    </div>
                  </div>
                </CardContent>
              </Card>
            </div>

            <div className="mb-8">
              <Tabs className="w-full" defaultValue={"الفقه"} dir="rtl">
                <TabsList className="bg-white border rounded-lg p-1 mb-6 w-fit mx-auto">
                  {Object.keys(lessonsGroupedByCat).map((cat) => (
                    <TabsTrigger
                      key={cat}
                      value={cat}
                      className="data-[state=active]:bg-emerald-600 data-[state=active]:text-white rounded-md px-6"
                    >
                      {cat}
                    </TabsTrigger>
                  ))}
                </TabsList>

                {Object.entries(lessonsGroupedByCat).map(([category, lessons]) => (
                  <TabsContent key={category} value={category} className="mt-0">
                    <div className="mb-8">
                      <h3 className="text-xl font-bold mb-4 border-r-4 border-emerald-600 pr-3">
                        {category}
                      </h3>
                      {lessons.length === 0 ? (
                        <p className="text-gray-500">No lessons available for this category.</p>
                      ) : (
                        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-2 gap-6">
                          {lessons.map(lesson => (
                            <Card key={lesson.id} className="overflow-hidden border-0 shadow-sm group hover:shadow-md transition-shadow">
                              <div className="grid grid-cols-1 md:grid-cols-[120px,1fr] gap-4">
                                <div className="relative h-28 w-full md:h-full">
                                  <Image
                                    src={lesson.coverImage || "/placeholder.svg?height=150&width=150"}
                                    alt={lesson.title || "Cover Image"}
                                    fill
                                    className="object-cover"
                                  />
                                </div>
                                <div className="p-4 pt-0 md:pt-4 flex flex-col h-full">
                                  <div className="flex justify-between items-start mb-2">
                                    <span className="bg-emerald-100 text-emerald-700 text-xs px-2 py-1 rounded-full">
                                      {category}
                                    </span>
                                    <Button variant="ghost" size="icon" className="h-8 w-8">
                                      <BookMarked className="h-4 w-4 text-gray-500" />
                                    </Button>
                                  </div>
                                  <Link href={`/lessons/${lesson.id}`} className="mb-2 block">
                                    <h3 className="font-bold text-lg group-hover:text-emerald-600 line-clamp-2">
                                      {lesson.title}
                                    </h3>
                                  </Link>
                                  <p className="text-sm text-gray-500 line-clamp-2 mb-2">
                                    {lesson.description}
                                  </p>
                                  <div className="mt-auto flex items-center text-xs text-gray-400 gap-3">
                                    <span className="flex items-center">
                                      <Clock className="h-3 w-3 ml-1" />
                                      {lesson.createdAt && formatDate(new Date(lesson.createdAt))}
                                    </span>
                                    <span>{lesson.duration}</span>
                                  </div>
                                </div>
                              </div>
                            </Card>
                          ))}
                        </div>
                      )}
                    </div>

                    {categories.length > 0 && (
                      <div className="flex justify-center mt-8">
                        <div className="flex gap-1">
                          <Button variant="outline" size="sm" className="h-8 w-8 p-0">1</Button>
                          <Button variant="ghost" size="sm" className="h-8 w-8 p-0">2</Button>
                          <Button variant="ghost" size="sm" className="h-8 w-8 p-0">3</Button>
                          <Button variant="ghost" size="sm" className="h-8 w-8 p-0">4</Button>
                          <Button variant="ghost" size="sm" className="h-8 w-8 p-0">5</Button>
                        </div>
                      </div>
                    )}
                  </TabsContent>
                ))}
              </Tabs>
            </div>
          </div>

          <div className="lg:col-span-1">
            <PageSidebar />
          </div>
        </div>
      </div>
    </div>
  );
}