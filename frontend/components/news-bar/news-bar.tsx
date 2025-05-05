"use client";

import { useState, useEffect } from "react";
import { Megaphone } from "lucide-react";

const defaultNews = [
  "درس جديد في شرح كتاب التوحيد - الثلاثاء بعد صلاة المغرب",
  "تم إضافة محاضرة جديدة عن فضل العلم الشرعي وطلبه",
  "بدء التسجيل في الدورة العلمية الصيفية لعام ١٤٤٧هـ",
  "موعد الملتقى العلمي السنوي يوم الخميس القادم",
  "صدور الطبعة الجديدة من كتاب السبيل المحني للمسلم من الفتن",
];

interface NewsBarProps {
  news?: string[];
  duration?: number;      // ms between fades
  transitionTime?: number; // ms fade duration
}

export function NewsBar({
  news = defaultNews,
  duration = 4000,
  transitionTime = 600,
}: NewsBarProps) {
  const [currentIndex, setCurrentIndex] = useState(0);

  // auto-advance
  useEffect(() => {
    const id = setInterval(() => {
      setCurrentIndex(i => (i + 1) % news.length);
    }, duration);
    return () => clearInterval(id);
  }, [news.length, duration]);

  return (
    <div className="bg-primary/100 text-white py-2 overflow-hidden text-right">
      <div className="container mx-auto px-4 flex items-center gap-3">
        <div className="flex-shrink-0 flex items-center ml-3 gap-2">
          <Megaphone className="h-4 w-4" />
          <span className="text-sm font-medium">أخر الأخبار</span>
        </div>

        <div className="relative w-full h-6 overflow-hidden">
          {news.map((item, idx) => (
            <div
              key={idx}
              className="absolute inset-0 px-4 whitespace-nowrap text-right"
              style={{
                opacity: idx === currentIndex ? 1 : 0,
                transition: `opacity ${transitionTime}ms ease-in-out`,
              }}
            >
              {item}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

export default NewsBar;
