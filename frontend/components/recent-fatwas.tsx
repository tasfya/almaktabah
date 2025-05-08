import { Button } from "@/components/ui/button"
import { Fatwa } from "@/lib/services/fatwas-service"
import { ArrowLeft } from "lucide-react"
import Link from "next/link"
import { FatwaCardCompact } from "./fatwa-card"


export default function RecentFatwas({ fatwas }: { fatwas: Fatwa[] }) {
  return (
    <section>
      <div className="flex justify-between items-center mb-6">
        <h2 className="text-2xl font-bold">أحدث الفتاوى</h2>
        <Button variant="link">
          <Link href="/fatwas">
            عرض الكل <ArrowLeft className="h-4 w-4 mr-1" />
          </Link>
        </Button>
      </div>

      <div className="grid grid-cols-1 gap-4">
        {fatwas.map((fatwa) => (
          <FatwaCardCompact key={fatwa.id} fatwa={fatwa} />
        ))}
      </div>
    </section>
  )
}
