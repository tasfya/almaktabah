import { Breadcrumb, BreadcrumbItem, BreadcrumbLink, BreadcrumbList, BreadcrumbSeparator } from "@/components/ui/breadcrumb"
import { Card, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { MessageSquare } from "lucide-react"
import PageSidebar from "@/components/page-sidebar"
import { getAllFatwas } from "@/lib/services/fatwas-service"
import { SearchBar } from "@/components/search-bar"
import Pagination from "@/components/pagination"
import { FatwaCard } from "@/components/fatwa-card"

export default async function FatwasPage(props: {
  searchParams?: Promise<{
    query?: string;
    page?: string;
    category?: string;
    sort?: string;

  }>;
}) {
  const searchParams = await props.searchParams;
  const query = searchParams?.query || '';
  const currentPage = Number(searchParams?.page) || 1;
  const category = searchParams?.category || '';
  const sort = searchParams?.sort || 'created_at';
  const { meta, fatwas } = await getAllFatwas(currentPage, query, category);
  const totalPages = meta.total_pages;
  return (
    <div className="bg-gray-50 min-h-screen py-8">
      <div className="container mx-auto px-4">
        {/* Breadcrumb */}
        <Breadcrumb className="mb-4"  dir="rtl">
          <BreadcrumbList>
            <BreadcrumbItem>
              <BreadcrumbLink href="/">الرئيسية</BreadcrumbLink>
            </BreadcrumbItem>
            <BreadcrumbSeparator />
            <BreadcrumbItem>
              <BreadcrumbLink href="/fatwas">الفتاوى</BreadcrumbLink>
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

              </div>
              <SearchBar categories={[]} />
              <Card className="border-gray-100 shadow-sm h-full">
                <CardContent className="p-4">
                  <div className="flex flex-col items-center text-center">
                    <MessageSquare className="h-12 w-12 text-primary mb-3" />
                    <h3 className="text-lg font-bold mb-2">لديك سؤال شرعي؟</h3>
                    <p className="text-sm text-gray-600 mb-4">
                      يمكنك ارسال استفسارك وسيقوم الشيخ بالإجابة عليه قريباً
                    </p>
                    <Button className="w-full">
                      اسأل الشيخ
                    </Button>
                  </div>
                </CardContent>
              </Card>
            </div>


            {/* Latest Fatwas */}
            <div className="mb-8">
              <div className="space-y-6">
                {fatwas.map((fatwa) => (
                  <FatwaCard key={fatwa.id} fatwa={fatwa} />
                ))}
              </div>
              <Pagination totalPages={totalPages} />
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