import Hero from "@/components/hero"
import ContentCategories from "@/components/content-categories"
import RecentFatwas from "@/components/recent-fatwas"
import BooksSection from "@/components/books-section"
import PopularTopics from "@/components/popular-topics"
import {RecentLessons} from "@/components/lessons-list"
import PageSidebar from "@/components/page-sidebar"
import { getRecentLessons } from "@/lib/services/lessons-service"

export default async function Home() {
  const lessons = await getRecentLessons()

  return (
    <div className="bg-gray-50" dir="rtl">
      <Hero />

      <div className="container mx-auto px-4 py-8">
        <div className="grid grid-cols-1 lg:grid-cols-4 gap-8">
          <div className="lg:col-span-3">
            <div className="mb-8">
              <ContentCategories />
            </div>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mb-12">
              <div className="md:col-span-1">
                <PopularTopics />
              </div>
              <div className="md:col-span-2">
                <RecentFatwas />
              </div>
            </div>

            {/* Rest of the components remain the same */}
            <div className="mb-12">
              <RecentLessons lessons={lessons} />
            </div>
          </div>

          {/* Sidebar remains the same */}
          <div className="lg:col-span-1">
            <PageSidebar />
          </div>
        </div>

        <div className="mb-12">
          <BooksSection />
        </div>
      </div>
    </div>
  )
}
