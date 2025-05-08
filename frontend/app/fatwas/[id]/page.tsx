import { Card, CardContent } from "@/components/ui/card";
import { Calendar } from "lucide-react";
import { formatDate } from "@/lib/utils";

import { Breadcrumb, BreadcrumbItem, BreadcrumbLink, BreadcrumbList, BreadcrumbSeparator } from "@/components/ui/breadcrumb";
import PageSidebar from "@/components/page-sidebar";
import { getFatwaById } from "@/lib/services/fatwas-service";

export default async function FatwaPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;

  const fatwa = await getFatwaById(id);

  if (!fatwa) {
    return <div className="container mx-auto px-4 py-8">الفتوى غير موجودة</div>;
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <div className="mb-6">
        <Breadcrumb className="mb-4">
          <BreadcrumbList>
            <BreadcrumbItem>
              <BreadcrumbLink href="/">الرئيسية</BreadcrumbLink>
            </BreadcrumbItem>
            <BreadcrumbSeparator />
            <BreadcrumbItem>
              <BreadcrumbLink href="/fatwas">الفتاوى</BreadcrumbLink>
            </BreadcrumbItem>
            <BreadcrumbSeparator />
            <BreadcrumbItem>
              <BreadcrumbLink href={`/fatwas/${fatwa.id}`}>{fatwa.title}</BreadcrumbLink>
            </BreadcrumbItem>
          </BreadcrumbList>
        </Breadcrumb>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
        <div className="md:col-span-2">
          <Card className="overflow-hidden border-0 shadow-md">
            <CardContent className="p-6">
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center gap-2">
                  <span className="bg-emerald-100 text-emerald-800 px-2 py-0.5 rounded text-xs">فتوى</span>
                  <span className="bg-gray-100 text-gray-800 px-2 py-0.5 rounded text-xs">{fatwa.category}</span>
                </div>
              </div>

              <h1 className="text-2xl md:text-3xl font-bold mb-4">{fatwa.title}</h1>

              <div className="flex flex-wrap items-center gap-4 mb-6 text-sm text-gray-600">
                <div className="flex items-center">
                  <Calendar className="h-4 w-4 ml-1" />
                  <span>{formatDate(fatwa.published_date)}</span>
                </div>
              </div>

              <div className="prose max-w-none">
                <div className="text-gray-700 leading-relaxed">
                  <span className="font-semibold">السؤال:</span> 
                  {fatwa.question && (
                    <div className="mt-2 max-h-[600px] overflow-y-auto pr-2 scrollbar-thin scrollbar-thumb-gray-300 scrollbar-track-gray-100" 
                         dangerouslySetInnerHTML={{ __html: fatwa.question.body }} />
                  )}
                </div>
                {fatwa.answer && (
                  <div className="mt-4 max-h-[600px] overflow-y-auto pr-2 scrollbar-thin scrollbar-thumb-gray-300 scrollbar-track-gray-100" 
                       dangerouslySetInnerHTML={{ __html: fatwa.answer.body }} />
                )}
              </div>
            </CardContent>
          </Card>
        </div>

        <div className="md:col-span-1">
          <PageSidebar/>
        </div>
      </div>
    </div>
  );
}
