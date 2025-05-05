import Link from "next/link"
import Image from "next/image"
import { Input } from "@/components/ui/input"
import { Button } from "@/components/ui/button"
import SocialLinks from "./social-links"

export default function Footer() {
  return (
    <footer className="bg-gray-900">
      <div className="container mx-auto py-12 px-4">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-10">
          {/* Newsletter Subscription */}
          <div>
            <h3 className="text-xl font-semibold mb-4 text-white">اشترك بالقائمة البريدية</h3>
            <p className="text-gray-400 mb-4">
              اشترك بالقائمة البريدية للشيخ ليصلك جديد الشيخ من المحاضرات والدروس والمواعيد
            </p>
            <div className="flex flex-col space-y-3">
              <Input
                type="email"
                placeholder="عنوان بريدك الإلكتروني"
                className="bg-gray-800 border-gray-700 text-white"
              />
              <Button variant={'outline'}>اشتراك</Button>
            </div>
          </div>

          {/* Follow Sheikh */}
          <div>
            <h3 className="text-xl font-semibold mb-4 text-white">اتبع الشيخ</h3>
            <div className="flex flex-col space-y-4">
              <SocialLinks />

              <div className="mt-6">
                <h4 className="text-lg font-medium mb-2 text-white">الأحكام والشروط</h4>
                <ul className="space-y-2 text-gray-400">
                  <li>
                    <Link href="/privacy" className="hover:text-white">
                      سياسة الخصوصية
                    </Link>
                  </li>
                  <li>
                    <Link href="/terms" className="hover:text-white">
                      تواصل معنا
                    </Link>
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </div>

        <div className="mt-10 pt-6 border-t border-gray-800 flex flex-col md:flex-row justify-between items-center">
          <div className="mb-4 md:mb-0">
            <Image
              src="/logo.png?height=60&width=300"
              alt="Foundation Logo"
              width={300}
              height={60}
            />
          </div>
          <div className="text-gray-400 text-sm">
            <p>جميع الحقوق محفوظة © 2025 / 1446 هـ</p>
          </div>
        </div>
      </div>
    </footer>
  )
}
