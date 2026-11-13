# Be sure to restart your server when you modify this file.

# Add new inflection rules using the following format. Inflections
# are locale specific, and you may define rules for as many different
# locales as you wish. All of these examples are active by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.plural /^(ox)$/i, "\\1en"
#   inflect.singular /^(ox)en/i, "\\1"
#   inflect.irregular "person", "people"
#   inflect.uncountable %w( fish sheep )
# end

# These inflection rules are supported but not enabled by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.acronym "RESTful"
# end

# Avo singularizes a has_many panel's Arabic title (config/locales/avo.ar.yml)
# with the English rules to label its buttons ("إنشاء موعد جديد", "حذف موعد").
ActiveSupport::Inflector.inflections(:en) do |inflect|
  {
    "برنامج" => "برامج", "عنصر" => "عناصر", "اختبار" => "اختبارات", "سؤال" => "أسئلة",
    "دفعة" => "دفعات", "موعد" => "مواعيد", "طالب" => "طلاب", "تسجيل" => "تسجيلات"
  }.each { |singular, plural| inflect.irregular(singular, plural) }
end
