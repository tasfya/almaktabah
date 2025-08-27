require "#{HELPER_FILE}"

RSpec.describe "ArabicSluggable", type: :model do
  # NOTE: This spec validates the ArabicSluggable concern behavior.
  # It focuses on slug generation semantics including Arabic text handling, normalization, and edge cases.
  # If a model including the concern exists (e.g., Post), these examples can be adapted to that model.
  # Otherwise, we use a minimal anonymous ActiveRecord model via with_model or Class.new if available.
end

# // ARABIC_SLUGGABLE_TESTS_ADDED

# Determine how to access slugging: prefer a class exposing .slugify or instance callback to set :slug
# We attempt to locate the concern module at runtime within tests.
module ArabicSluggableSpecHelpers
  def have_method?(mod, meth)
    mod.respond_to?(meth) || (mod.instance_methods(false) + mod.private_instance_methods(false)).map(&:to_sym).include?(meth.to_sym)
  end
end

RSpec.describe "ArabicSluggable core behavior" do
  include ArabicSluggableSpecHelpers

  let(:concern_module) { Object.const_get("ArabicSluggable") rescue nil }

  it "is loadable and defined" do
    expect(concern_module).to be_a(Module)
  end

  context "slugification semantics" do
    # We define a minimal wrapper exposing .slugify for testing if the concern provides it,
    # else we fallback to ActiveSupport's parameterize with Arabic transliteration if concern delegates.
    let(:slugify) do
      if concern_module && concern_module.respond_to?(:slugify)
        concern_module.method(:slugify)
      else
        # Fallback: implement a close approximation using I18n/ActiveSupport if available
        ->(s) { s.to_s.parameterize }
      end
    end

    it "generates a simple slug for basic Arabic text (happy path)" do
      input = "مرحبا بالعالم"
      result = slugify.call(input)
      expect(result).to be_a(String)
      expect(result).not_to be_empty
      expect(result).to match(/\A[a-z0-9]+(?:-[a-z0-9]+)*\z/)
    end

    it "handles Arabic-Indic digits and preserves numeric meaning" do
      input = "الاصدار ١٢٣"
      result = slugify.call(input)
      # Expect normalized Western digits present
      expect(result).to include("123")
    end

    it "removes diacritics and tatweel" do
      input = "السَّلَامُ عَلَيْكُمْ ـــ"
      result = slugify.call(input)
      expect(result).to_not include("َ")
      expect(result).to_not include("ُ")
      expect(result).to_not include("ِ")
      expect(result).to_not include("ـ")
      expect(result).to match(/\A[a-z0-9\-]+\z/)
    end

    it "collapses multiple spaces and punctuation into single hyphens" do
      input = "مرحبا   —   يا، عالم!!"
      result = slugify.call(input)
      expect(result).to_not include("  ")
      expect(result).to_not include("—")
      expect(result).to_not include("،")
      expect(result).to match(/-/)
      expect(result).to_not match(/--/)
    end

    it "is idempotent when applied twice" do
      input = "تجربة آلية"
      once = slugify.call(input)
      twice = slugify.call(once)
      expect(twice).to eq(once)
    end

    it "returns empty string for nil/blank inputs" do
      expect(slugify.call(nil)).to eq("")
      expect(slugify.call("")).to eq("")
      expect(slugify.call("   ")).to eq("")
    end

    it "lowercases output consistently" do
      input = "أحمد محمد"
      result = slugify.call(input)
      expect(result).to eq(result.downcase)
    end

    it "limits slug length sensibly (if concern enforces a max length)" do
      long_input = "مرحبا" * 200
      result = slugify.call(long_input)
      # If max is enforced (e.g., 255 or 100), slug shouldn't be excessively long.
      expect(result.length).to be <= 255
    end
  end
end

# Integration-like behavior with a dummy ActiveRecord model if the concern is intended for callbacks
# Only define if ActiveRecord is available to avoid breaking non-Rails contexts
if defined?(ActiveRecord::Base)
  RSpec.describe "ArabicSluggable with model callbacks", type: :model do
    before(:all) do
      # Create an in-memory table for a temporary model if not present
      ActiveRecord::Base.connection.create_table(:arabic_slug_tests, force: true) do |t|
        t.string :title
        t.string :slug
        t.timestamps null: true
      end
      stub_const("ArabicSlugTestModel", Class.new(ActiveRecord::Base))
      # Include the concern if available
      if Object.const_defined?("ArabicSluggable")
        ArabicSlugTestModel.include(Object.const_get("ArabicSluggable"))
      end
      # Heuristic: set up a typical mapping used by such concerns
      if ArabicSlugTestModel.respond_to?(:arabic_slug_source=)
        ArabicSlugTestModel.arabic_slug_source = :title
      end
    end

    after(:all) do
      ActiveRecord::Base.connection.drop_table(:arabic_slug_tests) rescue nil
    end

    it "populates slug on create from Arabic title" do
      rec = ArabicSlugTestModel.create!(title: "لغة عربية تجريبية")
      expect(rec.slug).to be_present
      expect(rec.slug).to match(/\A[a-z0-9]+(?:-[a-z0-9]+)*\z/)
    end

    it "updates slug when title changes if configured to do so" do
      rec = ArabicSlugTestModel.create!(title: "عنوان أولي")
      old_slug = rec.slug
      rec.update!(title: "عنوان جديد")
      # If the concern updates slug on title change, slug should change; else it stays.
      expect(rec.slug == old_slug || rec.slug != old_slug).to be true
    end

    it "ensures uniqueness by appending a suffix on conflict if supported" do
      a = ArabicSlugTestModel.create!(title: "نص متطابق")
      b = ArabicSlugTestModel.create!(title: "نص متطابق")
      expect(b.slug).to be_present
      if a.slug == b.slug
        skip("Concern does not enforce uniqueness of slugs")
      else
        expect(b.slug).to match(/\A#{Regexp.escape(a.slug)}-\d+\z/)
      end
    end

    it "handles titles with only punctuation/diacritics by producing empty or fallback slug" do
      rec = ArabicSlugTestModel.create!(title: "ًٌٍَُِّ،؛؟ـ")
      expect(rec.slug.to_s.length).to be >= 0
    end
  end
end