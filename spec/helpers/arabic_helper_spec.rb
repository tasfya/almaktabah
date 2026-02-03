require "rails_helper"

RSpec.describe ArabicHelper do
  let(:helper_class) do
    Class.new do
      include ArabicHelper
    end
  end

  subject(:helper) { helper_class.new }

  describe "#transliterate_arabic" do
    it "maps Arabic letters to Latin and strips diacritics" do
      expect(helper.transliterate_arabic("مُحَمَّد")).to eq("mhmmd")
    end

    it "handles hamza and alif variants" do
      expect(helper.transliterate_arabic("إمام")).to eq("imam")
      expect(helper.transliterate_arabic("آدم")).to eq("aadm")
      expect(helper.transliterate_arabic("مسؤول")).to eq("ms'wl")
    end

    it "maps ta marbuta and common Arabic letters" do
      expect(helper.transliterate_arabic("مدرسة")).to eq("mdrsh")
      expect(helper.transliterate_arabic("سورة")).to eq("swrh")
    end

    it "supports lam-alif ligatures and presentation forms" do
      expect(helper.transliterate_arabic("ﻻ")).to eq("la")
      expect(helper.transliterate_arabic("لا")).to eq("la")
    end

    it "maps Persian letters used in Arabic text" do
      expect(helper.transliterate_arabic("پچڤگژ")).to eq("pchvgzh")
    end

    it "converts Arabic-Indic digits to Latin digits" do
      expect(helper.transliterate_arabic("الدرس ١٢٣")).to eq("aldrs 123")
    end

    it "converts Eastern Arabic digits to Latin digits" do
      expect(helper.transliterate_arabic("۱۲۳۴۵۶۷۸۹۰")).to eq("1234567890")
    end

    it "removes tatweel characters" do
      expect(helper.transliterate_arabic("كتــاب")).to eq("ktab")
    end

    it "handles shadda by doubling the previous letter" do
      expect(helper.transliterate_arabic("مَدَّ")).to eq("mdd")
      expect(helper.transliterate_arabic("شّ")).to eq("shsh")
    end

    it "removes tashkeel marks" do
      expect(helper.transliterate_arabic("قُرْآنٌ")).to eq("qraan")
      expect(helper.transliterate_arabic("مُحَمَّد")).to eq("mhmmd")
    end

    it "preserves Latin text and punctuation while squeezing spaces" do
      expect(helper.transliterate_arabic("سلام, world!")).to eq("slam, world!")
      expect(helper.transliterate_arabic("  عبد   الله  ")).to eq("abd allh")
    end

    it "keeps non-Arabic symbols intact" do
      expect(helper.transliterate_arabic("سلام 😊 123")).to eq("slam 😊 123")
    end

    it "transliterates mixed Arabic and Latin text" do
      expect(helper.transliterate_arabic("الدرس 12A")).to eq("aldrs 12A")
      expect(helper.transliterate_arabic("يحيى test")).to eq("yhya test")
    end

    it "returns empty string for nil or blank input" do
      expect(helper.transliterate_arabic(nil)).to eq("")
      expect(helper.transliterate_arabic("   ")).to eq("")
    end
  end
end
