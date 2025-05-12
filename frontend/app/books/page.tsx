import { Breadcrumb, BreadcrumbItem, BreadcrumbLink, BreadcrumbList, BreadcrumbSeparator } from "@/components/ui/breadcrumb"
import { Card, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Search, Book, FileText, Download, Bookmark, Star, Filter, ArrowUpDown, ChevronLeft, ChevronRight, Eye } from "lucide-react"
import Link from "next/link"
import Image from "next/image"
import PageSidebar from "@/components/page-sidebar"
import { getAllBooks } from "@/lib/services/books-service"
import { resourceUrl } from "@/lib/utils"
import Pagination from "@/components/pagination"
import { SearchBar } from "@/components/search-bar"
export default async function BooksPage(props: {
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
  const { meta, books } = await getAllBooks(currentPage, query, category);
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
              <BreadcrumbLink href="/books">الكتب</BreadcrumbLink>
            </BreadcrumbItem>
          </BreadcrumbList>
        </Breadcrumb>

        <div className="grid grid-cols-1 lg:grid-cols-4 gap-8">
          <div className="lg:col-span-3">
            <div className="mb-8 bg-white p-6 rounded-lg border border-gray-100 shadow-sm">
              <div className="flex flex-col md:flex-row md:items-center md:justify-between mb-4">
                <div>
                  <h1 className="text-3xl font-bold mb-2 text-gray-900">الكتب والمؤلفات</h1>
                  <p className="text-gray-600">تصفح مؤلفات وكتب الشيخ</p>
                </div>
              </div>
              <SearchBar categories={meta.categories} />
            </div>


            <div className="mb-8">
              <h2 className="text-xl font-bold mb-6 border-r-4 border-primary pr-3">جميع الكتب</h2>
              <div className="grid grid-cols-2 md:grid-cols-3 gap-6">
                {books.length === 0 && (
                  <div className="col-span-4 text-center">
                    <p className="text-gray-500">لا توجد كتب متاحة حالياً.</p>
                  </div>
                )}
                {books.map((book) => (
                  <Card key={book.id} className="overflow-hidden border-gray-100 shadow-sm hover:shadow-md transition-shadow flex flex-col h-full">
                    <div className="aspect-square relative">
                      <Image
                        src={resourceUrl(book.cover_image_url)}
                        alt={book.title}
                        fill
                        className="object-cover"
                      />
                    </div>
                    <CardContent className="p-4 flex-1 flex flex-col justify-between">
                      <div>
                        <h3 className="text-md font-semibold mb-2 line-clamp-1">{book.title}</h3>
                        <div className="flex items-center text-xs text-gray-500 mb-3 gap-1">
                          <Book className="h-3 w-3" />
                          <span>{book.pages} صفحة</span>
                        </div>

                        <div className="flex items-center text-xs text-gray-500 mb-3 gap-1">
                          <FileText className="h-3 w-3" />
                          <span>{book.category}</span>
                        </div>
                        <div className="flex items-center text-xs text-gray-500 mb-3 gap-1">
                          <Eye className="h-3 w-3" />
                          <span>{book.views} مشاهدة</span>
                        </div>
                      </div>
                      <div className="flex flex-col space-y-2">
                        <Link href={`/books/${book.id}`}>
                          <Button className="w-full justify-center ">
                            <Book className="h-3 w-3 ml-2" />
                            تصفح الكتاب
                          </Button>
                        </Link>
                        <a href={resourceUrl(book.file_url)} download target="_blank">
                          <Button variant="outline" className="w-full justify-center">
                            <Download className="h-3 w-3 ml-2" />
                            تحميل PDF
                          </Button>
                        </a>
                      </div>
                    </CardContent>
                  </Card>
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