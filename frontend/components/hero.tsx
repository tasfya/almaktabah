import Image from "next/image"
import { Button } from "@/components/ui/button"
import { Badge } from "./ui/badge"
import { formatDate } from "@/lib/utils"

export default function Hero() {
  return (
    <section className="relative w-full h-[500px] overflow-hidden">
      {/* Background Image */}
      <div className="absolute inset-0">
        <Image
          src="/speech.jpg?height=500&width=1200"
          alt="Hero background"
          fill
          className="object-cover"
          priority
        />
        <div className="absolute inset-0 bg-black/20"></div>
      </div>

      {/* Content */}
      <div className="relative container mx-auto h-full flex flex-col justify-center p-6 md:p-12">
        <div className="max-w-3xl">
          <div className="flex items-center text-sm mb-3 gap-2">
            <Badge className="text-slate-50">خطب</Badge>
            <span className="text-white">{formatDate(new Date("2018/01/01"))}</span>
          </div>
          <h1 className="text-3xl md:text-5xl font-bold mb-6 text-white">الدنيا وزينتها</h1>
          <p className="text-sm md:text-base mb-8 leading-relaxed text-white">
            الحمد لله الذي له ما في السموات وما في الأرض، وله الحمد في الآخرة وهو الحكيم الخبير، أحمده سبحانه وأشكره
            وأشهد أن لا إله إلا الله وحده لا شريك له ولا ولد ولا وزير وأشهد أن سيدنا ونبينا محمد عبده ورسوله، صلى الله
            عليه وعلى آله وصحبه وسلم تسليماً كثيراً.
          </p>
          <div className="flex flex-wrap gap-4">
            <Button>قراءة المزيد</Button>
            <Button variant="outline">
              استماع للخطبة
            </Button>
          </div>
        </div>
      </div>
    </section>
  )
}
