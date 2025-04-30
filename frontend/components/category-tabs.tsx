
interface CategoryTabsProps {
    category: string;
    lessonsCategories: Category[];
    lessons: Lesson[];
}
export default function CategoryTabs({ category, lessonsCategories, lessons }: CategoryTabsProps) {
  if (!lessonsCategories || lessonsCategories.length === 0) {
      return <p className="text-red-600">No categories available.</p>;
  }

  return (
    
  );
}