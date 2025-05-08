import { Fatwa } from "@/lib/services/fatwas-service"
import { Card, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { formatDate } from "@/lib/utils"
import { BookmarkPlus, Calendar, Eye, MessageCircle, Share2 } from "lucide-react"
import Link from "next/link"


export const FatwaCardCompact = ({ fatwa }: { fatwa: Fatwa }) => {
  return (
    <Card
      key={fatwa.id}
      className="overflow-hidden border border-gray-100 shadow-sm hover:shadow-md transition-shadow"
    >
      <CardContent className="p-4">
        <div className="flex items-start gap-4">
          <div className="flex-shrink-0 flex items-center justify-center w-10 h-10 rounded-full text-primary mt-1">
            <MessageCircle className="h-5 w-5" />
          </div>
          <div className="flex-1">
            <div className="flex flex-wrap items-center justify-between gap-2 mb-1">
              <span className="text-xs text-gray-500">{formatDate(fatwa.published_date)}</span>
              <div className="flex items-center gap-2">
                <Button variant="ghost" size="sm" className="h-8 w-8 p-0">
                  <BookmarkPlus className="h-4 w-4" />
                </Button>
                <Button variant="ghost" size="sm" className="h-8 w-8 p-0">
                  <Share2 className="h-4 w-4" />
                </Button>
              </div>
            </div>
            <Button variant="link" className="text-lg font-semibold text-gray-900">
              <Link href={`/fatwas/${fatwa.id}`}>
                <h3 className="text-lg font-medium mb-2 hover:text-primary">{fatwa.title}</h3>
              </Link>
            </Button>
          </div>
        </div>
      </CardContent>
    </Card>
  )
}

export const FatwaCard = ({ fatwa }: { fatwa: Fatwa }) => {
    return (
      <Card key={fatwa.id} className="border-gray-100 shadow-sm hover:shadow-md transition-shadow overflow-hidden">
        <CardContent className="p-0">
          <div className="p-6">
            <div className="flex justify-between items-start mb-3">
              <Badge>
                {fatwa.category}
              </Badge>
              <div className="flex items-center text-xs text-gray-500">
                <Calendar className="h-3.5 w-3.5 ml-1" />
                <span>{formatDate(fatwa.published_date)}</span>
              </div>
            </div>
            <Link href={`/fatwas/${fatwa.id}`} className="block">
              <h3 className="text-lg font-semibold mb-2 hover:text-primary-700 hover:underline transition-colors">
                {fatwa.title}
              </h3>
            </Link>
            <div className="text-sm text-gray-600 mb-4">
              {fatwa.question && (
                <div className="max-h-[200px] overflow-y-auto pr-2 scrollbar-thin scrollbar-thumb-gray-300 scrollbar-track-gray-100">
                  <span className="font-semibold">السؤال:</span>
                  <div dangerouslySetInnerHTML={{ __html: fatwa.question.body }} />
                </div>
              )}
            </div>
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-4 space-x-reverse">
                <div className="flex items-center text-xs text-gray-500">
                  <Eye className="h-3.5 w-3.5 ml-1" />
                  <span>{fatwa.views} مشاهدة</span>
                </div>
                {/* <div className="flex items-center text-xs text-gray-500">
                  <MessageSquare className="h-3.5 w-3.5 ml-1" />
                  <span>{0} تعليق</span>
                </div> */}
              </div>
              <div className="flex space-x-2 space-x-reverse">
                <Button variant="ghost" size="sm">
                  <BookmarkPlus className="h-4 w-4" />
                </Button>
                <Button variant="ghost" size="sm">
                  <Share2 className="h-4 w-4" />
                </Button>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>
    )
  } 