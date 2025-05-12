import Image from "next/image"
import { Card, CardContent, CardHeader, CardTitle, CardFooter } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { ExternalLink, Mail, BookOpen, Download } from "lucide-react"
import Link from "next/link"
import SocialLinks from "./social-links"
import { getMostDownloadedBooks, getMostViewedBooks } from "@/lib/services/books-service"
import { resourceUrl } from "@/lib/utils"
import { books } from "@/lib/data"


export default async function PageSidebar() {
  const [mostVisitedBooks, mostDownloadedBooks] = await Promise.all([
    getMostViewedBooks(),
    getMostDownloadedBooks()
  ]);
  return (
    <div className="space-y-6">
      {/* Sheikh Info Card */}
      <Card className="border border-gray-100 shadow-sm overflow-hidden">
        <CardContent className="pt-4">
          <div className="flex flex-col items-center text-center">
            <div className="relative mb-4">
              <Image
                src="/logo.png?height=300&width=300"
                alt="الشيخ"
                width={300}
                height={300}
                className="rounded-full"
              />
            </div>
            <div className="flex gap-2 w-full justify-center">
              <Button asChild>
                <Link href="/about">
                  <span className="flex items-center justify-center gap-1">
                    <ExternalLink className="h-3.5 w-3.5 ml-1" />
                    عن الشيخ
                  </span>
                </Link>
              </Button>
              <Button variant="outline" asChild>
                <Link href="/about">
                  <span className="flex items-center justify-center gap-1">
                    <Mail className="h-3.5 w-3.5 ml-1" />
                    تواصل
                  </span>
                </Link>
              </Button>
            </div>
          </div>
        </CardContent>
        <CardFooter className="flex justify-center py-2">
          <SocialLinks />
        </CardFooter>
      </Card>

      {/* Most Downloaded Books */}
      <Card className="border border-gray-100 shadow-sm">
        <CardHeader className="pb-2">
          <CardTitle className="text-lg text-primary">الكتب الأكثر تحميلاً</CardTitle>
        </CardHeader>
        <CardContent className="pt-4">
          <div className="space-y-3">
            {mostDownloadedBooks.map((book) => (
              <div key={book.id} className="flex items-center gap-3 pb-3 border-b border-gray-100 last:border-0 last:pb-0">
                <div className="flex-1">
                  <h4 className="font-medium text-sm mb-1 line-clamp-1">
                    {book.title}
                  </h4>
                  <div className="flex items-center text-xs text-gray-500 mb-2 gap-1">
                    <Download className="h-3 w-3" />
                    <span>{book.downloads} تحميل</span>
                  </div>
                  <Link href={resourceUrl(book.file_url)} download target="_blank">
                    <Button variant="outline">
                      <Download className="h-3 w-3" />
                      تحميل
                    </Button>
                  </Link>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Most Visited Content */}
      <Card className="border border-gray-100 shadow-sm">
        <CardHeader className="pb-2">
          <CardTitle className="text-lg text-primary">المحتوى الأكثر زيارة</CardTitle>
        </CardHeader>
        <CardContent className="pt-4">
          <div className="space-y-3">
            {mostVisitedBooks.map((book, index) => (
              <Link key={book.id} href={`/books/${book.id}`} className="flex gap-3 pb-3 border-b border-gray-100 last:border-0 last:pb-0">
                <div className="bg-primary text-white h-6 w-6 rounded-full flex items-center justify-center flex-shrink-0 font-medium text-sm">
                  {index + 1}
                </div>
                <div className="flex-1">
                  <h4 className="font-medium text-sm mb-1 line-clamp-2">
                    {book.title}
                  </h4>
                  <div className="flex items-center text-xs text-gray-500 gap-1">
                    <BookOpen className="h-3 w-3 ml-1" />
                    <span>{book.views} مشاهدة</span>
                  </div>
                </div>
              </Link>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  )
}