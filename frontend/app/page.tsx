import Hero from "@/components/hero"
import ContentCategories from "@/components/content-categories"
import RecentFatwas from "@/components/recent-fatwas"
import { RecentBooks } from "@/components/books-section"
import PopularTopics from "@/components/popular-topics"
import { RecentLessons } from "@/components/lessons-list"
import PageSidebar from "@/components/page-sidebar"
import { getRecentLessons } from "@/lib/services/lessons-service"
import { getRecentFatwas } from "@/lib/services/fatwas-service"
import { getRecentBooks } from "@/lib/services/books-service"

export default async function Home() {
  const [lessons, fatwas, books] = await Promise.all([
    getRecentLessons(),
    getRecentFatwas(),
    getRecentBooks()
  ])

  return (
    <div className="bg-gray-50" dir="rtl">
      {lessons.length > 0 && <Hero lesson={lessons[0]} />}

      <div className="container mx-auto px-4 py-8">
        <div className="grid grid-cols-1 lg:grid-cols-4 gap-8">
          <div className="lg:col-span-3">
            <div className="mb-8">
              <ContentCategories />
            </div>
            <div className="mb-12">
              <RecentLessons lessons={lessons} />
            </div>
            <div className="mb-12">
              <RecentFatwas fatwas={fatwas} />
            </div>

          </div>

          {/* Sidebar remains the same */}
          <div className="lg:col-span-1">
            <PageSidebar />
          </div>
        </div>

        <div className="mb-12">
          <RecentBooks books={books} />
        </div>
      </div>
    </div>
  )
}
