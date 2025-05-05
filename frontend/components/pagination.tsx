'use client';

import { Button } from '@/components/ui/button';
import Link from 'next/link';
import { usePathname, useSearchParams } from 'next/navigation';
import { cn } from '@/lib/utils';

export default function Pagination({ totalPages }: { totalPages: number }) {
    const pathname = usePathname();
    const searchParams = useSearchParams();
    const currentPage = Number(searchParams.get('page')) || 1;

    const createPageURL = (pageNumber: number | string) => {
        const params = new URLSearchParams(searchParams);
        params.set('page', pageNumber.toString());
        return `${pathname}?${params.toString()}`;
    };

    return (
        <div className="flex flex-col md:flex-row items-center justify-between mt-4 gap-2">
            <div className="flex flex-wrap items-center gap-2">
                {currentPage > 1 && (
                    <Link href={createPageURL(currentPage - 1)} scroll={false}>
                        <Button variant="outline">السابق</Button>
                    </Link>
                )}

                {Array.from({ length: totalPages }, (_, index) => {
                    const page = index + 1;
                    return (
                        <Link href={createPageURL(page)} key={page} scroll={false}>
                            <Button
                                variant={currentPage === page ? 'default' : 'outline'}
                                className={cn({ 'bg-emerald-600 text-white hover:bg-emerald-700': currentPage === page })}
                            >
                                {page}
                            </Button>
                        </Link>
                    );
                })}

                {currentPage < totalPages && (
                    <Link href={createPageURL(currentPage + 1)} scroll={false}>
                        <Button variant="outline">التالي</Button>
                    </Link>
                )}
            </div>
            <div className="text-sm text-muted-foreground">
                صفحة {currentPage} من {totalPages}
            </div>
        </div>
    );
}
