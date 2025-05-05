import type React from "react"
import type { Metadata } from "next"
import { Inter } from "next/font/google"
import "./globals.css"
import Header from "@/components/header"
import Footer from "@/components/footer"
import { AudioPlayerProvider } from "@/context/AudioPlayerContext"

const inter = Inter({ subsets: ["latin"] })

export const metadata: Metadata = {
  title: "الموقع الرسمي للشيخ",
  description: "الموقع الرسمي للشيخ - دروس علمية، خطب، محاضرات، فتاوى",
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html lang="ar" dir="rtl">
      <body className={inter.className}>
        <AudioPlayerProvider>
          <Header />
          <main className="min-h-screen">{children}</main>
          <Footer />
        </AudioPlayerProvider>
      </body>
    </html>
  )
}
