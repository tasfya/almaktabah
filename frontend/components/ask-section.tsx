import Image from "next/image"
import { Button } from "@/components/ui/button"

export default function AskSection() {
  return (
    <section className="py-10">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
        <div className="bg-gray-50 rounded-lg p-6 flex flex-col items-center">
          <div className="w-20 h-20 mb-4 relative">
            <Image
              src="/placeholder.svg?height=80&width=80"
              alt="Audio icon"
              width={80}
              height={80}
              className="rounded-full"
            />
          </div>
          <h3 className="text-lg font-semibold mb-2">بث مباشر للشيخ</h3>
          <p className="text-sm text-gray-600 mb-4 text-center">استمع إلى البث المباشر للشيخ</p>
          <Button variant="outline" className="w-full">
            استمع الآن
          </Button>
        </div>

        <div className="bg-gray-50 rounded-lg p-6 flex flex-col items-center">
          <div className="w-20 h-20 mb-4 flex items-center justify-center">
            <Image src="/placeholder.svg?height=80&width=80" alt="Question icon" width={80} height={80} />
          </div>
          <h3 className="text-lg font-semibold mb-2">اسأل الشيخ</h3>
          <p className="text-sm text-gray-600 mb-4 text-center">يمكنك إرسال سؤالك للشيخ</p>
          <Button className="w-full bg-emerald-600 hover:bg-emerald-700">اسأل الشيخ</Button>
        </div>
      </div>
    </section>
  )
}
