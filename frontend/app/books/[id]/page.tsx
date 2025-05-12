import { Card, CardContent } from "@/components/ui/card"
import { Calendar, Download } from "lucide-react"
import { formatDate, resourceUrl } from "@/lib/utils"
import {
  Breadcrumb,
  BreadcrumbItem,
  BreadcrumbLink,
  BreadcrumbList,
  BreadcrumbSeparator,
} from "@/components/ui/breadcrumb"
import PageSidebar from "@/components/page-sidebar"
import { getBookById } from "@/lib/services/books-service"
import Link from "next/link"
import Image from "next/image"
import { Button } from "@/components/ui/button"

export default async function BookPage({
  params,
}: {
  params: Promise<{ id: string }>
}) {
  const { id } = await params
  const book = await getBookById(id)

  if (!book) {
    return <div className="container mx-auto px-4 py-8">الكتاب غير موجود</div>
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="mb-6">
        <Breadcrumb className="mb-4">
          <BreadcrumbList>
            <BreadcrumbItem>
              <BreadcrumbLink href="/">الرئيسية</BreadcrumbLink>
            </BreadcrumbItem>
            <BreadcrumbSeparator />
            <BreadcrumbItem>
              <BreadcrumbLink href="/books">الكتب</BreadcrumbLink>
            </BreadcrumbItem>
            <BreadcrumbSeparator />
            <BreadcrumbItem>
              <BreadcrumbLink href={`/books/${book.id}`}>{book.title}</BreadcrumbLink>
            </BreadcrumbItem>
          </BreadcrumbList>
        </Breadcrumb>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
        <div className="md:col-span-2">
          <Card className="overflow-hidden border-0 shadow-md">
            <CardContent className="p-6">
              {/* Book cover image card */}
              {book.cover_image_url && (
                  <div className="aspect-square relative w-full  h-[300px] mb-4">
                    <Image
                      src={resourceUrl(book.cover_image_url)}
                      alt={book.title}
                      fill
                      className="object-cover"
                    />
                  </div>
              )}
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center gap-2">
                  {book.category && (
                    <span className="bg-gray-100 text-gray-800 px-2 py-0.5 rounded text-xs">
                      {book.category}
                    </span>
                  )}
                </div>
              </div>

              <h1 className="text-2xl md:text-3xl font-bold mb-4">{book.title}</h1>

              {book.author && (
                <div className="mb-4">
                  <h2 className="text-lg font-semibold text-gray-700">
                    <span>المؤلف: </span>
                    <Link href={`/authors/${book.author.id}`}>
                      <Button variant="link" className="text-xl">
                        {book.author.first_name} {book.author.last_name}
                      </Button>
                    </Link>
                  </h2>
                </div>
              )}

              <div className="flex flex-wrap items-center gap-4 mb-6 text-sm text-gray-600">
                {book.published_date && (
                  <div className="flex items-center">
                    <Calendar className="h-4 w-4 ml-1" />
                    <span>{formatDate(book.published_date)}</span>
                  </div>
                )}

                {/* Book details */}
                <div className="flex gap-6 flex-wrap">
                  {book.pages && (
                    <div className="flex items-center">
                      <span className="font-medium ml-1">الصفحات:</span>
                      <span>{book.pages}</span>
                    </div>
                  )}

                  {book.volumes && (
                    <div className="flex items-center">
                      <span className="font-medium ml-1">المجلدات:</span>
                      <span>{book.volumes}</span>
                    </div>
                  )}

                  {book.views && (
                    <div className="flex items-center">
                      <span className="font-medium ml-1">المشاهدات:</span>
                      <span>{book.views}</span>
                    </div>
                  )}

                  {book.downloads && (
                    <div className="flex items-center">
                      <span className="font-medium ml-1">التحميلات:</span>
                      <span>{book.downloads}</span>
                    </div>
                  )}
                </div>
              </div>

              <div className="prose max-w-none">
                <div className="text-gray-700 leading-relaxed">
                  {book.description}
                </div>
              </div>

              {/* Download button */}
              {book.file_url && (
                <div className="mt-6">
                  <Button asChild>
                    <a href={book.file_url} download className="flex items-center gap-2">
                      <Download className="h-4 w-4" />
                      <span>تحميل الكتاب</span>
                    </a>
                  </Button>
                </div>
              )}
            </CardContent>
          </Card>
        </div>

        <div className="md:col-span-1">

          <PageSidebar />
        </div>
      </div>
    </div>
  )
}
