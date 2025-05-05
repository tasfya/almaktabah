"use client"
import Link from "next/link"
import { usePathname } from "next/navigation"
import Image from "next/image"
import { Search, User, Menu, LogOut, Settings, Bookmark, ChevronDown } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import SocialLinks from "./social-links"
import { useState, useEffect } from "react"
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import SearchModal from "./search-modal"

export default function Header() {
  const [isMenuOpen, setIsMenuOpen] = useState(false)
  const [user, setUser] = useState<any>(null)
  const [loading, setLoading] = useState(true)
  const [isSearchModalOpen, setIsSearchModalOpen] = useState(false)
  const pathname = usePathname()


  // Handle sign out
  const handleSignOut = async () => {
  }

  const isActive = (path: string) => {
    return pathname === path
  }
  
  const isActiveStartsWith = (path: string) => {
    return pathname.startsWith(path) && (path !== "/" || pathname === "/")
  }
  
  const getNavLinkClass = (path: string) => {
    const active = path === "/" ? isActive(path) : isActiveStartsWith(path)
    return active
      ? "px-4 py-3 text-sm font-medium text-primary border-b-2 border-primary whitespace-nowrap"
      : "px-4 py-3 text-sm font-medium text-gray-600 hover:text-primary whitespace-nowrap"
  }
  
  // Function for mobile nav link styles
  const getMobileNavLinkClass = (path: string) => {
    const active = path === "/" ? isActive(path) : isActiveStartsWith(path)
    return active
      ? "p-2 text-sm font-medium text-primary rounded"
      : "p-2 text-sm font-medium text-gray-600 hover:bg-gray-100 rounded"
  }

  // Get user initials for avatar fallback
  const getUserInitials = () => {
    if (!user || !user.user_metadata?.name) return "U"
    const name = user.user_metadata.name
    return name.split(" ").map((n: string) => n[0]).join("").toUpperCase()
  }

  const handleOpenSearchModal = () => {
    setIsSearchModalOpen(true)
  }

  return (
    <header className="bg-white border-b sticky top-0 z-50">
      <div className="container mx-auto py-3 px-4">
        <div className="flex items-center justify-between">
          {/* Logo */}
          <Link href="/" className="flex items-center flex-1 w-full">
            <Image
              src="/logo.png"
              alt="الموقع الرسمي للشيخ"
              width={200}
              height={50}
            />
          </Link>

          {/* Search Button - Replace the search input with a button */}
          <div className="hidden md:flex items-center gap-2 mx-4 flex-1 max-w-md">
            <Button 
              variant="outline" 
              className="w-full flex justify-between" 
              onClick={handleOpenSearchModal}
              dir="rtl"
            >
              <span className="text-gray-500">ابحث في المكتبة...</span>
              <Search className="h-4 w-4 text-gray-400" />
            </Button>
          </div>

          {/* Social Links */}
          <div className="hidden md:flex">
            <SocialLinks />
          </div>

          {/* Account Button/Menu and Preferences */}
          <div className="flex items-center gap-2 mr-4">            
            {/* User Menu */}
            {!loading && (
              user ? (
                <DropdownMenu>
                  <DropdownMenuTrigger asChild>
                    <Button variant="ghost" size="sm" className="flex items-center gap-2 text-gray-600">
                      <span className="hidden sm:inline">{"حسابي"}</span>
                      <Avatar className="h-8 w-8">
                        <AvatarImage src={user.user_metadata?.avatar_url} />
                        <AvatarFallback className="bg-emerald-100 text-emerald-800">
                          {getUserInitials()}
                        </AvatarFallback>
                      </Avatar>
                    </Button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent align="end" className="w-56">
                    <DropdownMenuItem className="flex justify-end" asChild>
                      <Link href="/profile" className="cursor-pointer w-full text-right">
                        <User className="ml-2 h-4 w-4" />
                        <span>الملف الشخصي</span>
                      </Link>
                    </DropdownMenuItem>
                    <DropdownMenuItem className="flex justify-end" asChild>
                      <Link href="/dashboard" className="cursor-pointer w-full text-right">
                        <Settings className="ml-2 h-4 w-4" />
                        <span>لوحة التحكم</span>
                      </Link>
                    </DropdownMenuItem>
                    <DropdownMenuItem className="flex justify-end" asChild>
                      <Link href="/bookmarks" className="cursor-pointer w-full text-right">
                        <Bookmark className="ml-2 h-4 w-4" />
                        <span>المحفوظات</span>
                      </Link>
                    </DropdownMenuItem>
                    <DropdownMenuSeparator />
                    <DropdownMenuItem className="flex justify-end cursor-pointer" onClick={handleSignOut}>
                      <LogOut className="ml-2 h-4 w-4" />
                      <span>تسجيل الخروج</span>
                    </DropdownMenuItem>
                  </DropdownMenuContent>
                </DropdownMenu>
              ) : (
                <DropdownMenu>
                  <DropdownMenuTrigger asChild>
                    <Button variant="ghost" size="sm" className="flex items-center gap-1 text-gray-600">
                      <span>تسجيل الدخول</span>
                      <ChevronDown className="h-4 w-4" />
                    </Button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent align="end" className="w-56">
                    <DropdownMenuItem className="flex justify-end" asChild>
                      <Link href="/login" className="cursor-pointer w-full text-right">
                        <span>تسجيل الدخول</span>
                      </Link>
                    </DropdownMenuItem>
                    <DropdownMenuItem className="flex justify-end" asChild>
                      <Link href="/register" className="cursor-pointer w-full text-right">
                        <span>إنشاء حساب جديد</span>
                      </Link>
                    </DropdownMenuItem>
                  </DropdownMenuContent>
                </DropdownMenu>
              )
            )}
          </div>

          {/* Mobile Menu Button */}
          <Button variant="ghost" size="sm" className="md:hidden" onClick={() => setIsMenuOpen(!isMenuOpen)}>
            <Menu className="h-6 w-6" />
          </Button>
        </div>

        {/* Mobile Search Button */}
        <div className="mt-3 md:hidden">
          <Button 
            variant="outline" 
            className="w-full flex justify-between" 
            onClick={handleOpenSearchModal}
            dir="rtl"
          >
            <span className="text-gray-500">ابحث في المكتبة...</span>
            <Search className="h-4 w-4 text-gray-400" />
          </Button>
        </div>
      </div>

      {/* Main Navigation */}
      <div className="border-t">
        <div className="container mx-auto">
          <nav className="flex justify-center">
            <div className="flex overflow-x-auto">
              <Link
                href="/"
                className={getNavLinkClass("/")}
              >
                الرئيسية
              </Link>
              <Link
                href="/lessons"
                className={getNavLinkClass("/lessons")}
              >
                الدروس العلمية
              </Link>
              <Link
                href="/fatwas"
                className={getNavLinkClass("/fatwas")}
              >
                الفتاوى
              </Link>
              <Link
                href="/sermons"
                className={getNavLinkClass("/sermons")}
              >
                الخطب
              </Link>
              <Link
                href="/lectures"
                className={getNavLinkClass("/lectures")}
              >
                المحاضرات والكلمات
              </Link>
              <Link
                href="/books"
                className={getNavLinkClass("/books")}
              >
                الكتب
              </Link>
              <Link
                href="/benefits"
                className={getNavLinkClass("/benefits")}
              >
                الفوائد
              </Link>
              <Link
                href="/about"
                className={getNavLinkClass("/about")}
              >
                مع الشيخ
              </Link>
              <Link
                href="/comments"
                className={getNavLinkClass("/comments")}
              >
                التعليقات
              </Link>
            </div>
          </nav>
        </div>
      </div>

      {/* Mobile Menu */}
      {isMenuOpen && (
        <div className="md:hidden border-t">
          <div className="container mx-auto py-4">
            <div className="grid grid-cols-2 gap-2">
              <Link href="/" className={getMobileNavLinkClass("/")}>
                الرئيسية
              </Link>
              <Link href="/lessons" className={getMobileNavLinkClass("/lessons")}>
                الدروس العلمية
              </Link>
              <Link href="/fatwas" className={getMobileNavLinkClass("/fatwas")}>
                الفتاوى
              </Link>
              <Link href="/sermons" className={getMobileNavLinkClass("/sermons")}>
                الخطب
              </Link>
              <Link href="/lectures" className={getMobileNavLinkClass("/lectures")}>
                المحاضرات والكلمات
              </Link>
              <Link href="/books" className={getMobileNavLinkClass("/books")}>
                الكتب
              </Link>
              <Link href="/benefits" className={getMobileNavLinkClass("/benefits")}>
                الفوائد
              </Link>
              <Link href="/about" className={getMobileNavLinkClass("/about")}>
                مع الشيخ
              </Link>
              <Link href="/comments" className={getMobileNavLinkClass("/comments")}>
                التعليقات
              </Link>
            </div>

            {/* Mobile Auth Links */}
            <div className="mt-4 pt-4 border-t flex flex-col gap-2">
              {user ? (
                <>
                  <Link href="/profile" className="p-2 text-sm font-medium text-gray-600 hover:bg-gray-100 rounded flex justify-between items-center">
                    <User className="h-4 w-4" />
                    <span>الملف الشخصي</span>
                  </Link>
                  <Link href="/dashboard" className="p-2 text-sm font-medium text-gray-600 hover:bg-gray-100 rounded flex justify-between items-center">
                    <Settings className="h-4 w-4" />
                    <span>لوحة التحكم</span>
                  </Link>
                  <Link href="/bookmarks" className="p-2 text-sm font-medium text-gray-600 hover:bg-gray-100 rounded flex justify-between items-center">
                    <Bookmark className="h-4 w-4" />
                    <span>المحفوظات</span>
                  </Link>
                  <button 
                    onClick={handleSignOut}
                    className="p-2 text-sm font-medium text-gray-600 hover:bg-gray-100 rounded flex justify-between items-center w-full"
                  >
                    <LogOut className="h-4 w-4" />
                    <span>تسجيل الخروج</span>
                  </button>
                </>
              ) : (
                <>
                  <Link href="/login" className="p-2 text-sm font-medium text-gray-600 hover:bg-gray-100 rounded text-center">
                    تسجيل الدخول
                  </Link>
                  <Link href="/register" className="p-2 text-sm font-medium bg-emerald-600 text-white hover:bg-emerald-700 rounded text-center">
                    إنشاء حساب جديد
                  </Link>
                </>
              )}
            </div>

            <div className="mt-4 pt-4 border-t">
              <SocialLinks />
            </div>
          </div>
        </div>
      )}
      
      {/* Search Modal */}
      <SearchModal 
        open={isSearchModalOpen} 
        onOpenChange={setIsSearchModalOpen} 
      />
    </header>
  )
}
