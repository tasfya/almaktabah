import Link from "next/link"
import { Book, FileText, Mic, BookOpen, Gift, Video } from "lucide-react"

export default function ContentCategories() {
  const categories = [
    {
      title: "الدروس العلمية",
      icon: <Book className="h-6 w-6" />,
      href: "/lessons",
    },
    {
      title: "الفتاوى",
      icon: <FileText className="h-6 w-6" />,
      href: "/fatwas",
    },
    {
      title: "الخطب",
      icon: <Mic className="h-6 w-6" />,
      href: "/sermons",
    },
    {
      title: "المحاضرات",
      icon: <Video className="h-6 w-6" />,
      href: "/lectures",
    },
    {
      title: "الكتب",
      icon: <BookOpen className="h-6 w-6" />,
      href: "/books",
    },
    {
      title: "الفوائد",
      icon: <Gift className="h-6 w-6" />,
      href: "/benefits",
    },
  ]

  return (
    <section className="py-8">
      <h2 className="text-2xl font-bold text-center mb-8">محتويات الموقع</h2>
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
        {categories.map((category) => (
          <Link
            key={category.title}
            href={category.href}
            className="flex flex-col items-center p-6 rounded-lg shadow-sm hover:shadow-md transition-shadow bg-white border border-gray-100"
          >
            <div className="p-3 rounded-full  text-primary mb-3 border">{category.icon}</div>
            <span className="font-medium text-gray-800 text-center">{category.title}</span>
          </Link>
        ))}
      </div>
    </section>
  )
}
