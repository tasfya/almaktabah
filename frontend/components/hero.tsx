import Image from "next/image"
import { Button } from "@/components/ui/button"

export default function Hero() {
  return (
    <section className="relative w-full h-[500px] overflow-hidden">
      {/* Background Image */}
      <div className="absolute inset-0">
        <Image
          src="/placeholder.svg?height=500&width=1200"
          alt="Hero background"
          fill
          className="object-cover"
          priority
        />
        <div className="absolute inset-0 bg-black/60"></div>
      </div>

      {/* Content */}
      <div className="relative container mx-auto h-full flex flex-col justify-center text-white p-6 md:p-12">
        <div className="max-w-3xl">
          <div className="flex items-center text-sm mb-3">
            <span className="bg-emerald-600 px-3 py-1 rounded text-white text-xs ml-2">خطب</span>
            <span>2018/01/01</span>
          </div>
          <h1 className="text-3xl md:text-5xl font-bold mb-6">الدنيا وزينتها</h1>
          <p className="text-sm md:text-base mb-8 leading-relaxed">
            الحمد لله الذي له ما في السموات وما في الأرض، وله الحمد في الآخرة وهو الحكيم الخبير، أحمده سبحانه وأشكره
            وأشهد أن لا إله إلا الله وحده لا شريك له ولا ولد ولا وزير وأشهد أن سيدنا ونبينا محمد عبده ورسوله، صلى الله
            عليه وعلى آله وصحبه وسلم تسليماً كثيراً.
          </p>
          <div className="flex flex-wrap gap-4">
            <Button className="bg-emerald-600 hover:bg-emerald-700">قراءة المزيد</Button>
            <Button variant="outline" className="text-black bg-white hover:bg-gray-100">
              استماع للخطبة
            </Button>
          </div>
        </div>
      </div>
    </section>
  )
}
