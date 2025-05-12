"use client"
import Image from "next/image"
import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { Book } from "lucide-react"
import Link from "next/link"
import { Book as TBook } from "@/lib/services/books-service"
import { resourceUrl } from "@/lib/utils"
import {
  Carousel,
  CarouselContent,
  CarouselItem,
  CarouselNext,
  CarouselPrevious,
} from "@/components/ui/carousel"


const BookCard = ({ book }: { book: TBook }) => {
  return (
    <Card className="border border-gray-100 shadow-sm hover:shadow-md transition-shadow" dir="rtl">
      <CardContent className="p-0">
        <div className="flex flex-col">
          <div className="relative h-48 flex items-center justify-center">
            <Image
              src={resourceUrl(book.cover_image_url)}
              alt={book.title}
              width={120}
              height={180}
              className="h-40 w-auto object-cover shadow-md"
            />
          </div>
          <div className="p-4">
            <div className="flex items-center gap-2 mb-2">
              <div className="flex items-center justify-center w-8 h-8 rounded-full border text-primary">
                <Book className="h-4 w-4" />
              </div>
              <span className="text-xs text-gray-500">{book.year} هـ</span>
            </div>
            <h3 className="text-lg font-semibold mb-3 line-clamp-1">{book.title}</h3>
            <div className="text-sm text-gray-600 space-y-1 mb-4">
              <p className="flex justify-between">
                <span>عدد الصفحات:</span>
                <span className="font-medium">{book.pages}</span>
              </p>
              {book.volumes && (
                <p className="flex justify-between">
                  <span>عدد المجلدات:</span>
                  <span className="font-medium">{book.volumes}</span>
                </p>
              )}
              <p className="flex justify-between">
                <span>رقم الطبعة:</span>
                <span className="font-medium">{book.category}</span>
              </p>
            </div>
            <Link href={`/books/${book.id}`}>
              <Button className="w-full">قراءة الكتاب</Button>
            </Link>
          </div>
        </div>
      </CardContent>
    </Card>
  )
}


export function RecentBooks({ books }: { books: TBook[] }) {
  return (
    <section>
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-2xl font-bold">كتب الشيخ</h2>
      </div>
      <Carousel
        opts={{
          loop: true,
        }}
        dir="ltr"
        orientation='horizontal'
        className="w-full sm:max-w-sm md:max-w-md lg:max-w-lg xl:max-w-xl 2xl:max-w-full mx-auto">
        <CarouselContent dir="ltr">
          {books.map((book, index) => (
            <CarouselItem key={index} className="md:basis-1/2 lg:basis-1/3">
              <div className="p-1">
                <BookCard book={book} />
              </div>
            </CarouselItem>
          ))}
        </CarouselContent>
        <CarouselPrevious />
        <CarouselNext />
      </Carousel>
      <div className="flex justify-center mt-8">
        <Link href="/books">
          <Button variant="outline">
            عرض المزيد من الكتب
          </Button>
        </Link>
      </div>
    </section>
  )
}
