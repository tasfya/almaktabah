"use client"

import { useState, useEffect } from "react"
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Search, Book, FileText, Mic, Video, Gift } from "lucide-react"
import { useRouter } from "next/navigation"
import { Badge } from "./ui/badge"

type SearchResult = {
  id: string
  title: string
  description?: string
  type: 'lesson' | 'book' | 'fatwa' | 'sermon' | 'lecture' | 'benefit'
  category?: string
  date?: string
}

export default function SearchModal({ 
  open, 
  onOpenChange 
}: { 
  open: boolean
  onOpenChange: (open: boolean) => void 
}) {
  const [searchQuery, setSearchQuery] = useState("")
  const [activeTab, setActiveTab] = useState("all")
  const [results, setResults] = useState<SearchResult[]>([])
  const [isLoading, setIsLoading] = useState(false)
  const router = useRouter()

  useEffect(() => {
    // Reset search when modal opens
    if (open) {
      setSearchQuery("")
      setResults([])
    }
  }, [open])

  useEffect(() => {
    // Simple debounce for search
    const timeoutId = setTimeout(() => {
      if (searchQuery.trim().length >= 2) {
        performSearch()
      }
    }, 300)

    return () => clearTimeout(timeoutId)
  }, [searchQuery, activeTab])

  const performSearch = async () => {
    // This would be replaced with actual API calls
    setIsLoading(true)
    
    // Mock search results
    const mockResults: SearchResult[] = [
      // Filter based on active tab
      ...(activeTab === "all" || activeTab === "lessons" ? [
        { id: "1", title: "شرح حديث الإيمان", description: "شرح مفصل لحديث جبريل في الإيمان", type: "lesson" as const, category: "العقيدة", date: "2025/04/15" },
        { id: "2", title: "التعليق على صحيح البخاري", description: "درس من سلسلة التعليق على صحيح البخاري", type: "lesson" as const, category: "الحديث", date: "2025/04/10" }
      ] : []),
      ...(activeTab === "all" || activeTab === "books" ? [
        { id: "1", title: "السبيل المحني للمسلم من الفتن", description: "توضيح في بيان السبيل الذي ينجي من الفتن", type: "book" as const, category: "العقيدة", date: "1437" },
        { id: "2", title: "القول البين الأظهر", description: "القول البين الأظهر في الدعوة إلى الله والأمر بالمعروف والنهي عن المنكر", type: "book" as const, category: "الدعوة", date: "1437" }
      ] : []),
      ...(activeTab === "all" || activeTab === "fatwas" ? [
        { id: "1", title: "حكمة خلق الله الكافر مع علمه سبحانه أنه من أهل النار", type: "fatwa" as const, category: "العقيدة", date: "2023/02/10" },
        { id: "7", title: "حكم قراءة القرآن للحائض", type: "fatwa" as const, category: "الفقه", date: "2023/06/10" }
      ] : []),
      ...(activeTab === "all" || activeTab === "sermons" ? [
        { id: "1", title: "أهمية الصلاة", type: "sermon" as const, category: "العبادات", date: "2025/05/02" }
      ] : []),
      ...(activeTab === "all" || activeTab === "lectures" ? [
        { id: "1", title: "أثر القرآن في تزكية النفوس", type: "lecture" as const, category: "التزكية", date: "2025/03/15" }
      ] : []),
      ...(activeTab === "all" || activeTab === "benefits" ? [
        { id: "1", title: "فائدة في الحرص على قيام الليل", type: "benefit" as const, category: "العبادات", date: "2025/04/30" }
      ] : [])
    ].filter(item => 
      item.title.includes(searchQuery) || 
      (item.description && item.description.includes(searchQuery))
    )
    
    // Simulate API delay
    setTimeout(() => {
      setResults(mockResults)
      setIsLoading(false)
    }, 500)
  }

  const handleResultClick = (result: SearchResult) => {
    // Navigate to the appropriate page based on result type
    switch (result.type) {
      case 'lesson':
        router.push(`/lessons/${result.id}`)
        break
      case 'book':
        router.push(`/books/${result.id}`)
        break
      case 'fatwa':
        router.push(`/fatwas/${result.id}`)
        break
      case 'sermon':
        router.push(`/sermons/${result.id}`)
        break
      case 'lecture':
        router.push(`/lectures/${result.id}`)
        break
      case 'benefit':
        router.push(`/benefits/${result.id}`)
        break
    }
    onOpenChange(false)
  }

  const getIconForType = (type: string) => {
    switch (type) {
      case 'lesson':
        return <FileText className="h-4 w-4" />
      case 'book':
        return <Book className="h-4 w-4" />
      case 'fatwa':
        return <FileText className="h-4 w-4" />
      case 'sermon':
        return <Mic className="h-4 w-4" />
      case 'lecture':
        return <Video className="h-4 w-4" />
      case 'benefit':
        return <Gift className="h-4 w-4" />
      default:
        return <Search className="h-4 w-4" />
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-3xl w-[90vw]" dir="rtl">
        <DialogHeader>
          <DialogTitle className="text-center text-xl">البحث في المكتبة</DialogTitle>
        </DialogHeader>
        
        <div className="relative w-full mt-4">
          <Input 
            type="search" 
            placeholder="ابحث في المكتبة..." 
            className="pl-10 pr-4 py-1 h-10 text-lg w-full" 
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            autoFocus
          />
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" size={20} />
        </div>
        
        <Tabs value={activeTab} onValueChange={setActiveTab} className="w-full mt-4">
          <TabsList className="w-full flex justify-between">
            <TabsTrigger value="all" className="flex-1">الكل</TabsTrigger>
            <TabsTrigger value="lessons" className="flex-1">الدروس</TabsTrigger>
            <TabsTrigger value="books" className="flex-1">الكتب</TabsTrigger>
            <TabsTrigger value="fatwas" className="flex-1">الفتاوى</TabsTrigger>
            <TabsTrigger value="sermons" className="flex-1">الخطب</TabsTrigger>
            <TabsTrigger value="lectures" className="flex-1">المحاضرات</TabsTrigger>
            <TabsTrigger value="benefits" className="flex-1">الفوائد</TabsTrigger>
          </TabsList>
          
          {/* Results content */}
          <div className="mt-6">
            {isLoading ? (
              <div className="flex justify-center items-center py-10">
                <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-b-2 border-primary"></div>
              </div>
            ) : searchQuery.length < 2 ? (
              <div className="text-center text-gray-500 py-10">
                اكتب كلمة للبحث (على الأقل حرفين)
              </div>
            ) : results.length === 0 ? (
              <div className="text-center text-gray-500 py-10">
                لا توجد نتائج للبحث
              </div>
            ) : (
              <div className="space-y-4 max-h-[50vh] overflow-y-auto pr-2">
                {results.map((result) => (
                  <div 
                    key={`${result.type}-${result.id}`}
                    className="flex border rounded-md p-3 hover:bg-gray-50 cursor-pointer"
                    onClick={() => handleResultClick(result)}
                  >
                    <div className="mr-2 flex flex-col justify-between flex-1">
                      <div>
                        <div className="flex items-center gap-2 mb-1">
                          <Badge 
                            className={`
                              ${result.type === 'lesson' ? 'bg-blue-100 text-blue-800 hover:bg-blue-100' : ''} 
                              ${result.type === 'book' ? 'bg-emerald-100 text-emerald-800 hover:bg-emerald-100' : ''}
                              ${result.type === 'fatwa' ? 'bg-amber-100 text-amber-800 hover:bg-amber-100' : ''}
                              ${result.type === 'sermon' ? 'bg-purple-100 text-purple-800 hover:bg-purple-100' : ''}
                              ${result.type === 'lecture' ? 'bg-red-100 text-red-800 hover:bg-red-100' : ''}
                              ${result.type === 'benefit' ? 'bg-teal-100 text-teal-800 hover:bg-teal-100' : ''}
                            `}
                          >
                            <span className="flex items-center gap-1">
                              {getIconForType(result.type)}
                              {result.type === 'lesson' && 'درس'}
                              {result.type === 'book' && 'كتاب'}
                              {result.type === 'fatwa' && 'فتوى'}
                              {result.type === 'sermon' && 'خطبة'}
                              {result.type === 'lecture' && 'محاضرة'}
                              {result.type === 'benefit' && 'فائدة'}
                            </span>
                          </Badge>
                          {result.category && (
                            <span className="text-xs text-gray-500">{result.category}</span>
                          )}
                        </div>
                        <h3 className="text-lg font-medium">{result.title}</h3>
                        {result.description && (
                          <p className="text-sm text-gray-600 line-clamp-2 mt-1">{result.description}</p>
                        )}
                      </div>
                      {result.date && (
                        <div className="text-xs text-gray-500 mt-2">{result.date}</div>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </Tabs>
      </DialogContent>
    </Dialog>
  )
}