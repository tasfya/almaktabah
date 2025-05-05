"use client";

import { ArrowUpDown, Filter, Search, X } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useSearchParams, usePathname, useRouter } from "next/navigation";
import { useDebouncedCallback } from "use-debounce";
import {
  DropdownMenu,
  DropdownMenuCheckboxItem,
  DropdownMenuContent,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
  DropdownMenuRadioGroup,
  DropdownMenuRadioItem,
} from "@/components/ui/dropdown-menu";
import { useEffect, useState } from "react";

export function SearchBar({
  placeholder = "ابحث ...",
  categories = [],
}: {
  placeholder?: string;
  categories?: string[];
}) {
  const searchParams = useSearchParams();
  const pathname = usePathname();
  const { replace } = useRouter();

  const [selectedCategories, setSelectedCategories] = useState<string[]>([]);
  const [selectedSort, setSelectedSort] = useState<string>("");

  useEffect(() => {
    setSelectedCategories(searchParams.getAll("category"));
    setSelectedSort(searchParams.get("sort") || "");
  }, [searchParams]);

  const handleSearch = useDebouncedCallback((term) => {
    const params = new URLSearchParams(searchParams);
    if (term) {
      params.set("query", term);
    } else {
      params.delete("query");
    }
    replace(`${pathname}?${params.toString()}`, { scroll: false });
  }, 300);

  const handleCategoryToggle = (category: string) => {
    const updated = selectedCategories.includes(category)
      ? selectedCategories.filter((c) => c !== category)
      : [...selectedCategories, category];

    setSelectedCategories(updated);
    const params = new URLSearchParams(searchParams);
    params.delete("category");
    updated.forEach((cat) => params.append("category", cat));
    replace(`${pathname}?${params.toString()}`, { scroll: false });
  };

  const handleSortChange = (sort: string) => {
    setSelectedSort(sort);
    const params = new URLSearchParams(searchParams);
    if (sort) {
      params.set("sort", sort);
    } else {
      params.delete("sort");
    }
    replace(`${pathname}?${params.toString()}`, { scroll: false });
  };

  const clearFilters = () => {
    const params = new URLSearchParams(searchParams);
    params.delete("category");
    params.delete("query");
    params.delete("sort");
    setSelectedCategories([]);
    setSelectedSort("");
    replace(`${pathname}?${params.toString()}`, { scroll: false });
  };

  const activeFilters =
    selectedCategories.length > 0 || searchParams.get("query") || selectedSort;

  return (
    <div className="grid grid-cols-1 md:grid-cols-[1fr,auto] gap-4">
      <div className="relative">
        <input
          type="search"
          dir="rtl"
          placeholder={placeholder}
          onChange={(e) => handleSearch(e.target.value)}
          defaultValue={searchParams.get("query") || ""}
          className="w-full p-2 pl-10 pr-4 border rounded-md border-gray-200"
        />
        <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" size={18} />
      </div>

      <div className="flex flex-wrap gap-2 items-center">
        {/* Sort Dropdown */}
        <DropdownMenu dir="rtl">
          <DropdownMenuTrigger asChild>
            <Button
              variant="outline"
            >
              <ArrowUpDown className="h-4 w-4 ml-2" />
              ترتيب
              {selectedSort && (
                <span className="absolute top-1 right-1 h-2 w-2 rounded-full bg-emerald-500 animate-pulse" />
              )}
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent className="w-40">
            <DropdownMenuLabel>ترتيب حسب</DropdownMenuLabel>
            <DropdownMenuSeparator />
            <DropdownMenuRadioGroup value={selectedSort} onValueChange={handleSortChange}>
              <DropdownMenuRadioItem value="newest">الأحدث</DropdownMenuRadioItem>
              <DropdownMenuRadioItem value="oldest">الأقدم</DropdownMenuRadioItem>
              <DropdownMenuRadioItem value="title">حسب الاسم</DropdownMenuRadioItem>
            </DropdownMenuRadioGroup>
          </DropdownMenuContent>
        </DropdownMenu>

        {/* Filter Categories Dropdown */}
        <DropdownMenu dir="rtl">
          <DropdownMenuTrigger asChild>
            <Button
              variant="outline"
              className="relative"
            >
              <Filter className="h-4 w-4 ml-2" />
              تصفية
              {selectedCategories.length > 0 && (
                <span className="absolute top-1 right-1 h-2 w-2 rounded-full bg-emerald-500 animate-pulse" />
              )}
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent className="w-56">
            <DropdownMenuLabel>الفئات</DropdownMenuLabel>
            <DropdownMenuSeparator />
            {categories.map((category) => (
              <DropdownMenuCheckboxItem
                key={category}
                checked={selectedCategories.includes(category)}
                onCheckedChange={() => handleCategoryToggle(category)}
              >
                {category}
              </DropdownMenuCheckboxItem>
            ))}
          </DropdownMenuContent>
        </DropdownMenu>

        {/* Clear Filters */}
        {activeFilters && (
          <Button
            variant="outline"
            onClick={clearFilters}
            className="text-red-600 border-red-200 hover:bg-red-50"
          >
            <X className="h-4 w-4 ml-2" />
            مسح التصفية
          </Button>
        )}
      </div>
    </div>
  );
}
