import Hero from "@/components/hero"
import ContentCategories from "@/components/content-categories"
import RecentLessons from "@/components/recent-lessons"
import RecentFatwas from "@/components/recent-fatwas"
import AskSheikhSection from "@/components/ask-sheikh-section"
import BooksSection from "@/components/books-section"
import PopularTopics from "@/components/popular-topics"
import UpcomingEvents from "@/components/upcoming-events"
import FeaturedSheikh from "@/components/featured-sheikh"
import { getAllBooks } from "@/lib/services/books-service"

export default async function Home() {
  // Example of how to use the getAllBooks function
  const books = await getAllBooks()
  console.log(books)
  
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
              <RecentLessons />
            </div>
          </div>

          {/* Sidebar remains the same */}
          <div className="lg:col-span-1">
            <div className="mb-8 bg-white rounded-lg border border-gray-100 shadow-sm overflow-hidden">
              <FeaturedSheikh />
            </div>

            <div className="mb-8 bg-white rounded-lg border border-gray-100 shadow-sm overflow-hidden">
              <AskSheikhSection />
            </div>

            <div className="bg-white rounded-lg border border-gray-100 shadow-sm overflow-hidden">
              <UpcomingEvents />
            </div>
          </div>
        </div>

        <div className="mb-12">
          <BooksSection />
        </div>
      </div>
    </div>
  )
}
