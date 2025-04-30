import { Button } from "@/components/ui/button"
import { ArrowLeft, MessageCircle, Send } from "lucide-react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Textarea } from "@/components/ui/textarea"
import Image from "next/image"

export default function AskSheikhSection() {
  return (
    <div className="h-full">
      <CardHeader className="pb-2">
        <div className="flex justify-between items-center">
          <CardTitle className="flex items-center gap-2 text-xl">
            <MessageCircle className="h-5 w-5 text-emerald-600" />
            اسأل الشيخ
          </CardTitle>
          <Button variant="ghost" size="sm" className="text-emerald-600 hover:text-emerald-700">
            جميع الأسئلة <ArrowLeft className="h-4 w-4 mr-1" />
          </Button>
        </div>
      </CardHeader>
      <CardContent>
        <Card className="shadow-sm border-gray-100">
          <CardContent className="pt-6">
            <div className="mb-4 flex items-center gap-3">
              <div className="relative h-12 w-12 overflow-hidden rounded-full border-2 border-emerald-100">
                <Image 
                  src="/placeholder-user.jpg" 
                  alt="Sheikh profile" 
                  fill 
                  className="object-cover"
                />
              </div>
              <div>
                <h4 className="font-medium text-gray-900">الشيخ عبدالله بن بيه</h4>
                <p className="text-sm text-gray-500">يجيب على أسئلتكم الشرعية</p>
              </div>
            </div>

            <div className="bg-gray-50 p-4 rounded-lg mb-4">
              <p className="text-sm text-gray-600 mb-2">آخر الأسئلة المجابة:</p>
              <p className="text-gray-800 mb-1 text-sm">
                <span className="font-medium text-emerald-700">سؤال:</span> ما حكم استخدام برامج قراءة القرآن الكريم الصوتية؟
              </p>
              <p className="text-gray-700 text-sm">
                <span className="font-medium text-emerald-700">الجواب:</span> يجوز استخدام برامج قراءة القرآن الصوتية بشرط...
              </p>
            </div>

            <form className="space-y-3">
              <Textarea 
                placeholder="اكتب سؤالك الشرعي هنا..." 
                className="resize-none h-24 border-gray-200 focus:border-emerald-300 focus:ring-emerald-200"
              />
              <div className="flex justify-between items-center text-xs text-gray-500">
                <span>يرجى الالتزام بآداب السؤال</span>
                <span>0/500 حرف</span>
              </div>
              <div className="flex space-x-2 justify-end">
                <Button type="submit" className="bg-emerald-600 hover:bg-emerald-700 ml-2">
                  <Send className="h-4 w-4 ml-2" /> إرسال السؤال
                </Button>
              </div>
            </form>
          </CardContent>
        </Card>
      </CardContent>
    </div>
  )
}
