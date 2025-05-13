import {
  Breadcrumb,
  BreadcrumbItem,
  BreadcrumbLink,
  BreadcrumbList,
  BreadcrumbSeparator,
} from "@/components/ui/breadcrumb";
import PageSidebar from "@/components/page-sidebar";
import { getAllLectures } from "@/lib/services/lectures-service";
import { SearchBar } from "@/components/search-bar";
import Pagination from "@/components/pagination";
import { LectureCard } from "@/components/lecture-card";

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
  const { meta, lectures } = await getAllLectures(currentPage, query, category);
  const totalPages = meta.total_pages;
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
        <div className="grid grid-cols-1 lg:grid-cols-4 gap-8">

          <div className="lg:col-span-3">
            {/* Page Title with Stats */}
            <div className="mb-8 bg-white p-6 rounded-lg border border-gray-100 shadow-sm">
              <div className="flex flex-col md:flex-row md:items-center md:justify-between mb-4">
                <div>
                  <h1 className="text-3xl font-bold mb-2 text-gray-900">
                    المحاضرات والكلمات
                  </h1>
                  <p className="text-gray-600">
                    تصفح جميع المحاضرات والكلمات للشيخ في مختلف المناسبات
                  </p>
                </div>
              </div>
              <SearchBar categories={meta.categories} />

            </div>

            <div className="space-y-6">
              {lectures.map((lecture, index) => (
                <LectureCard key={index} lecture={lecture} />
              ))}
              {lectures.length === 0 && (
                <div className="text-center py-8">
                  <p className="text-gray-500">لا توجد محاضرات متاحة.</p>
                </div>
              )}
            </div>
            <Pagination totalPages={totalPages} />
          </div>

          {/* Sidebar */}
          <div className="lg:col-span-1">
            <PageSidebar />
          </div>
        </div>
      </div>
    </div>
  );
}
