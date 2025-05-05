import { Breadcrumb, BreadcrumbItem, BreadcrumbLink, BreadcrumbList, BreadcrumbSeparator } from "@/components/ui/breadcrumb"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Button } from "@/components/ui/button"
import { Calendar, MapPin, Mail, Phone, ExternalLink } from "lucide-react"
import Link from "next/link"
import Image from "next/image"
import SocialLinks from "@/components/social-links"

export default function AboutPage() {
  return (
    <div className="container mx-auto px-4 py-8">
      {/* Breadcrumb */}
      <Breadcrumb className="mb-6">
        <BreadcrumbList>
          <BreadcrumbItem>
            <BreadcrumbLink href="/">الرئيسية</BreadcrumbLink>
          </BreadcrumbItem>
          <BreadcrumbSeparator />
          <BreadcrumbItem>
            <BreadcrumbLink>مع الشيخ</BreadcrumbLink>
          </BreadcrumbItem>
        </BreadcrumbList>
      </Breadcrumb>

      {/* Page Title */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold mb-2">مع الشيخ</h1>
        <p className="text-gray-600">تعرف على الشيخ وسيرته ونشاطاته العلمية</p>
      </div>

      {/* Main Content */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
        {/* Sheikh Profile */}
        <div className="md:col-span-1">
          <Card className="border-gray-100 shadow-sm overflow-hidden">
            <div className="relative h-60 md:h-80">
              <Image
                src="/placeholder.svg?height=400&width=300"
                alt="صورة الشيخ"
                fill
                className="object-cover"
              />
            </div>
            <CardContent className="p-6">
              <h2 className="text-2xl font-bold mb-4 text-center">الشيخ عبدالعزيز الراجحي</h2>
              <p className="text-gray-600 text-sm mb-4 text-center">
                عالم وداعية ومفكر إسلامي معاصر، له إسهامات كبيرة في مجال العلوم الشرعية والدعوة إلى الله.
              </p>
              
              <hr className="my-4" />
              
              <div className="space-y-3">
                <div className="flex items-center text-sm">
                  <MapPin className="h-4 w-4 text-gray-500 ml-2" />
                  <span>الرياض، المملكة العربية السعودية</span>
                </div>
                <div className="flex items-center text-sm">
                  <Calendar className="h-4 w-4 text-gray-500 ml-2" />
                  <span>مواليد 1370هـ / 1950م</span>
                </div>
                <div className="flex items-center text-sm">
                  <Mail className="h-4 w-4 text-gray-500 ml-2" />
                  <span>contact@sheikh-name.com</span>
                </div>
                <div className="flex items-center text-sm">
                  <Phone className="h-4 w-4 text-gray-500 ml-2" />
                  <span>+966 12 345 6789</span>
                </div>
              </div>
              
              <hr className="my-4" />
              
              <div className="flex justify-center">
                <SocialLinks />
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Main Content Tabs */}
        <div className="md:col-span-2">
          <Tabs defaultValue="bio" className="w-full">
            <TabsList className="bg-white border rounded-lg p-1 mb-6 w-fit mx-auto">
              <TabsTrigger
                value="bio"
                className="data-[state=active]:bg-emerald-600 data-[state=active]:text-white rounded-md px-6"
              >
                السيرة الذاتية
              </TabsTrigger>
              <TabsTrigger
                value="publications"
                className="data-[state=active]:bg-emerald-600 data-[state=active]:text-white rounded-md px-6"
              >
                المؤلفات
              </TabsTrigger>
              <TabsTrigger
                value="activities"
                className="data-[state=active]:bg-emerald-600 data-[state=active]:text-white rounded-md px-6"
              >
                النشاطات
              </TabsTrigger>
              <TabsTrigger
                value="contact"
                className="data-[state=active]:bg-emerald-600 data-[state=active]:text-white rounded-md px-6"
              >
                التواصل
              </TabsTrigger>
            </TabsList>

            <TabsContent value="bio" className="mt-0">
              <Card className="border-gray-100 shadow-sm">
                <CardContent className="p-6">
                  <h3 className="text-xl font-bold mb-4">السيرة الذاتية</h3>
                  <div className="space-y-4 text-gray-700">
                    <p>
                      ولد الشيخ في مدينة الرياض عام 1370هـ الموافق 1950م، ونشأ في أسرة عُرفت بالعلم والصلاح. بدأ تعليمه في كتاتيب المساجد حيث حفظ القرآن الكريم في سن مبكرة، ثم التحق بالمدارس النظامية وأكمل تعليمه الابتدائي والمتوسط والثانوي.
                    </p>
                    <p>
                      انتقل بعد ذلك للدراسة في كلية الشريعة بجامعة الإمام محمد بن سعود الإسلامية، وحصل على درجة البكالوريوس في الشريعة الإسلامية، ثم واصل دراسته العليا حتى حصل على درجة الماجستير والدكتوراه في الفقه.
                    </p>
                    <p>
                      عمل الشيخ في التدريس الجامعي، وتولى عدة مناصب أكاديمية وإدارية في الجامعة. كما كان له نشاط دعوي كبير من خلال المحاضرات والدروس والخطب في المساجد والجامعات والمعاهد العلمية.
                    </p>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="publications" className="mt-0">
              <Card className="border-gray-100 shadow-sm">
                <CardContent className="p-6">
                  <h3 className="text-xl font-bold mb-4">المؤلفات والإصدارات</h3>
                  <div className="space-y-4">
                    <ul className="list-disc list-inside space-y-2 text-gray-700">
                      <li>شرح كتاب التوحيد</li>
                      <li>تفسير القرآن الكريم</li>
                      <li>شرح العقيدة الطحاوية</li>
                      <li>فقه العبادات</li>
                      <li>مختصر الفقه الإسلامي</li>
                      <li>وسائل الثبات على دين الله</li>
                      <li>مسائل معاصرة في المعاملات المالية</li>
                      <li>فتاوى في العقيدة والفقه</li>
                    </ul>
                    <Button className="bg-emerald-600 hover:bg-emerald-700 mt-4">
                      <Link href="/books">
                        <span className="flex items-center">
                          تصفح جميع مؤلفات الشيخ
                          <ExternalLink className="h-4 w-4 mr-2" />
                        </span>
                      </Link>
                    </Button>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="activities" className="mt-0">
              <Card className="border-gray-100 shadow-sm">
                <CardContent className="p-6">
                  <h3 className="text-xl font-bold mb-4">النشاطات والمشاركات العلمية</h3>
                  <div className="space-y-4 text-gray-700">
                    <p>
                      يقدم الشيخ دروساً علمية أسبوعية في الفقه والعقيدة والتفسير وشرح الحديث في عدد من المساجد.
                    </p>
                    <p>
                      يشارك في العديد من المؤتمرات والندوات العلمية المحلية والدولية المتعلقة بالقضايا الإسلامية المعاصرة.
                    </p>
                    <p>
                      يقدم فتاوى وإجابات للأسئلة الشرعية من خلال برنامج إذاعي أسبوعي وعبر موقعه الرسمي.
                    </p>
                    <p>
                      يشرف على عدد من الرسائل العلمية في مرحلتي الماجستير والدكتوراه في عدة جامعات.
                    </p>
                    <p>
                      عضو في عدد من الهيئات والمجامع العلمية والفقهية المحلية والدولية.
                    </p>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>

            <TabsContent value="contact" className="mt-0">
              <Card className="border-gray-100 shadow-sm">
                <CardContent className="p-6">
                  <h3 className="text-xl font-bold mb-4">تواصل مع الشيخ</h3>
                  <div className="space-y-4">
                    <p className="text-gray-700">
                      يمكنكم التواصل مع الشيخ من خلال الوسائل التالية:
                    </p>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mt-4">
                      <div className="p-4 border rounded-md">
                        <h4 className="font-semibold mb-2">البريد الإلكتروني</h4>
                        <p className="flex items-center text-sm">
                          <Mail className="h-4 w-4 text-emerald-600 ml-2" />
                          <span>contact@sheikh-name.com</span>
                        </p>
                      </div>
                      <div className="p-4 border rounded-md">
                        <h4 className="font-semibold mb-2">الهاتف</h4>
                        <p className="flex items-center text-sm">
                          <Phone className="h-4 w-4 text-emerald-600 ml-2" />
                          <span>+966 12 345 6789</span>
                        </p>
                      </div>
                    </div>
                    <p className="text-gray-700 mt-4">
                      أو يمكنكم إرسال رسالة مباشرة من خلال موقعنا:
                    </p>
                    <form className="mt-4 space-y-4">
                      <div>
                        <label className="block text-sm font-medium mb-1">الاسم</label>
                        <input
                          type="text"
                          className="w-full p-2 border rounded-md"
                          placeholder="أدخل اسمك الكامل"
                        />
                      </div>
                      <div>
                        <label className="block text-sm font-medium mb-1">البريد الإلكتروني</label>
                        <input
                          type="email"
                          className="w-full p-2 border rounded-md"
                          placeholder="أدخل بريدك الإلكتروني"
                        />
                      </div>
                      <div>
                        <label className="block text-sm font-medium mb-1">الموضوع</label>
                        <input
                          type="text"
                          className="w-full p-2 border rounded-md"
                          placeholder="أدخل موضوع الرسالة"
                        />
                      </div>
                      <div>
                        <label className="block text-sm font-medium mb-1">الرسالة</label>
                        <textarea
                          className="w-full p-2 border rounded-md"
                          rows={4}
                          placeholder="أدخل نص الرسالة"
                        ></textarea>
                      </div>
                      <div>
                        <Button className="bg-emerald-600 hover:bg-emerald-700 w-full">إرسال الرسالة</Button>
                      </div>
                    </form>
                  </div>
                </CardContent>
              </Card>
            </TabsContent>
          </Tabs>
        </div>
      </div>
    </div>
  )
}