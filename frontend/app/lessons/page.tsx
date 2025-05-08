"use server";
import { Breadcrumb, BreadcrumbItem, BreadcrumbLink, BreadcrumbList, BreadcrumbSeparator } from "@/components/ui/breadcrumb";
import { Card, CardContent } from "@/components/ui/card";
import PageSidebar from "@/components/page-sidebar";
import { getAllLessons } from "@/lib/services/lessons-service";
import { SearchBar } from "@/components/search-bar";
import { LessonsList } from "@/components/lessons-list";
import Pagination from "@/components/pagination";


export default async function LessonsPage(props: {
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
  const { meta, lessons } = await getAllLessons(currentPage, query, category);
  const totalPages = meta.total_pages;
  return (
    <div className="bg-gray-50 min-h-screen py-8">
      <div className="container mx-auto px-4">
        <Breadcrumb className="mb-4" dir="rtl">
          <BreadcrumbList>
            <BreadcrumbItem>
              <BreadcrumbLink href="/">الرئيسية</BreadcrumbLink>
            </BreadcrumbItem>
            <BreadcrumbSeparator/>
            <BreadcrumbItem>
              <BreadcrumbLink href="/lessons">الدروس العلمية</BreadcrumbLink>
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
              </div>
            </div>

            <div className="mb-6">
              <Card className="border-gray-100 shadow-sm">
                <CardContent className="p-4">
                  <SearchBar categories={meta.categories} />
                  <div className="mt-6 relative overflow-hidden rounded-lg">
                    {lessons.length > 0 ? (
                      <LessonsList lessons={lessons} />
                    ) : (
                      <div className="text-center py-8">
                        <p className="text-gray-500">لا توجد دروس متاحة.</p>
                      </div>
                    )}
                    <Pagination totalPages={totalPages} />
                  </div>
                </CardContent>
              </Card>
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